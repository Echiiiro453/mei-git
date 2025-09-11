#!/bin/bash

# setup.sh - Instala depend�ncias essenciais para o MEI Git
# Vers�o 3.0 - Suporte expandido a mais distribui��es

echo "???? Iniciando setup do MEI Git..."

# Fun��o para detectar a distribui��o
detect_distro() {
    if [ -f /etc/os-release ]; then
        # L� o arquivo de release para obter as vari�veis
        . /etc/os-release
        OS=$ID
    else
        echo "?? N�o foi poss�vel detectar a distribui��o. Instale as depend�ncias manualmente."
        exit 1
    fi
}

# Fun��o para instalar pacotes
install_packages() {
    echo "???? Detectada distro: $OS."
    
    # Define os pacotes e o comando de instala��o para cada fam�lia de distro
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            echo "   (Fam�lia Debian/Ubuntu)"
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            COMMAND="sudo apt-get update && sudo apt-get install -y $PACKAGES"
            ;;
        "fedora" | "rhel" | "centos")
            echo "   (Fam�lia Red Hat/Fedora)"
            # kernel-devel � o equivalente de linux-headers
            PACKAGES="git dkms kernel-devel"
            COMMAND="sudo dnf install -y $PACKAGES && sudo dnf groupinstall -y \"Development Tools\""
            ;;
        "arch" | "endeavouros" | "manjaro")
            echo "   (Fam�lia Arch Linux)"
            # base-devel � o equivalente de build-essential
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="sudo pacman -Syu --noconfirm $PACKAGES"
            ;;
        "opensuse-tumbleweed" | "opensuse-leap")
            echo "   (Fam�lia openSUSE)"
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
            # system.devel � o grupo de pacotes de compila��o
            PACKAGES="git dkms linux-current-headers system.devel"
            COMMAND="sudo eopkg it -y $PACKAGES"
            ;;
        *)
            echo "?? Distribui��o '$OS' n�o suportada por este script de setup."
            echo "   Por favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    echo "   Executando o comando de instala��o..."
    
    # Executa o comando de instala��o definido
    eval $COMMAND

    if [ $? -ne 0 ]; then
        echo "?? Falha na instala��o das depend�ncias. Verifique os erros acima."
        exit 1
    fi
}

# --- L�gica Principal ---
detect_distro
install_packages

echo "?? Setup conclu�do! O MEI Git est� pronto para ser usado."
echo "   Para criar o comando global, rode o seguinte comando:"
echo "   sudo ln -sf \$(pwd)/mei_git.py /usr/local/bin/mei-git"
