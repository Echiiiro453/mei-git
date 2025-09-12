#!/bin/bash

# setup.sh - v5.1 - Instalador profissional com progresso em tempo real

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# Força o locale para UTF-8 para máxima compatibilidade com caracteres
export LANG=C.UTF-8

# --- Verificação e Instalação do 'dialog' ---
# A função agora é mais silenciosa e só mostra algo se precisar instalar
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' nao encontrado. Instalando..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &> /dev/null; then
            dnf install -y dialog
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm dialog
        elif command -v zypper &> /dev/null; then
            zypper --non-interactive install dialog
        fi

        if ! command -v dialog &> /dev/null; then
             echo "???? Falha ao instalar o 'dialog'. O script continuara em modo texto simples."
        fi
    fi
}

# --- Funções de Interface ---
show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 10 70
    else
        echo -e "\n$1\n"
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmacao" --cr-wrap --yesno "$1" 10 70
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

    show_message "Bem-vindo ao instalador de dependencias do MEI Git!\\n\\nEste script ira preparar seu sistema para compilar e instalar drivers."

    if ! ask_yes_no "O script ira detectar sua distribuicao e instalar os pacotes necessarios (como git, dkms, etc.).\\n\\nDeseja continuar?"; then
        show_message "Instalacao cancelada pelo usuario."
        exit 0
    fi

    # Detecção de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? Nao foi possivel detectar a distribuicao."
        exit 1
    fi

    # Lógica de Instalação Multi-distro
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            # Comando sem 'sudo' porque o script já está rodando como root
            COMMAND="apt-get update && apt-get install -y $PACKAGES"
            ;;
        "fedora" | "rhel" | "centos")
            PACKAGES="git dkms kernel-devel"
            COMMAND="dnf install -y $PACKAGES && dnf groupinstall -y 'Development Tools'"
            ;;
        "arch" | "endeavouros" | "manjaro")
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="pacman -Syu --noconfirm $PACKAGES"
            ;;
        "opensuse-tumbleweed" | "opensuse-leap")
            PACKAGES="git dkms patterns-devel-base-devel_basis kernel-default-devel"
            COMMAND="zypper install -y $PACKAGES"
            ;;
        *)
            show_message "?? Distribuicao '$OS' nao suportada.\\n\\nInstale manualmente os pacotes: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    # --- A MÁGICA ACONTECE AQUI ---
    # Usa --programbox para mostrar a saída do comando em tempo real
    if command -v dialog &> /dev/null; then
        dialog --title "Instalando Dependencias para '$OS'..." --programbox "$COMMAND" 25 90
    else
        echo "???? Executando comando de instalacao..."
        # Executa o comando diretamente se o dialog não estiver disponível
        eval $COMMAND
    fi
    
    INSTALL_STATUS=$?

    if [ $INSTALL_STATUS -ne 0 ]; then
        show_message "?? Falha na instalacao das dependencias. Verifique os erros na janela anterior."
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
    echo -e "\033[1;32msudo $FINAL_CMD\033[0m" # Imprime o comando em verde
    echo ""
    echo "=================================================================="
}

# Executa a função principal
main