#!/bin/bash
# Atualiza o sistema
sudo apt update && sudo apt upgrade -y

# Dependências para compilar drivers
sudo apt install -y build-essential git dkms linux-headers-$(uname -r) lshw pciutils usbutils

echo "Setup concluído! Você pode usar mei-git agora."
