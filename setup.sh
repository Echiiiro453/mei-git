#!/bin/bash

# setup.sh - v5.6 - Instalador com verificação secundária de gerenciador de pacotes

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilégios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# Força o locale para UTF-8 para máxima compatibilidade
export LANG=C.UTF-8
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE"

# --- Funções de Interface ---
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' nao encontrado. Instalando..."
        export DEBIAN_FRONTEND=noninteractive
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &> /dev/null; then
            dnf install -y dialog
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm dialog
        fi
    fi
}
show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 78
    else
        echo -e "\n$1\n"
    fi
}
ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmacao" --cr-wrap --yesno "$1" 12 78
        return $?
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- Funções de Instalação por Família ---

run_install_debian_family() {
    PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)")
    CMD_UPDATE="apt-get update"
    CMD_INSTALL="apt-get install -y"
    TOTAL_PACKAGES=${#PACKAGES[@]}

    (
        echo 10; echo "XXX\nAtualizando lista de pacotes (apt)...\nXXX"
        eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        
        INSTALLED_COUNT=0
        for pkg in "${PACKAGES[@]}"; do
            ((INSTALLED_COUNT++)); PERCENTAGE=$((INSTALLED_COUNT * 80 / TOTAL_PACKAGES + 10))
            echo $PERCENTAGE; echo "XXX\nInstalando: $pkg ($INSTALLED_COUNT de $TOTAL_PACKAGES)...\nXXX"
            eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        done
        
        echo 100; echo "XXX\nFinalizando...\nXXX"; sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Debian/Ubuntu" --gauge "Iniciando..." 10 75 0
}

run_install_fedora_family() {
    PACKAGES=("git" "dkms" "kernel-devel" "Development Tools")
    CMD_INSTALL="dnf install -y"
    CMD_GROUP_INSTALL="dnf groupinstall -y"
    TOTAL_PACKAGES=${#PACKAGES[@]}

    (
        INSTALLED_COUNT=0
        for pkg in "${PACKAGES[@]}"; do
            ((INSTALLED_COUNT++)); PERCENTAGE=$((INSTALLED_COUNT * 100 / TOTAL_PACKAGES))
            echo $PERCENTAGE; echo "XXX\nInstalando: $pkg ($INSTALLED_COUNT de $TOTAL_PACKAGES)...\nXXX"
            if [[ "$pkg" == "Development Tools" ]]; then
                eval "$CMD_GROUP_INSTALL \"$pkg\"" >> "$LOG_FILE" 2>&1
            else
                eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            fi
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        done
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Fedora/RHEL" --gauge "Iniciando..." 10 75 0
}

run_install_arch_family() {
    PACKAGES=("git" "dkms" "base-devel" "linux-headers")
    CMD_INSTALL="pacman -S --noconfirm"
    TOTAL_PACKAGES=${#PACKAGES[@]}
    
    (
        INSTALLED_COUNT=0
        for pkg in "${PACKAGES[@]}"; do
            ((INSTALLED_COUNT++)); PERCENTAGE=$((INSTALLED_COUNT * 100 / TOTAL_PACKAGES))
            echo $PERCENTAGE; echo "XXX\nInstalando: $pkg ($INSTALLED_COUNT de $TOTAL_PACKAGES)...\nXXX"
            eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        done
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Arch Linux" --gauge "Iniciando..." 10 75 0
}


# --- Lógica Principal ---
main() {
    install_dialog_if_missing

    show_message "Bem-vindo ao instalador de dependencias do MEI Git!\n\nEste script ira preparar seu sistema para compilar e instalar drivers."
    if ! ask_yes_no "O script ira detectar sua distribuicao e instalar os pacotes necessarios.\n\nDeseja continuar?"; then
        show_message "Instalacao cancelada pelo usuario."; exit 0; fi

    if [ -f /etc/os-release ]; then . /etc/os-release; OS=$ID; else
        show_message "?? Nao foi possivel detectar a distribuicao."; exit 1; fi

    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            run_install_debian_family
            ;;
        "fedora" | "rhel" | "centos")
            run_install_fedora_family
            ;;
        "arch" | "endeavouros" | "manjaro")
            run_install_arch_family
            ;;
        *)
            show_message "Distro '$OS' nao reconhecida diretamente.\\n\\nTentando detectar o gerenciador de pacotes como um 'Plano B'..."
            
            if command -v apt-get &> /dev/null; then
                run_install_debian_family
            elif command -v dnf &> /dev/null; then
                run_install_fedora_family
            elif command -v pacman &> /dev/null; then
                run_install_arch_family
            else
                show_message "?? Nenhum gerenciador de pacotes conhecido (apt, dnf, pacman) foi encontrado."
                exit 1
            fi
            ;;
    esac
    
    FINAL_STATUS=$(cat /tmp/mei-git-status.txt)
    rm /tmp/mei-git-status.txt

    if [ $FINAL_STATUS -ne 0 ]; then
        show_message "?? Falha na instalacao de um dos pacotes. Verifique o log em $LOG_FILE para mais detalhes."
        exit 1
    fi

    FINAL_CMD="ln -sf \"\$(pwd)/mei_git\" /usr/local/bin/mei-git"
    show_message "?? Dependencias instaladas com sucesso!\\n\\nO MEI Git está pronto para o proximo passo."
    
    clear
    echo "=================================================================="
    echo "?? Setup concluido com sucesso!"
    echo ""
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""
    echo -e "\033[1;32msudo $FINAL_CMD\033[0m"
    echo ""
    echo "=================================================================="
}

main