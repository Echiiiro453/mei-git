#!/bin/bash

# setup.sh - Instala dependências essenciais para o MEI Git

set -e

echo "???? Iniciando setup do MEI Git..."

# Função para detectar a distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "?? Não foi possível detectar a distribuição. Instale as dependências manualmente."
        exit 1
    fi
}

# Função para instalar pacotes
install_packages() {
    local pkgs="$1"
    echo "???? Detectada distro: $OS. Instalando pacotes: $pkgs"

    case "$OS" in
        "ubuntu" | "debian" | "linuxmint")
            sudo apt-get update
            sudo apt-get install -y $pkgs
            ;;
        "fedora" | "rhel" | "centos")
            sudo dnf install -y $pkgs
            ;;
        "arch")
            sudo pacman -Syu --noconfirm $pkgs
            ;;
        "opensuse-tumbleweed" | "opensuse-leap")
            sudo zypper install -y $pkgs
            ;;
        *)
            echo "???? Distribuição '$OS' não suportada por este script."
            echo "   Instale manualmente: $pkgs"
            ;;
    esac
}

# --- Lógica Principal ---
detect_distro

# Define os pacotes baseados na distro
case "$OS" in
    "ubuntu" | "debian" | "linuxmint")
        PACKAGES="git dkms build-essential linux-headers-$(uname -r) hplip"
        ;;
    "fedora" | "rhel" | "centos")
        PACKAGES="git gcc make dkms kernel-devel hplip"
        ;;
    "arch")
        PACKAGES="git base-devel dkms linux-headers hplip"
        ;;
    "opensuse-tumbleweed" | "opensuse-leap")
        PACKAGES="git gcc make dkms kernel-devel hplip"
        ;;
    *)
        PACKAGES="git dkms build-essential linux-headers hplip"
        ;;
esac

install_packages "$PACKAGES"

echo "?? Setup concluído! O MEI Git está pronto para ser usado."
echo "   Para criar o comando global rode:"
echo "   sudo ln -sf \$(pwd)/mei_git.py /usr/local/bin/mei-git"
