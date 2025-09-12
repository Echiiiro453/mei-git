#!/bin/bash

# setup.sh - v5.4 - Instalador profissional com barra de progresso

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# Força o locale para UTF-8 para máxima compatibilidade
export LANG=C.UTF-8

# --- Variáveis Globais ---
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE" # Limpa o log antigo

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

# --- Lógica Principal ---
main() {
    install_dialog_if_missing

    WELCOME_TEXT="Bem-vindo ao instalador de dependencias do MEI Git!\n\nEste script ira preparar seu sistema para compilar e instalar drivers."
    show_message "$WELCOME_TEXT"

    CONFIRM_TEXT="O script ira detectar sua distribuicao e instalar os pacotes necessarios (como git, dkms, etc).\n\nDeseja continuar?"
    if ! ask_yes_no "$CONFIRM_TEXT"; then
        show_message "Instalacao cancelada pelo usuario."
        exit 0
    fi

    # Detecção de Distro
    if [ -f /etc/os-release ]; then . /etc/os-release; OS=$ID; else
        show_message "?? Nao foi possivel detectar a distribuicao."; exit 1; fi

    # Lógica de Instalação Multi-distro
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            CMD_UPDATE="apt-get update"
            CMD_INSTALL="apt-get install -y $PACKAGES"
            ;;
        "fedora" | "rhel" | "centos")
            PACKAGES="git dkms kernel-devel"
            CMD_UPDATE="echo 'DNF nao precisa de update separado.'" # DNF faz isso junto com o install
            CMD_INSTALL="dnf install -y $PACKAGES && dnf groupinstall -y 'Development Tools'"
            ;;
        "arch" | "endeavouros" | "manjaro")
            PACKAGES="git dkms base-devel linux-headers"
            CMD_UPDATE="echo 'Pacman atualiza durante a instalacao.'"
            CMD_INSTALL="pacman -Syu --noconfirm $PACKAGES"
            ;;
        *)
            show_message "?? Distribuicao '$OS' nao suportada."; exit 1 ;;
    esac

    # --- NOVO BLOCO DE INSTALAÇÃO COM BARRA DE PROGRESSO ---
    (
        # Etapa 1: Update (25%)
        echo 25
        echo "XXX"
        echo "Atualizando lista de pacotes..."
        echo "XXX"
        eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        
        # Etapa 2: Install (75%)
        echo 75
        echo "XXX"
        echo "Instalando dependencias: $PACKAGES"
        echo "XXX"
        eval $CMD_INSTALL >> "$LOG_FILE" 2>&1
        INSTALL_STATUS=$?
        
        # Etapa 3: Finish (100%)
        echo 100
        echo "XXX"
        echo "Finalizando..."
        echo "XXX"
        sleep 1
        
        # Salva o status final da instalação
        echo $INSTALL_STATUS > /tmp/mei-git-status.txt

    ) | dialog --title "Progresso da Instalação" --gauge "Iniciando..." 10 75 0

    FINAL_STATUS=$(cat /tmp/mei-git-status.txt)
    rm /tmp/mei-git-status.txt

    if [ $FINAL_STATUS -ne 0 ]; then
        show_message "?? Falha na instalacao das dependencias. Verifique o log em $LOG_FILE para mais detalhes."
        exit 1
    fi

    # Mensagem final de sucesso
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git\" /usr/local/bin/mei-git"
    show_message "?? Dependencias instaladas com sucesso!\\n\\nO MEI Git está pronto."
    
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

# Executa a função principal
main