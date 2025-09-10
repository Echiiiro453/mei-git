#!/usr/bin/env bash

set -e

echo "🔍 Detectando distribuição Linux..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Não consegui identificar a distro."
    exit 1
fi

echo "📌 Distro detectada: $DISTRO"
echo "⚙️ Instalando dependências..."

case "$DISTRO" in
    arch|manjaro)
        sudo pacman -Syu --noconfirm
        sudo pacman -S --needed --noconfirm base-devel dkms linux-headers git
        ;;
    ubuntu|debian|linuxmint|pop)
        sudo apt update
        sudo apt install -y build-essential dkms linux-headers-$(uname -r) git
        ;;
    fedora)
        sudo dnf install -y @development-tools dkms kernel-devel kernel-headers git
        ;;
    opensuse*|suse)
        sudo zypper install -y -t pattern devel_basis
        sudo zypper install -y dkms kernel-devel kernel-default-devel git
        ;;
    *)
        echo "⚠️ Distro $DISTRO não suportada automaticamente."
        echo "👉 Instale manualmente: compilador (gcc, make), dkms, linux-headers, git."
        ;;
esac

echo "✅ Dependências instaladas com sucesso!"
echo "Agora você pode rodar: python mei_git.py install [wifi|bluetooth|ethernet|audio|video]"


