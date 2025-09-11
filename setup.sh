#!/bin/bash

# setup.sh - Instala dependências essenciais para o MEI Git
# Versão 3.0 - Suporte expandido a mais distribuições

echo "???? Iniciando setup do MEI Git..."

# Função para detectar a distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        # Lê o arquivo de release para obter as variáveis
        . /etc/os-release
        OS=$ID
    else
        echo "?? Não foi possível detectar a distribuição. Instale as dependências manualmente."
        exit 1
    fi
}

# Função para instalar pacotes
install_packages() {
    echo "???? Detectada distro: $OS."
    
    # Define os pacotes e o comando de instalação para cada família de distro
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            echo "   (Família Debian/Ubuntu)"
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            COMMAND="sudo apt-get update && sudo apt-get install -y $PACKAGES"
            ;;
        "fedora" | "rhel" | "centos")
            echo "   (Família Red Hat/Fedora)"
            # kernel-devel é o equivalente de linux-headers
            PACKAGES="git dkms kernel-devel"
            COMMAND="sudo dnf install -y $PACKAGES && sudo dnf groupinstall -y \"Development Tools\""
            ;;
        "arch" | "endeavouros" | "manjaro")
            echo "   (Família Arch Linux)"
            # base-devel é o equivalente de build-essential
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="sudo pacman -Syu --noconfirm $PACKAGES"
            ;;
        "opensuse-tumbleweed" | "opensuse-leap")
            echo "   (Família openSUSE)"
            PACKAGES="git dkms patterns-devel-base-devel_basis kernel-default-devel"
            COMMAND="sudo zypper install -y $PACKAGES"
            ;;
        "void")
            echo "   (Void Linux)"
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="sudo xbps-install -Syu $PACKAGES"
            ;;
        "solus")
            echo "   (Solus)"
            # system.devel é o grupo de pacotes de compilação
            PACKAGES="git dkms linux-current-headers system.devel"
            COMMAND="sudo eopkg it -y $PACKAGES"
            ;;
        *)
            echo "?? Distribuição '$OS' não suportada por este script de setup."
            echo "   Por favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    echo "   Executando o comando de instalação..."
    
    # Executa o comando de instalação definido
    eval $COMMAND

    if [ $? -ne 0 ]; then
        echo "?? Falha na instalação das dependências. Verifique os erros acima."
        exit 1
    fi
}

# --- Lógica Principal ---
detect_distro
install_packages

echo "?? Setup concluído! O MEI Git está pronto para ser usado."
echo "   Para criar o comando global, rode o seguinte comando:"
echo "   sudo ln -sf \$(pwd)/mei_git.py /usr/local/bin/mei-git"
