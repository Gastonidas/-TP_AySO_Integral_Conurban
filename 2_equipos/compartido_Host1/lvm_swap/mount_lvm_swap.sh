#!/bin/bash
set -e

# formatear y activar swap
mkfs.ext4 /dev/vg_datos/lv_docker
mkfs.ext4 /dev/vg_datos/lv_workareas
mkswap /dev/vg_temp/lv_swap
mkswap ${DISCO_SWAP}1

# crear puntos de montaje
mkdir -p /var/lib/docker
mkdir -p /work

# montar y activar
mount /dev/vg_datos/lv_docker /var/lib/docker
mount /dev/vg_datos/lv_workareas /work
swapon /dev/vg_temp/lv_swap
swapon ${DISCO_SWAP}1

# reiniciar docker si existe
if which docker &>/dev/null; then
    systemctl restart docker
fi

# persistencia en fstab (para evitar duplicados)
grep -q "${DISCO_SWAP}1" /etc/fstab || echo "${DISCO_SWAP}1 none swap sw 0 0" >> /etc/fstab
grep -q "lv_docker" /etc/fstab || echo "/dev/vg_datos/lv_docker /var/lib/docker ext4 defaults 0 2" >> /etc/fstab
grep -q "lv_workareas" /etc/fstab || echo "/dev/vg_datos/lv_workareas /work ext4 defaults 0 2" >> /etc/fstab
grep -q "lv_swap" /etc/fstab || echo "/dev/vg_temp/lv_swap none swap sw 0 0" >> /etc/fstab

echo "Configuración finalizada."

lsblk

