#!/bin/bash

#configura /etc/hosts
grep -q "192.168.56.6" /etc/hosts || echo "192.168.56.6 vmHost2.utnfra.com vmHost2 pc-redhat" | sudo tee -a /etc/hosts
grep -q "192.168.56.5" /etc/hosts || echo "192.168.56.5 vmHost1.utnfra.com vmHost1 pc-ubuntu" | sudo tee -a /etc/hosts

# Configuración SSH
echo "Configurando claves SSH..."
[ ! -d ~/.ssh ] && mkdir ~/.ssh && chmod 700 ~/.ssh
[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# Acepta automáticamente el fingerprint y copia la clave
ssh-keyscan pc-redhat >> ~/.ssh/known_hosts 2>/dev/null
cat ~/.ssh/id_ed25519.pub | ssh vagrant@pc-redhat "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

echo "Configuración completada. Prueba con: ssh vagrant@pc-redhat"