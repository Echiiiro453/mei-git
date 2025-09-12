#!/bin/bash

# setup.sh - v5.5 - Instalador profissional com progresso pacote a pacote

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
# (As funções 'install_dialog_if_missing', 'show_message' e 'ask_yes_no' continuam as mesmas)
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

    # Define pacotes e comandos baseados na distro
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)")
            CMD_UPDATE="apt-get update"
            CMD_INSTALL="apt-get install -y"
            ;;
        "fedora" | "rhel" | "centos")
            PACKAGES=("git" "dkms" "kernel-devel" "Development Tools") # Development Tools é um grupo
            CMD_UPDATE="echo 'DNF nao precisa de update separado.'"
            CMD_INSTALL="dnf install -y"
            CMD_GROUP_INSTALL="dnf groupinstall -y"
            ;;
        "arch" | "endeavouros" | "manjaro")
            PACKAGES=("git" "dkms" "base-devel" "linux-headers")
            CMD_UPDATE="echo 'Pacman atualiza durante a instalacao.'"
            CMD_INSTALL="pacman -S --noconfirm"
            ;;
        *)
            show_message "?? Distribuicao '$OS' nao suportada."; exit 1 ;;
    esac

    # --- NOVO BLOCO DE INSTALAÇÃO DETALHADA ---
    
    # Prepara a instalação
    TOTAL_PACKAGES=${#PACKAGES[@]}
    INSTALLED_COUNT=0
    
    # Bloco de comandos que será enviado para a barra de progresso
    (
        # Etapa de Update (se aplicável)
        echo 10
        echo "XXX"
        echo "Atualizando lista de pacotes..."
        echo "XXX"
        eval $CMD_UPDATE > "$LOG_FILE" 2>&1
        
        # Loop para instalar cada pacote individualmente
        for pkg in "${PACKAGES[@]}"; do
            ((INSTALLED_COUNT++))
            PERCENTAGE=$((INSTALLED_COUNT * 80 / TOTAL_PACKAGES + 10)) # Calcula a porcentagem (de 10 a 90)
            
            echo $PERCENTAGE
            echo "XXX"
            echo "Instalando: $pkg ($INSTALLED_COUNT de $TOTAL_PACKAGES)..."
            echo "XXX"

            # Lógica especial para grupos de pacotes (como no Fedora)
            if [[ "$pkg" == "Development Tools" && -n "$CMD_GROUP_INSTALL" ]]; then
                eval "$CMD_GROUP_INSTALL \"$pkg\"" >> "$LOG_FILE" 2>&1
            else
                eval "$CMD_INSTALL $pkg" >> "$LOG_FILE" 2>&1
            fi

            # Se um pacote falhar, para o script
            if [ $? -ne 0 ]; then
                echo 1 > /tmp/mei-git-status.txt # Sinaliza erro
                exit
            fi
        done
        
        # Etapa final
        echo 100
        echo "XXX"
        echo "Finalizando..."
        echo "XXX"
        sleep 1
        echo 0 > /tmp/mei-git-status.txt # Sinaliza sucesso

    ) | dialog --title "Instalando Dependencias para '$OS'" --gauge "Iniciando..." 10 75 0

    FINAL_STATUS=$(cat /tmp/mei-git-status.txt)
    rm /tmp/mei-git-status.txt

    if [ $FINAL_STATUS -ne 0 ]; then
        show_message "?? Falha na instalacao de um dos pacotes. Verifique o log em $LOG_FILE para mais detalhes."
        exit 1
    fi

    # Mensagem final de sucesso
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git.py\" /usr/local/bin/mei-git"
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

# Executa a função principal
main