# Parche Menu Modo Xbox - Windows 11

Una herramienta grafica ligera desarrollada en PowerShell que permite forzar la habilitacion de la nueva interfaz "Modo Xbox" en la aplicacion de Configuracion de Windows 11 (Builds 26100 o superiores).

## Caracteristicas
* **Interfaz de Usuario (GUI):** Estilo moderno (Dark Mode) inspirado en el ecosistema Xbox.
* **Proceso guiado por pasos:** Verifica el sistema, descarga las herramientas de forma segura y aplica el parche.
* **Autoelevacion:** Detecta automaticamente si se requieren permisos de administrador.
* **Soporte EXE:** Funciona nativamente como script `.ps1` o compilado como `.exe`.

## Como usar
1. Descarga el archivo `ParcheMenuXbox.ps1` desde la seccion de Releases o clonando este repositorio.
2. Haz clic derecho sobre el archivo y selecciona **"Ejecutar con PowerShell"**.
3. Acepta los permisos de administrador si el sistema lo solicita.
4. Sigue los 3 pasos en la interfaz del programa.
5. **Reinicia tu computadora** para que la aplicacion de Configuracion recargue los menus.
6. Dirigete a `Configuracion > Juegos` y el nuevo Modo Xbox estara disponible.

## Notas para desarrolladores
Este script utiliza **ViVeTool** de forma automatizada (descargandolo en un directorio temporal y eliminandolo al finalizar) para inyectar los IDs ocultos de Microsoft (`58989070` y `59765208`). Si deseas compilar el script a formato `.exe`, se recomienda usar herramientas como PS2EXE.

## Licencia
Distribuido bajo la Licencia MIT.
