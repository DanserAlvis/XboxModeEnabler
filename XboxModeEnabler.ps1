# 1. Solicitar permisos de Administrador automaticamente (Soporte para .exe y .ps1)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $rutaActual = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    
    if ($rutaActual -match '\.exe$') {
        # Si se abrio como un programa .exe compilado
        Start-Process -FilePath $rutaActual -Verb RunAs
    } else {
        # Si se abrio como un script .ps1 normal
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    exit
}

# 2. Cargar librerias de interfaz grafica
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Variables globales para compartir entre pasos
$script:tempZip = "$env:TEMP\vivetool_temp.zip"
$script:tempDir = "$env:TEMP\vivetool_temp"

# 3. Configurar la ventana principal (Estilo Xbox Dark)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Instalador: Parche Menu Modo Xbox"
$form.Size = New-Object System.Drawing.Size(620, 520)
$form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# 4. Banner superior (Verde Xbox)
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Size = New-Object System.Drawing.Size(620, 65)
$pnlHeader.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "PARCHE: FORZAR MENU MODO XBOX"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Location = New-Object System.Drawing.Point(20, 18)
$lblTitle.Size = New-Object System.Drawing.Size(500, 30)
$pnlHeader.Controls.Add($lblTitle)
$form.Controls.Add($pnlHeader)

# 5. Botones de Pasos (Flat UI)
# Paso 1
$btnStep1 = New-Object System.Windows.Forms.Button
$btnStep1.Text = "1. Verificar Sistema"
$btnStep1.Location = New-Object System.Drawing.Point(20, 85)
$btnStep1.Size = New-Object System.Drawing.Size(180, 45)
$btnStep1.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnStep1.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$btnStep1.ForeColor = [System.Drawing.Color]::White
$btnStep1.FlatStyle = 'Flat'
$btnStep1.FlatAppearance.BorderSize = 0

# Paso 2
$btnStep2 = New-Object System.Windows.Forms.Button
$btnStep2.Text = "2. Descargar Herramienta"
$btnStep2.Location = New-Object System.Drawing.Point(210, 85)
$btnStep2.Size = New-Object System.Drawing.Size(180, 45)
$btnStep2.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnStep2.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$btnStep2.ForeColor = [System.Drawing.Color]::Gray
$btnStep2.FlatStyle = 'Flat'
$btnStep2.FlatAppearance.BorderSize = 0
$btnStep2.Enabled = $false

# Paso 3
$btnStep3 = New-Object System.Windows.Forms.Button
$btnStep3.Text = "3. Aplicar Parche"
$btnStep3.Location = New-Object System.Drawing.Point(400, 85)
$btnStep3.Size = New-Object System.Drawing.Size(180, 45)
$btnStep3.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnStep3.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$btnStep3.ForeColor = [System.Drawing.Color]::Gray
$btnStep3.FlatStyle = 'Flat'
$btnStep3.FlatAppearance.BorderSize = 0
$btnStep3.Enabled = $false

# 6. Consola de Registro (Log Box)
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(20, 145)
$logBox.Size = New-Object System.Drawing.Size(560, 280)
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
$logBox.BorderStyle = 'None'

