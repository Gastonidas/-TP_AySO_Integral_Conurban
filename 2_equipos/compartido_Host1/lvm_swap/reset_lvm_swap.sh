#!/bin/bash

# detiene la ejecución si algún comando falla
set -e

# apagar swap
swapoff -a

# detener Docker si está activo
if systemctl is-active --quiet docker; then
    systemctl stop docker
fi

# desmontar puntos de montaje si están montados
mountpoint -q /var/lib/docker && umount /var/lib/docker || echo "/var/lib/docker no está montado"
mountpoint -q /work && umount /work || echo "/work no está montado"

# intentar eliminar volúmenes lógicos si existen
lvremove -fy /dev/vg_datos/lv_docker 2>/dev/null || echo "lv_docker no existe o ya fue eliminado"
lvremove -fy /dev/vg_datos/lv_workareas 2>/dev/null || echo "lv_workareas no existe o ya fue eliminado"
lvremove -fy /dev/vg_temp/lv_swap 2>/dev/null || echo "lv_swap no existe o ya fue eliminado"

# eliminar grupos de volúmenes si existen
vgremove -fy vg_datos 2>/dev/null || echo "vg_datos no existe o ya fue eliminado"
vgremove -fy vg_temp 2>/dev/null || echo "vg_temp no existe o ya fue eliminado"

# intentar reducir VG si aún está usando algún PV
vgreduce --removemissing vg_datos 2>/dev/null || echo "No fue necesario reducir vg_datos"

# eliminar volúmenes físicos si no están en uso
pvremove -ffy /dev/sdf1 /dev/sde1 /dev/sdd1 2>/dev/null || echo "No se pudieron eliminar algunos PVs"

# limpiar firmas de todos los discos usados
wipefs -a /dev/sdf
wipefs -a /dev/sde
wipefs -a /dev/sdd
wipefs -a /dev/sdc

echo "Reinicio de discos completado."

