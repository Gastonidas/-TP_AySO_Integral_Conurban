#! /bim/bash

# script para setear la llave ssh y modificar el archivo host para las maquinas 
echo "192.168.56.6 vmHost2.utnfra.com vmHost2 pc-redhat" | sudo tee -a /etc/hosts

echo "192.168.56.5 vmHost1.utnfra.com vmHost1 pc-ubuntu" | sudo tee -a /etc/hosts


ssh-keygen -t ed25519

ssh-copy-id vagrant@pc-ubuntu

