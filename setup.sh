#!/bin/bash

# setup.sh - Instala dependências essenciais para o MEI Git (v2, com suporte a Deepin)

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

    # Adicionamos "deepin" na mesma regra de "ubuntu" e "debian"
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin")
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
            echo "Por favor, instale manualmente: $pkgs"
            return 1 # Retorna um código de erro
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "?? Falha na instalação das dependências. Verifique os erros acima."
        exit 1
    fi
}

# --- Lógica Principal ---
detect_distro

# Define os pacotes baseados na distro
if [ "$OS" == "arch" ]; then
    PACKAGES="git dkms base-devel linux-headers"
else
    PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
fi

install_packages "$PACKAGES"

echo "?? Setup concluído! O MEI Git está pronto para ser usado."
echo "   Para criar o comando global, rode o seguinte comando:"
echo "   sudo ln -sf \$(pwd)/mei_git.py /usr/local/bin/mei-git"
