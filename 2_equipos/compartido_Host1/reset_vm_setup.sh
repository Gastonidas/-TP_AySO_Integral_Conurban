#!/bin/bash

# Script: cleanup_vm.sh
# Descripcion: Elimina la estructura de directorios, usuarios, grupos y configuraciones
#              creadas por el script 'setup_vm.sh' (o como le hayas llamado a tu script principal).
#
# Uso: sudo ./cleanup_vm.sh

echo "Iniciando proceso de limpieza de la VM..."
echo "---------------------------------------------------------"

# Definir variables igual que en el script principal para asegurar consistencia
USUARIOS_FILE="Bash_script/alta_usuarios/Lista_Usuarios.txt"
GRUPO_SUDO="grupo_sec"
# Nuevas variables para la limpieza de check_URL
BASE_LOG_DIR="/tmp/head-check"
LOG_GENERAL="/var/log/status_URL.log"

# 1. Eliminar el archivo de configuración de sudoers para el grupo secundario
echo "1. Eliminando archivo de configuración de sudoers para '$GRUPO_SUDO'..."
if [ -f "/etc/sudoers.d/$GRUPO_SUDO" ]; then
    sudo rm -f "/etc/sudoers.d/$GRUPO_SUDO"
    echo "   Archivo /etc/sudoers.d/$GRUPO_SUDO eliminado."
else
    echo "   Archivo /etc/sudoers.d/$GRUPO_SUDO no encontrado. Saltando."
fi

# 2. Eliminar usuarios creados
echo "2. Eliminando usuarios creados por el script principal..."
if [ -f "$USUARIOS_FILE" ]; then
    # Usar 'awk' para extraer solo los nombres de usuario, y luego un bucle 'while read'
    # en Bash para ejecutar 'userdel' con 'sudo'. Esto asegura que sudo se aplique correctamente.
    awk -F ',' 'NR > 7 && !/^#/ { print $1 }' "$USUARIOS_FILE" | while IFS=',' read -r USERNAME_TO_DELETE; do
        if id -u "$USERNAME_TO_DELETE" >/dev/null 2>&1; then # Verificar si el usuario existe antes de intentar eliminar
            echo "   - Eliminando usuario '$USERNAME_TO_DELETE'..."
            sudo userdel -r "$USERNAME_TO_DELETE" # Eliminar el directorio home del usuario también (-r)
            if [ $? -eq 0 ]; then
                echo "     Usuario '$USERNAME_TO_DELETE' eliminado."
            else
                echo "     Error o usuario '$USERNAME_TO_DELETE' no eliminado (podría tener procesos activos o ser primario de un grupo aún en uso)."
            fi
        else
            echo "   - Usuario '$USERNAME_TO_DELETE' no existe. Saltando."
        fi
    done
    echo "   Proceso de eliminación de usuarios completado."
else
    echo "   Archivo $USUARIOS_FILE no encontrado. No se eliminarán usuarios."
fi

# 3. Eliminar los grupos primarios de los usuarios
echo "3. Eliminando grupos primarios de usuarios..."
if [ -f "$USUARIOS_FILE" ]; then
    # Usar 'awk' para extraer solo los nombres de los grupos primarios, eliminar duplicados con 'sort -u',
    # y luego un bucle 'while read' en Bash para ejecutar 'groupdel' con 'sudo'.
    awk -F ',' 'NR > 7 && !/^#/ { print $2 }' "$USUARIOS_FILE" | sort -u | while IFS=',' read -r PRIMARY_GROUP_TO_DELETE; do
        if getent group "$PRIMARY_GROUP_TO_DELETE" > /dev/null 2>&1; then # Verificar si el grupo existe
            echo "   - Eliminando grupo primario '$PRIMARY_GROUP_TO_DELETE'..."
            sudo groupdel "$PRIMARY_GROUP_TO_DELETE"
            if [ $? -eq 0 ]; then
                echo "     Grupo '$PRIMARY_GROUP_TO_DELETE' eliminado."
            else
                echo "     Error o grupo '$PRIMARY_GROUP_TO_DELETE' no eliminado (podría no existir o tener miembros)."
            fi
        else
            echo "   - Grupo '$PRIMARY_GROUP_TO_DELETE' no existe. Saltando."
        fi
    done
    echo "   Proceso de eliminación de grupos primarios completado."
else
    echo "   Archivo $USUARIOS_FILE no encontrado. No se eliminarán grupos primarios."
fi

# 4. Eliminar el grupo secundario para sudo
echo "4. Eliminando grupo secundario '$GRUPO_SUDO'..."
if getent group "$GRUPO_SUDO" > /dev/null 2>&1; then
    sudo groupdel "$GRUPO_SUDO"
    echo "   Grupo '$GRUPO_SUDO' eliminado."
else
    echo "   Grupo '$GRUPO_SUDO' no existe. Saltando."
fi

# --- INICIO DE SECCIONES DE LIMPIEZA PARA check_URL ---

# 5. Eliminar el directorio de logs de URLs en /tmp/head-check/
echo "5. Eliminando directorio de logs de URLs '$BASE_LOG_DIR/'..."
if [ -d "$BASE_LOG_DIR" ]; then
    sudo rm -rf "$BASE_LOG_DIR"
    echo "   Directorio '$BASE_LOG_DIR/' eliminado."
else
    echo "   Directorio '$BASE_LOG_DIR/' no encontrado. Saltando."
fi

# 6. Eliminar el archivo de log general de URLs en /var/log/
echo "6. Eliminando archivo de log general '$LOG_GENERAL'..."
if [ -f "$LOG_GENERAL" ]; then
    sudo rm -f "$LOG_GENERAL"
    echo "   Archivo '$LOG_GENERAL' eliminado."
else
    echo "   Archivo '$LOG_GENERAL' no encontrado. Saltando."
fi

# --- FIN DE SECCIONES DE LIMPIEZA PARA check_URL ---


# 7. Eliminar la estructura de directorios principal (Bash_script/)
# Este paso debe ir al final, ya que los archivos internos (Lista_Usuarios.txt) se necesitan para la limpieza anterior
echo "7. Eliminando estructura de directorios 'Bash_script/'..."
if [ -d "Bash_script" ]; then
    sudo rm -rf Bash_script/
    echo "   Directorio 'Bash_script/' eliminado."
else
    echo "   Directorio 'Bash_script/' no encontrado. Saltando."
fi

echo "---------------------------------------------------------"
echo "Proceso de limpieza finalizado."