# Etiqueta de Estado Inferior
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Estado: Esperando accion. Haga clic en el Paso 1."
$lblStatus.Location = New-Object System.Drawing.Point(20, 440)
$lblStatus.Size = New-Object System.Drawing.Size(560, 25)
$lblStatus.ForeColor = [System.Drawing.Color]::DarkGray
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Funcion de Log con Colores
function Write-Log([string]$Message, [string]$Color = "LightGray") {
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor = [System.Drawing.Color]::$Color
    $logBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Message`n")
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# --- LOGICA: PASO 1 (Verificar) ---
$btnStep1.Add_Click({
    $btnStep1.Enabled = $false
    $lblStatus.Text = "Estado: Verificando requisitos del sistema..."
    Write-Log "=== PASO 1: VERIFICACION DE SISTEMA ===" "White"
    
    # Verificar Build de Windows
    $build = [System.Environment]::OSVersion.Version.Build
    Write-Log "Comprobando version de Windows 11..." "Cyan"
    if ($build -ge 26100) {
        Write-Log "[OK] Compilacion compatible (Build $build)." "LimeGreen"
    } else {
        Write-Log "[ADVERTENCIA] Build $build. Este parche requiere Windows 11 24H2 o superior." "Yellow"
    }

    # Verificar Conexion a Internet
    Write-Log "Verificando conexion con los servidores de GitHub..." "Cyan"
    try {
        $ping = Test-Connection -ComputerName "github.com" -Count 1 -ErrorAction Stop
        Write-Log "[OK] Conexion a internet estable." "LimeGreen"
        
        # Desbloquear Paso 2
        Write-Log "Sistema listo. Continue con el Paso 2." "White"
        $btnStep2.Enabled = $true
        $btnStep2.ForeColor = [System.Drawing.Color]::White
        $btnStep1.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16) # Marcar como completado
        $lblStatus.Text = "Estado: Paso 1 completado. Proceda al Paso 2."
    } catch {
        Write-Log "[ERROR] No se pudo conectar a GitHub. Revise su conexion." "Red"
        $lblStatus.Text = "Estado: Error en la verificacion de red."
        $btnStep1.Enabled = $true
    }
})

# --- LOGICA: PASO 2 (Descargar) ---
$btnStep2.Add_Click({
    $btnStep2.Enabled = $false
    $lblStatus.Text = "Estado: Descargando y preparando herramientas..."
    Write-Log "`n=== PASO 2: PREPARAR HERRAMIENTAS ===" "White"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        Write-Log "Descargando ViVeTool en directorio temporal..." "Cyan"
        Invoke-WebRequest -Uri "https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3.zip" -OutFile $script:tempZip -UseBasicParsing
        
        Write-Log "Extrayendo archivos de configuracion..." "Cyan"
        if (Test-Path $script:tempDir) { Remove-Item -Path $script:tempDir -Recurse -Force }
        Expand-Archive -Path $script:tempZip -DestinationPath $script:tempDir -Force
        
        Write-Log "[OK] Herramientas preparadas con exito." "LimeGreen"
        Write-Log "Continue con el Paso 3 para inyectar el parche." "White"
        
        # Desbloquear Paso 3
        $btnStep3.Enabled = $true
        $btnStep3.ForeColor = [System.Drawing.Color]::White
        $btnStep2.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16) # Marcar como completado
        $lblStatus.Text = "Estado: Paso 2 completado. Proceda al Paso 3."
    } catch {
        Write-Log "[ERROR] Fallo la descarga o extraccion: $_" "Red"
        $lblStatus.Text = "Estado: Error en la descarga."
        $btnStep2.Enabled = $true
    }
})

# --- LOGICA: PASO 3 (Parchear) ---
$btnStep3.Add_Click({
    $btnStep3.Enabled = $false
    $lblStatus.Text = "Estado: Aplicando parche en el sistema..."
    Write-Log "`n=== PASO 3: APLICAR PARCHE ===" "White"
    
    try {
        $viveExe = "$script:tempDir\vivetool.exe"
        
        Write-Log "Inyectando identificadores (58989070, 59765208)..." "Yellow"
        $process = Start-Process -FilePath $viveExe -ArgumentList "/enable /id:58989070,59765208" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "[OK] Parche inyectado correctamente en el sistema." "LimeGreen"
        } else {
            Write-Log "[ERROR] ViVeTool devolvio el codigo de error: $($process.ExitCode)" "Red"
        }

        Write-Log "Realizando limpieza de archivos temporales..." "Cyan"
        Remove-Item -Path $script:tempZip -Force
        Remove-Item -Path $script:tempDir -Recurse -Force

        Write-Log "--------------------------------------------------" "White"
        Write-Log "PARCHE APLICADO COMPLETAMENTE." "LimeGreen"
        Write-Log "POR FAVOR, REINICIA TU COMPUTADORA AHORA." "Yellow"
        Write-Log "Despues de reiniciar, revisa: Configuracion > Juegos" "White"
        
        $btnStep3.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16) # Marcar como completado
        $lblStatus.Text = "Estado: Proceso finalizado. Pendiente de reinicio."
    } catch {
        Write-Log "[ERROR CRITICO] Ocurrio un problema inesperado: $_" "Red"
        $lblStatus.Text = "Estado: Error critico al parchear."
    }
})

# 7. Agregar controles al formulario y mostrar ventana
$form.Controls.Add($btnStep1)
$form.Controls.Add($btnStep2)
$form.Controls.Add($btnStep3)
$form.Controls.Add($logBox)
$form.Controls.Add($lblStatus)

[System.Windows.Forms.Application]::Run($form)