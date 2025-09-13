#!/bin/bash

# setup.sh - v6.3 - Instalador com otimização de mirrors e progresso detalhado para Arch

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# Força o locale para UTF-8 para máxima compatibilidade
export LANG=C.UTF-8
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE" # Limpa o log antigo

# --- Funções de Interface ---
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "📦 Pacote 'dialog' nao encontrado. Instalando..."
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
    PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)" "python3-dialog")
    CMD_UPDATE="apt-get update"
    CMD_INSTALL="apt-get install -y"
    TOTAL_STEPS=$((${#PACKAGES[@]} + 1))
    CURRENT_STEP=0

    (
        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo $PERCENTAGE; echo "XXX"; echo "Etapa 1 de 2: Atualizando lista de pacotes..."; echo "XXX"
        eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        
        for pkg in "${PACKAGES[@]}"; do
            ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); PKG_NUM=$((CURRENT_STEP - 1))
            PROGRESS_TEXT="Etapa 2 de 2: Instalando $pkg ($PKG_NUM de ${#PACKAGES[@]})"
            echo $PERCENTAGE; echo "XXX"; echo "$PROGRESS_TEXT"; echo "XXX"
            eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
            sleep 0.5
        done
        
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Debian/Ubuntu" --gauge "Iniciando..." 12 80 0
}

run_install_fedora_family() {
    PACKAGES=("git" "dkms" "kernel-devel-$(uname -r)" "python3-dialog" "Development Tools")
    CMD_UPDATE="echo 'DNF nao precisa de update separado.'"
    CMD_INSTALL="dnf install -y"
    CMD_GROUP_INSTALL="dnf groupinstall -y"
    TOTAL_STEPS=$((${#PACKAGES[@]} + 1))
    CURRENT_STEP=0
    (
        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo $PERCENTAGE; echo "XXX"; echo "Etapa 1 de 2: Verificando DNF..."; echo "XXX"
        eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        
        for pkg in "${PACKAGES[@]}"; do
            ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); PKG_NUM=$((CURRENT_STEP - 1))
            PROGRESS_TEXT="Etapa 2 de 2: Instalando $pkg ($PKG_NUM de ${#PACKAGES[@]})"
            echo $PERCENTAGE; echo "XXX"; echo "$PROGRESS_TEXT"; echo "XXX"
            if [[ "$pkg" == "Development Tools" ]]; then
                eval "$CMD_GROUP_INSTALL \"$pkg\"" >> "$LOG_FILE" 2>&1
            else
                eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            fi
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
            sleep 0.5
        done
        
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Fedora/RHEL" --gauge "Iniciando..." 12 80 0
}

run_install_arch_family() {
    OFFICIAL_PACKAGES=("reflector" "git" "dkms" "base-devel" "linux-headers" "dialog")
    AUR_PACKAGES=("python-pythondialog")
    TOTAL_STEPS=$((${#OFFICIAL_PACKAGES[@]} + 3)) # Pacotes + Reflector + Sync + AUR
    CURRENT_STEP=0

    (
        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo $PERCENTAGE; echo "XXX"; echo "Etapa 1: Instalando otimizador de servidores (reflector)..."; echo "XXX"
        pacman -S --noconfirm --needed reflector > "$LOG_FILE" 2>&1
        sleep 1

        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo $PERCENTAGE; echo "XXX"; echo "Etapa 2: Procurando servidores mais rapidos..."; echo "XXX"
        reflector --country Brazil,Chile,Argentina --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist >> "$LOG_FILE" 2>&1
        pacman -Syyu --noconfirm > "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        sleep 1

        for pkg in "${OFFICIAL_PACKAGES[@]}"; do
            if [[ "$pkg" == "reflector" ]]; then continue; fi
            ((CURRENT_STEP++)); PKG_NUM=$((CURRENT_STEP - 2))
            PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
            PROGRESS_TEXT="Etapa 3: Instalando pacotes (${PKG_NUM} de $((${#OFFICIAL_PACKAGES[@]} - 1))): $pkg"
            echo $PERCENTAGE; echo "XXX"; echo "$PROGRESS_TEXT"; echo "XXX"
            pacman -S --noconfirm --needed "$pkg" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
            sleep 0.5
        done

        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo $PERCENTAGE; echo "XXX"; echo "Etapa 4: Verificando pacotes do AUR..."; echo "XXX"
        if command -v yay &> /dev/null; then
            sudo -u $SUDO_USER yay -S --noconfirm "${AUR_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
        else
            YAY_MISSING=true
        fi
        sleep 1
        
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Arch Linux" --gauge "Iniciando..." 12 80 0

    if [ "$YAY_MISSING" = true ]; then
        declare -g YAY_MISSING_GLOBAL=true
    fi
}

# --- Lógica Principal ---
main() {
    install_dialog_if_missing

    WELCOME_TEXT="Bem-vindo ao instalador de dependencias do MEI Git!\n\nEste script ira preparar seu sistema para compilar e instalar drivers."
    show_message "$WELCOME_TEXT"

    CONFIRM_TEXT="O script ira detectar sua distribuicao e instalar os pacotes necessarios.\n\nDeseja continuar?"
    if ! ask_yes_no "$CONFIRM_TEXT"; then
        show_message "Instalacao cancelada pelo usuario."; exit 0; fi

    if [ -f /etc/os-release ]; then . /etc/os-release; OS=$ID_LIKE; OS_NAME=$ID; else
        show_message "❌ Nao foi possivel detectar a distribuicao."; exit 1; fi
    
    if [ -z "$OS" ]; then
        OS=$OS_NAME
    fi

    case "$OS" in
        "debian" | "ubuntu" | "deepin" | "pop" | "mx")
            run_install_debian_family
            ;;
        "fedora" | "rhel" | "centos")
            run_install_fedora_family
            ;;
        "arch" | "endeavouros" | "manjaro")
            run_install_arch_family
            ;;
        *)
            show_message "❌ Distribuicao da familia '$OS' nao suportada."; exit 1 ;;
    esac
    
    FINAL_STATUS=$(cat /tmp/mei-git-status.txt 2>/dev/null); rm /tmp/mei-git-status.txt 2>/dev/null
    if [ "$FINAL_STATUS" != "0" ]; then
        show_message "❌ Falha na instalacao. Verifique o log em $LOG_FILE."; exit 1; fi
    
    clear
    echo "=================================================================="
    echo "✅ Setup concluído com sucesso!"
    echo ""
    
    if [ "$YAY_MISSING_GLOBAL" = true ]; then
        echo -e "\033[1;33mATENÇÃO:\033[0m A dependência 'python-pythondialog' do AUR não foi instalada."
        echo "Você não parece ter um ajudante AUR como o 'yay'."
        echo "Por favor, instale-o manualmente para usar a interface gráfica do mei-git."
        echo ""
    fi
    
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git\" /usr/local/bin/mei-git"
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""; echo -e "\033[1;32msudo $FINAL_CMD\033[0m"; echo ""
    echo "=================================================================="
}

main