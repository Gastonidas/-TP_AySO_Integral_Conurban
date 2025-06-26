#!/bin/bash

# script para setear la llave ssh y modificar el archivo host para las maquinas 
echo "192.168.56.6 vmHost2.utnfra.com vmHost2 pc-redhat" | sudo tee -a /etc/hosts

echo "192.168.56.5 vmHost1.utnfra.com vmHost1 pc-ubuntu" | sudo tee -a /etc/hosts


# Generar la clave SSH automáticamente, solo si no existe
if [ ! -f ~/.ssh/id_ed25519 ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q
fi

ssh-copy-id -o StrictHostKeyChecking=no vagrant@pc-ubuntu

