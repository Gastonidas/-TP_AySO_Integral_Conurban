#!/bin/bash

# Preparar la estructura del proyecto y ejecutar scripts de configuración inicial.

echo "Iniciando la configuración inicial de la VM..."
echo "---------------------------------------------------------"


echo "cruzado de claves"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
ssh-copy-id -i ~/.ssh/id_ed25519.pub vagrant@192.168.56.5
ssh-copy-id -i ~/.ssh/id_ed25519.pub vagrant@192.168.56.6

# 1 Crear la estructura de directorios
echo "Creando estructura de directorios: Bash_script/"
mkdir -p Bash_script/{alta_usuarios,check_url} && touch Bash_script/alta_usuarios/{alta_usuarios.sh,Lista_Usuarios.txt} Bash_script/check_url/{check_URL.sh,Lista_URL.txt,README.md}
echo "Estructura creada con éxito."

# 2 Crear y rellenar Lista_Usuarios.txt
echo "Creando y rellenando Bash_script/alta_usuarios/Lista_Usuarios.txt..."
cat << EOF_LISTA_USUARIOS > Bash_script/alta_usuarios/Lista_Usuarios.txt
#---------------------#
# Listado de Usuarios separando campos por coma.
# Nombre_Usuario , Grupo_Primario , Directorio_Home
#---------------------#
gfragueiro,G_R1,/home/gfragueiro
dhaunau,G_R2,/home/dhaunau
fojeda,G_R3,/home/fojeda
asanchez,G_R4,/home/asanchez
lfonseca,G_R5,/home/lfonseca
agil,G_R6,/home/agil
EOF_LISTA_USUARIOS
echo "Lista_Usuarios.txt creada con éxito."

# 3. Crear y rellenar alta_usuarios.sh
echo "Creando y rellenando Bash_script/alta_usuarios/alta_usuarios.sh..."
cat << 'EOF_ALTA_USUARIOS_SCRIPT' > Bash_script/alta_usuarios/alta_usuarios.sh
#!/bin/bash

# Script: alta_usuarios.sh
# Descripcion: Crea usuarios y sus grupos primarios leyendo de Lista_Usuarios.txt usando awk.

# Ruta al archivo con la lista de usuarios.
USUARIOS_FILE="Bash_script/alta_usuarios/Lista_Usuarios.txt"

echo "Iniciando creacion de usuarios desde $USUARIOS_FILE"
echo "---------------------------------------------------------"

# Usar 'awk' para procesar el archivo.
# 'NR <= 7 || /^#/' : Ignora las primeras 7 líneas (comentarios) o líneas que empiezan con #.
awk -F ',' '!/^#/ && NF >= 3 {
    USERNAME=$1
    PRIMARY_GROUP=$2
    HOME_DIR=$3
    # Usando comas para concatenar en print
    print "Procesando usuario: " USERNAME
    print "   - Creando grupo: " PRIMARY_GROUP "..."
    system("groupadd " PRIMARY_GROUP) # QUITADO SUDO
    print "     Grupo " PRIMARY_GROUP " creado."
    print "   - Creando usuario: " USERNAME "..."
    system("useradd -m -d " HOME_DIR " -g " PRIMARY_GROUP " -s /bin/bash " USERNAME) # QUITADO SUDO
    print "     Usuario " USERNAME " creado (o intento de creacion)."
    print "---------------------------------------------------------"
}' "$USUARIOS_FILE"

echo "Proceso de alta de usuarios finalizado."
EOF_ALTA_USUARIOS_SCRIPT
echo "alta_usuarios.sh creado con éxito."

USUARIOS_FILE="Bash_script/alta_usuarios/Lista_Usuarios.txt"


# 4. Dar permisos de ejecución a los scripts
echo "Asignando permisos de ejecución a los scripts..."

chmod +x Bash_script/alta_usuarios/alta_usuarios.sh 

echo "Permisos asignados."

# 5. Ejecutar el script de alta de usuarios
echo "Ejecutando Bash_script/alta_usuarios/alta_usuarios.sh..."
# Necesita sudo porque useradd y groupadd lo requieren
sudo Bash_script/alta_usuarios/alta_usuarios.sh
echo "Ejecución de alta_usuarios.sh completada."

# 6. Crear el grupo secundario para sudo sin contraseña
GRUPO_SUDO="grupo_sec"
echo "---------------------------------------------------------"
echo "Configurando grupo '$GRUPO_SUDO' para sudo sin contraseña..."
echo "   - Creando grupo '$GRUPO_SUDO'..."
sudo groupadd "$GRUPO_SUDO" 

