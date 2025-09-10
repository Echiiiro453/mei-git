#!/usr/bin/env bash
# MEI Git - setup.sh
# Script de setup universal para instalar dependências em múltiplas distros

set -e

echo "🔎 Detectando distribuição Linux..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Não foi possível detectar a distribuição."
    exit 1
fi

echo "➡️ Distro detectada: $DISTRO"

install_pkg() {
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y "$@"
            ;;
        fedora|rhel|centos)
            sudo dnf install -y "$@"
            ;;
        arch)
            sudo pacman -Sy --noconfirm "$@"
            ;;
        opensuse*|suse)
            sudo zypper install -y "$@"
            ;;
        *)
            echo "⚠️ Distro não suportada automaticamente. Instale manualmente: $@"
            ;;
    esac
}

echo "📦 Instalando dependências..."
install_pkg git make build-essential dkms linux-headers-$(uname -r) usbutils pciutils

echo "✅ Setup finalizado com sucesso!"

