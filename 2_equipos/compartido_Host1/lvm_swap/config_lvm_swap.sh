#!/bin/bash
set -e

echo "Iniciando configuración de volúmenes LVM y partición swap..."

DISCO1="/dev/sdf" # 5G
DISCO2="/dev/sde" # 3G
DISCO_SWAP="/dev/sdc" # 1G

# busqueda de particiones existentes utilizando grep. si se encuentran coincidencias, se cancela para evitar sobrescribir datos
if lsblk -n -o NAME /dev/sdf /dev/sde | grep -qE 'sdf1|sde1'; then
    echo "Ya existen particiones"
    exit 1
fi


# limpieza y particionado
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

# particionado swap
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

# crear volúmenes físicos
pvcreate ${DISCO1}1
pvcreate ${DISCO2}1

# eliminar VG si existen (evitar error al crear)
vgremove vg_datos vg_temp -f || true

# crear grupos de volúmenes
vgcreate vg_datos ${DISCO1}1
vgcreate vg_temp ${DISCO2}1

# crear volúmenes lógicos
lvcreate -L 10M -n lv_docker vg_datos
lvcreate -L 2.5G -n lv_workareas vg_datos
lvcreate -L 2.5G -n lv_swap vg_temp

lsblk
sudo vgs
sudo lvs