# 7. Añadir los usuarios creados al grupo secundario
echo "   - Añadiendo usuarios a '$GRUPO_SUDO'..."
# Leemos de nuevo Lista_Usuarios.txt para obtener los nombres de usuario
awk -F ',' -v GRUPO_SUDO="$GRUPO_SUDO" '!/^#/ && NF >= 1 {
    USERNAME_TO_ADD = $1
    print "Añadiendo usuario " USERNAME_TO_ADD " al grupo " GRUPO_SUDO "..."
    system("usermod -aG " GRUPO_SUDO " " USERNAME_TO_ADD)
    print "Usuario " USERNAME_TO_ADD " añadido."
}' "$USUARIOS_FILE"


# 8. Configurar sudoers para el grupo (la linea que te interesaba)
echo "   - Configurando sudoers para que el grupo '$GRUPO_SUDO' use sudo sin contraseña..."
sudo cat /etc/sudoers.d/vagrant | sed "s/vagrant/%$GRUPO_SUDO/g" | sudo tee /etc/sudoers.d/"$GRUPO_SUDO"
echo "   Configuracion de sudoers para '$GRUPO_SUDO' aplicada."

echo "---------------------------------------------------------"
echo "Configuración inicial de la VM finalizada."

# --------------check_url-------------------------
# 1: crear la estructura de directorio /tmp/head-check/

mkdir -p /tmp/head-check/{OK,Error/{cliente,servidor}}

# 2: escribir el archivo Lista_URL.txt con las urls a validar
cat << EOF_LISTA_URL > Bash_script/check_url/Lista_URL.txt
#---------------------#
# Listado de URLs a verificar. Una URL por línea.
# Formato: DOMINIO,URL_COMPLETA
#---------------------#
google.com,https://www.google.com
github.com,https://github.com
example.com,http://example.com/nonexistent 
httpbin.org,https://httpbin.org/status/500 
EOF_LISTA_URL

# crear el archivo /var/log/status_URL.log
mkdir -p /var/log && touch /var/log/status_URL.log

#--- Escribir el script check_URL.sh -------------
cat << 'EOF_CHECK_URL' > Bash_script/check_url/check_URL.sh
#!/bin/bash
BASE_LOG_DIR="/tmp/head-check"

LISTA_URLS="$(dirname "$0")/Lista_URL.txt"

#Linea para evitar errores con saltos de linea dentro del for
OLD_IFS=$IFS
IFS=$'\n'
for LINEA in $(cat "$LISTA_URLS")
do
    # Ignorar líneas de comentarios o vacías
    [[ "$LINEA" =~ ^#.*$ || -z "$LINEA" ]] && continue
    
    #Separar dominio y URL usando cut
    DOMINIO=$(echo "$LINEA" | cut -d',' -f1)
    URL=$(echo "$LINEA" | cut -d',' -f2)

    # Obtener el código de estado HTTP
    STATUS_CODE=$(curl -LI -o /dev/null -w '%{http_code}\n' -s "$URL")

    # Obtener fecha y hora actual
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    # Formatear la línea de log
    LOG_LINE="$TIMESTAMP - Code:$STATUS_CODE - URL:$URL"

    echo "Verificando $URL (Dominio: $DOMINIO) - Status: $STATUS_CODE"

    # Guardar en el log general
    echo "$LOG_LINE" | sudo tee -a "/var/log/status_URL.log"

    #segun el status_code, crear archivo con el nombredeldominio.log y registrarlo en ok, cliente o servidor segun corresponda
    if [ "$STATUS_CODE" == "200" ]; then
        DESTINO_FOLDER="$BASE_LOG_DIR/OK"
    elif [[ "$STATUS_CODE" -ge 400 && "$STATUS_CODE" -le 499 ]]; then
        DESTINO_FOLDER="$BASE_LOG_DIR/Error/cliente"
    elif [[ "$STATUS_CODE" -ge 500 && "$STATUS_CODE" -le 599 ]]; then
        DESTINO_FOLDER="$BASE_LOG_DIR/Error/servidor"
    else
        echo "Advertencia: Código de estado $STATUS_CODE para $URL no se encuentra en rango"
        continue
    fi

    # Guardar en log por dominio (dominio.log en la carpeta correspondiente)
    echo "$LOG_LINE" >> "$DESTINO_FOLDER/${DOMINIO}.log"
done
# Restaurar IFS original
IFS=$OLD_IFS

echo "Proceso de verificación de URLs finalizado."

EOF_CHECK_URL

echo "check_URL.sh creado con éxito."

# 11. Dar permisos de ejecución a check_URL.sh
echo "Asignando permisos de ejecución a Bash_script/check_url/check_URL.sh..."
chmod +x Bash_script/check_url/check_URL.sh
echo "Permisos asignados."

# 12. Ejecutar el script check_URL.sh
echo "---------------------------------------------------------"
echo "Ejecutando Bash_script/check_url/check_URL.sh para verificar URLs..."
# Es importante ejecutarlo con sudo para que pueda escribir en /var/log/
sudo Bash_script/check_url/check_URL.sh
echo "Ejecución de check_URL.sh completada."

echo "---------------------------------------------------------"
echo "Configuración completa de la VM finalizada."





