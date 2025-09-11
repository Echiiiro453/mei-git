#!/bin/bash

# setup.sh - Instala depend�ncias essenciais para o MEI Git

set -e

echo "???? Iniciando setup do MEI Git..."

# Fun��o para detectar a distribui��o
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "?? N�o foi poss�vel detectar a distribui��o. Instale as depend�ncias manualmente."
        exit 1
    fi
}

# Fun��o para instalar pacotes
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
            echo "???? Distribui��o '$OS' n�o suportada por este script."
            echo "   Instale manualmente: $pkgs"
            ;;
    esac
}

# --- L�gica Principal ---
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

echo "?? Setup conclu�do! O MEI Git est� pronto para ser usado."
echo "   Para criar o comando global rode:"
echo "   sudo ln -sf \$(pwd)/mei_git.py /usr/local/bin/mei-git"
