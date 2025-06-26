cript: reset.sh
# Descripción: Revierte todos los cambios realizados por setup_vm.sh,
#              eliminando usuarios, grupos, directorios y archivos de log.
#
# Uso: sudo ./reset.sh

echo "Iniciando el proceso de reseteo de la VM..."
echo "---------------------------------------------------------"

# Definir variables clave para la limpieza (deben coincidir con setup_vm.sh)
USUARIOS_FILE="Bash_script/alta_usuarios/Lista_Usuarios.txt"
GRUPO_SUDO="grupo_sec"
BASE_LOG_DIR="/tmp/head-check"
LOG_GENERAL="/var/log/status_URL.log"

# --- Limpieza de sudoers ---
echo "1. Limpiando configuración de sudoers para '$GRUPO_SUDO'..."
if [ -f "/etc/sudoers.d/$GRUPO_SUDO" ]; then
	    sudo rm -f "/etc/sudoers.d/$GRUPO_SUDO"
	        echo "   Archivo /etc/sudoers.d/$GRUPO_SUDO eliminado."
	else
		    echo "   Archivo /etc/sudoers.d/$GRUPO_SUDO no encontrado. Saltando."
fi

# --- Limpieza de Usuarios y Grupos Primarios ---
echo "2. Eliminando usuarios y sus grupos primarios..."
if [ -f "$USUARIOS_FILE" ]; then
	    # Leer el archivo de usuarios y procesar cada línea que no sea un comentario
	        # Usamos IFS= read -r para manejar nombres con espacios, aunque no aplica aquí, es buena práctica.
		    awk -F ',' '!/^#/ && NF >= 3 { print $1 "," $2 }' "$USUARIOS_FILE" | while IFS=',' read -r USERNAME PRIMARY_GROUP; do
		            # Eliminar usuario
			            if id -u "$USERNAME" >/dev/null 2>&1; then
					                echo "   - Eliminando usuario '$USERNAME' y su directorio home..."
							            sudo userdel -r "$USERNAME"
								                if [ $? -eq 0 ]; then
											                echo "     Usuario '$USERNAME' eliminado con éxito."
													            else
															                    echo "     Error al eliminar usuario '$USERNAME'. Podría tener procesos activos o ser primario de un grupo."
																	                fi
																			        else
																					            echo "   - Usuario '$USERNAME' no existe. Saltando eliminación."
																						            fi

																							            # Eliminar grupo primario (solo si no es el grupo principal de ningún usuario existente)
																								            # Esto es más seguro hacerlo después de eliminar los usuarios.
																									            if getent group "$PRIMARY_GROUP" > /dev/null 2>&1; then
																											                # Verificar si el grupo tiene miembros distintos del propio grupo que va a ser eliminado
																													            # (ya que `userdel -r` debería limpiar el usuario del grupo)
																														                if [ -z "$(getent group "$PRIMARY_GROUP" | cut -d: -f4)" ]; then # Si la lista de miembros está vacía
																																	                echo "   - Eliminando grupo primario '$PRIMARY_GROUP'..."
																																			                sudo groupdel "$PRIMARY_GROUP"
																																					                if [ $? -eq 0 ]; then
																																								                    echo "     Grupo '$PRIMARY_GROUP' eliminado con éxito."
																																										                    else
																																													                        echo "     Error al eliminar grupo '$PRIMARY_GROUP'. Podría tener miembros inesperados."
																																																                fi
																																																		            else
																																																				                    echo "   - Grupo '$PRIMARY_GROUP' todavía tiene miembros. No se eliminará automáticamente."
																																																						                fi
																																																								        else
																																																										            echo "   - Grupo '$PRIMARY_GROUP' no existe. Saltando eliminación."
																																																											            fi
																																																												        done
																																																													    echo "   Proceso de eliminación de usuarios y grupos primarios completado."
																																																												    else
																																																													        echo "   Advertencia: '$USUARIOS_FILE' no encontrado. No se eliminarán usuarios ni grupos primarios."
fi

# --- Limpieza del Grupo Secundario de Sudo ---
echo "3. Eliminando grupo secundario '$GRUPO_SUDO'..."
if getent group "$GRUPO_SUDO" > /dev/null 2>&1; then
	    sudo groupdel "$GRUPO_SUDO"
	        if [ $? -eq 0 ]; then
			        echo "   Grupo '$GRUPO_SUDO' eliminado."
				    else
					            echo "   Error al eliminar el grupo '$GRUPO_SUDO'."
						        fi
						else
							    echo "   Grupo '$GRUPO_SUDO' no existe. Saltando."
fi

# --- Limpieza de directorios y logs de check_url ---
echo "4. Limpiando directorios y archivos de logs de check_url..."
if [ -d "$BASE_LOG_DIR" ]; then
	    sudo rm -rf "$BASE_LOG_DIR"
	        echo "   Directorio '$BASE_LOG_DIR/' eliminado."
	else
		    echo "   Directorio '$BASE_LOG_DIR/' no encontrado. Saltando."
fi

if [ -f "$LOG_GENERAL" ]; then
	    sudo rm -f "$LOG_GENERAL"
	        echo "   Archivo '$LOG_GENERAL' eliminado."
	else
		    echo "   Archivo '$LOG_GENERAL' no encontrado. Saltando."
fi

# --- Limpieza de la estructura principal de directorios ---
echo "5. Eliminando la estructura de directorios 'Bash_script/'..."
if [ -d "Bash_script" ]; then
	    # Primero, eliminamos todos los archivos creados dentro para asegurar.
	        # Esto es redundante si rm -rf funciona bien, pero es una capa extra.
		    sudo rm -f Bash_script/alta_usuarios/{alta_usuarios.sh,Lista_Usuarios.txt}
		        sudo rm -f Bash_script/check_url/{check_URL.sh,Lista_URL.txt,README.md}
			    sudo rm -rf Bash_script/
			        echo "   Directorio 'Bash_script/' eliminado."
			else
				    echo "   Directorio 'Bash_script/' no encontrado. Saltando."
fi

echo "---------------------------------------------------------"
echo "Proceso de reseteo completado. La VM debería estar en su estado original."
