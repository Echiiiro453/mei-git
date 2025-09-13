#!/bin/bash

# setup.sh - v6.5 - Instalador com modo seguro e transparente para Arch Linux

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

export LANG=C.UTF-8
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE"

# --- Funções de Interface ---
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' nao encontrado. Instalando..."
        export DEBIAN_FRONTEND=noninteractive
        if command -v apt-get &> /dev/null; then apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &> /dev/null; then dnf install -y dialog
        elif command -v pacman &> /dev/null; then pacman -S --noconfirm dialog
        fi
    fi
}
show_message() {
    if command -v dialog &> /dev/null; then dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 78
    else echo -e "\n$1\n"; fi
}
ask_yes_no() {
    if command -v dialog &> /dev/null; then dialog --title "Confirmacao" --cr-wrap --yesno "$1" 12 78; return $?
    else read -p "$1 [S/n] " choice; case "$choice" in [sS][iI][mM]|[sS]|"") return 0 ;; *) return 1 ;; esac; fi
}

# --- Funções de Instalação por Família ---

run_install_debian_family() {
    PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)" "python3-dialog")
    CMD_UPDATE="apt-get update"
    CMD_INSTALL="apt-get install -y"
    TOTAL_STEPS=$((${#PACKAGES[@]} + 1)); CURRENT_STEP=0
    (
        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); echo $PERCENTAGE; echo "XXX"; echo "Etapa 1: Atualizando lista de pacotes..."; echo "XXX"; eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        for pkg in "${PACKAGES[@]}"; do
            ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); PKG_NUM=$((CURRENT_STEP - 1))
            PROGRESS_TEXT="Etapa 2: Instalando $pkg ($PKG_NUM de ${#PACKAGES[@]})"
            echo $PERCENTAGE; echo "XXX"; echo "$PROGRESS_TEXT"; echo "XXX"
            eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi; sleep 0.5
        done
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1; echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Debian/Ubuntu" --gauge "Iniciando..." 12 80 0
    echo $(cat /tmp/mei-git-status.txt) > /tmp/mei-git-status.txt
}

run_install_fedora_family() {
    PACKAGES=("git" "dkms" "kernel-devel-$(uname -r)" "python3-dialog" "Development Tools")
    CMD_UPDATE="echo 'DNF nao precisa de update separado.'"
    CMD_INSTALL="dnf install -y"; CMD_GROUP_INSTALL="dnf groupinstall -y"
    TOTAL_STEPS=$((${#PACKAGES[@]} + 1)); CURRENT_STEP=0
    (
        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); echo $PERCENTAGE; echo "XXX"; echo "Etapa 1: Verificando DNF..."; echo "XXX"; eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        for pkg in "${PACKAGES[@]}"; do
            ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); PKG_NUM=$((CURRENT_STEP - 1))
            PROGRESS_TEXT="Etapa 2: Instalando $pkg ($PKG_NUM de ${#PACKAGES[@]})"
            echo $PERCENTAGE; echo "XXX"; echo "$PROGRESS_TEXT"; echo "XXX"
            if [[ "$pkg" == "Development Tools" ]]; then eval "$CMD_GROUP_INSTALL \"$pkg\"" >> "$LOG_FILE" 2>&1
            else eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1; fi
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi; sleep 0.5
        done
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1; echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Fedora/RHEL" --gauge "Iniciando..." 12 80 0
    echo $(cat /tmp/mei-git-status.txt) > /tmp/mei-git-status.txt
}

run_install_arch_family() {
    OFFICIAL_PACKAGES="git dkms base-devel linux-headers dialog"
    AUR_PACKAGE="python-pythondialog"
    COMMAND="pacman -Syu --noconfirm --needed $OFFICIAL_PACKAGES"
    
    show_message "No Arch Linux, a instalação será exibida em uma janela de texto para garantir a compatibilidade e evitar travamentos.\\n\\nVocê verá a saída do comando 'pacman' em tempo real."
    
    if command -v dialog &> /dev/null; then
        dialog --title "Instalando Dependencias Oficiais para Arch..." --programbox "$COMMAND" 25 90
        INSTALL_STATUS=$?
    else
        eval $COMMAND
        INSTALL_STATUS=$?
    fi

    # Sinaliza o status para a lógica principal
    echo $INSTALL_STATUS > /tmp/mei-git-status.txt
    
    # Verifica se o pacote do AUR precisa de atenção
    if ! pacman -Q "$AUR_PACKAGE" &> /dev/null; then
        if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
            declare -g AUR_INSTRUCTIONS_NEEDED=true
        fi
    fi
}

# --- Lógica Principal ---
main() {
    install_dialog_if_missing
    show_message "Bem-vindo ao instalador de dependencias do MEI Git!"
    if ! ask_yes_no "Deseja continuar com a instalacao das dependencias?"; then
        show_message "Instalacao cancelada."; exit 0; fi

    if [ -f /etc/os-release ]; then . /etc/os-release; OS=$ID; else
        show_message "?? Nao foi possivel detectar a distribuicao."; exit 1; fi

    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            run_install_debian_family ;;
        "fedora" | "rhel" | "centos")
            run_install_fedora_family ;;
        "arch" | "endeavouros" | "manjaro")
            run_install_arch_family ;;
        *)
            show_message "?? Distribuicao '$OS' nao suportada."; exit 1 ;;
    esac
    
    FINAL_STATUS=$(cat /tmp/mei-git-status.txt 2>/dev/null); rm /tmp/mei-git-status.txt 2>/dev/null
    if [ "$FINAL_STATUS" != "0" ]; then
        show_message "?? Falha na instalacao. Verifique a saída do terminal ou o log em $LOG_FILE."; exit 1; fi
    
    # Mensagem Final
    clear
    echo "=================================================================="
    echo "?? Setup concluído!"
    
    if [ "$AUR_INSTRUCTIONS_NEEDED" = true ]; then
        echo -e "\n\033[1;33mATENÇÃO: AÇÃO MANUAL NECESSÁRIA (SOMENTE PARA ARCH LINUX)\033[0m"
        echo "Para a interface gráfica do 'mei-git' funcionar, você precisa de um pacote do AUR."
        echo ""
        echo "1. Instale um ajudante AUR como o 'yay', se ainda não tiver:"
        echo -e "   \033[0;32mgit clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si\033[0m"
        echo ""
        echo "2. Use o 'yay' para instalar a dependência que falta:"
        echo -e "   \033[0;32myay -S python-pythondialog\033[0m"
        echo ""
    fi
    
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git\" /usr/local/bin/mei-git"
    echo ""
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""; echo -e "\033[1;32msudo $FINAL_CMD\033[0m"; echo ""
    echo "=================================================================="
}

main