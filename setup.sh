#!/bin/bash

# setup.sh - v6.2 - Barra de progresso com feedback de instalação pacote a pacote

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
            PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)" "python3-dialog")
            CMD_UPDATE="apt-get update"
            CMD_INSTALL="apt-get install -y"
            ;;
        "fedora" | "rhel" | "centos")
            PACKAGES=("git" "dkms" "kernel-devel-$(uname -r)" "python3-dialog" "Development Tools")
            CMD_UPDATE="echo 'DNF nao precisa de update separado.'"
            CMD_INSTALL="dnf install -y"
            CMD_GROUP_INSTALL="dnf groupinstall -y"
            ;;
        "arch" | "endeavouros" | "manjaro")
            PACKAGES=("git" "dkms" "base-devel" "linux-headers" "python-pythondialog")
            CMD_UPDATE="echo 'Pacman atualiza durante a instalacao.'"
            CMD_INSTALL="pacman -S --noconfirm"
            ;;
        *)
            show_message "❌ Distribuicao da familia '$OS' nao suportada."; exit 1 ;;
    esac

    # Bloco de instalação com barra de progresso
    TOTAL_STEPS=$((${#PACKAGES[@]} + 1))
    CURRENT_STEP=0
    (
        ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo $PERCENTAGE
        echo "XXX"
        echo "Etapa 1 de 2: Atualizando lista de pacotes..." # Mensagem para a primeira etapa
        echo "XXX"
        eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        
        for pkg in "${PACKAGES[@]}"; do
            ((CURRENT_STEP++)); PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS)); PKG_NUM=$((CURRENT_STEP - 1))
            
            # --- CORREÇÃO APLICADA AQUI ---
            # Combina a informação em uma única linha para a barra de progresso
            PROGRESS_TEXT="Etapa 2 de 2: Instalando $pkg ($PKG_NUM de ${#PACKAGES[@]})"
            
            echo $PERCENTAGE
            echo "XXX"
            echo "$PROGRESS_TEXT" # Envia a mensagem corrigida
            echo "XXX"

            if [[ "$pkg" == "Development Tools" && -n "$CMD_GROUP_INSTALL" ]]; then
                eval "$CMD_GROUP_INSTALL \"$pkg\"" >> "$LOG_FILE" 2>&1
            else
                eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            fi
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
            sleep 0.5
        done
        
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando Dependencias para '$OS_NAME'" --gauge "Iniciando..." 10 75 0

    FINAL_STATUS=$(cat /tmp/mei-git-status.txt); rm /tmp/mei-git-status.txt
    if [ $FINAL_STATUS -ne 0 ]; then
        show_message "❌ Falha na instalacao. Verifique o log em $LOG_FILE."; exit 1; fi

    FINAL_CMD="ln -sf \"\$(pwd)/mei-git\" /usr/local/bin/mei-git"
    show_message "✅ Dependencias instaladas com sucesso!"
    
    clear
    echo "=================================================================="
    echo "✅ Setup concluido com sucesso!"
    echo ""
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""; echo -e "\033[1;32msudo $FINAL_CMD\033[0m"; echo ""
    echo "=================================================================="
}

main