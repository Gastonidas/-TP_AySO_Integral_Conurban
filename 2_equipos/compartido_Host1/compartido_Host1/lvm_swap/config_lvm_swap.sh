#!/bin/bash
set -e -o pipefail -x

echo "Iniciando configuración de volúmenes LVM y partición swap..."

DISCO1="/dev/sdf" # 5G
DISCO2="/dev/sde" # 3G
DISCO_SWAP="/dev/sdc" # 1G

# Verificación de particiones existentes
for disco in $DISCO1 $DISCO2; do
    if lsblk -n -o NAME ${disco} | grep -q "${disco##*/}1"; then
        echo "Error: Ya existe una partición en $disco. Cancelando para evitar sobrescribir datos."
        exit 1
    fi
done

# Limpieza y particionado
for disco in $DISCO1 $DISCO2; do
    echo "Preparando $disco..."
    wipefs -a "$disco"

    fdisk "$disco" <<EOF
n
p
1


t
8e
w
EOF

    partprobe "$disco"
    sleep 1
done

# Particionado swap
wipefs -a "$DISCO_SWAP"
fdisk "$DISCO_SWAP" <<EOF
n
p
1


t
82
w
EOF
partprobe "$DISCO_SWAP"

# Crear volúmenes físicos
pvcreate ${DISCO1}1
pvcreate ${DISCO2}1

# Eliminar VG si existen (evitar error al crear)
vgremove vg_datos vg_temp -f || true

# Crear grupos de volúmenes
vgcreate vg_datos ${DISCO1}1
vgcreate vg_temp ${DISCO2}1

# Crear volúmenes lógicos
lvcreate -L 10M -n lv_docker vg_datos
lvcreate -L 2.5G -n lv_workareas vg_datos
lvcreate -L 2.5G -n lv_swap vg_temp

# Formatear y activar swap
mkfs.ext4 /dev/vg_datos/lv_docker
mkfs.ext4 /dev/vg_datos/lv_workareas
mkswap /dev/vg_temp/lv_swap
mkswap ${DISCO_SWAP}1

# Crear puntos de montaje
mkdir -p /var/lib/docker
mkdir -p /work

# Montar y activar
mount /dev/vg_datos/lv_docker /var/lib/docker
mount /dev/vg_datos/lv_workareas /work
swapon /dev/vg_temp/lv_swap
swapon ${DISCO_SWAP}1

# Reiniciar docker si existe
if which docker &>/dev/null; then
    systemctl restart docker
fi

# Persistencia en fstab (evitar duplicados)
grep -q "${DISCO_SWAP}1" /etc/fstab || echo "${DISCO_SWAP}1 none swap sw 0 0" >> /etc/fstab
grep -q "lv_docker" /etc/fstab || echo "/dev/vg_datos/lv_docker /var/lib/docker ext4 defaults 0 2" >> /etc/fstab
grep -q "lv_workareas" /etc/fstab || echo "/dev/vg_datos/lv_workareas /work ext4 defaults 0 2" >> /etc/fstab
grep -q "lv_swap" /etc/fstab || echo "/dev/vg_temp/lv_swap none swap sw 0 0" >> /etc/fstab

echo "Configuración finalizada."

