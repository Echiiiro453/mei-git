#!/bin/bash

# setup.sh - v6.4 - Usa programbox para sync e gauge para install no Arch

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

export LANG=C.UTF-8
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE"

# --- Funções de Interface ---
install_dialog_if_missing() { # ... (código omitido, continua o mesmo)
}
show_message() { # ... (código omitido, continua o mesmo)
}
ask_yes_no() { # ... (código omitido, continua o mesmo)
}

# --- NOVA E MELHORADA FUNÇÃO DE INSTALAÇÃO PARA ARCH ---
run_install_arch_family() {
    # Lista de pacotes
    OFFICIAL_PACKAGES=("git" "dkms" "base-devel" "linux-headers" "dialog")
    AUR_PACKAGES=("python-pythondialog")
    
    # --- ETAPA 1: SINCRONIZAÇÃO E ATUALIZAÇÃO DO SISTEMA ---
    SYNC_COMMAND="pacman -Syyu --noconfirm"
    show_message "A primeira etapa e sincronizar e atualizar o sistema com o Pacman. Isso pode levar alguns minutos."
    
    if command -v dialog &> /dev/null; then
        dialog --title "Etapa 1: Sincronizando Pacotes (pacman -Syyu)" --programbox "$SYNC_COMMAND" 25 90
    else
        eval $SYNC_COMMAND
    fi

    if [ $? -ne 0 ]; then
        show_message "❌ Falha ao sincronizar os pacotes com o pacman. Verifique sua conexao ou os erros no terminal."
        exit 1
    fi

    # --- ETAPA 2: INSTALAÇÃO DAS DEPENDÊNCIAS ---
    TOTAL_PACKAGES=${#OFFICIAL_PACKAGES[@]}
    INSTALLED_COUNT=0
    (
        for pkg in "${OFFICIAL_PACKAGES[@]}"; do
            ((INSTALLED_COUNT++)); PERCENTAGE=$((INSTALLED_COUNT * 100 / TOTAL_PACKAGES))
            PROGRESS_TEXT="Etapa 2: Instalando dependencias - $pkg ($INSTALLED_COUNT de $TOTAL_PACKAGES)"
            echo $PERCENTAGE; echo "XXX"; echo "$PROGRESS_TEXT"; echo "XXX"
            
            pacman -S --noconfirm --needed "$pkg" > /dev/null 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        done
        sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando Dependencias Oficiais" --gauge "Iniciando..." 10 75 0

    FINAL_STATUS=$(cat /tmp/mei-git-status.txt 2>/dev/null); rm /tmp/mei-git-status.txt 2>/dev/null
    if [ "$FINAL_STATUS" != "0" ]; then
        show_message "❌ Falha na instalacao de um dos pacotes oficiais."; exit 1; fi

    # --- ETAPA 3: INSTALAÇÃO DO AUR ---
    if command -v yay &> /dev/null; then
        if ask_yes_no "Dependencia '${AUR_PACKAGES[0]}' do AUR encontrada. Deseja instalar com 'yay'?"; then
            sudo -u $SUDO_USER yay -S --noconfirm "${AUR_PACKAGES[@]}"
        fi
    else
        # Define a variável global para ser usada na mensagem final
        declare -g YAY_MISSING_GLOBAL=true
    fi
}

# --- Lógica Principal ---
main() {
    install_dialog_if_missing
    show_message "Bem-vindo ao instalador de dependencias do MEI Git!"
    if ! ask_yes_no "Deseja continuar com a instalacao das dependencias?"; then
        show_message "Instalacao cancelada."; exit 0; fi

    if [ -f /etc/os-release ]; then . /etc/os-release; OS=$ID; else
        show_message "❌ Nao foi possivel detectar a distribuicao."; exit 1; fi

    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            # A lógica para Debian-based...
            ;;
        "fedora" | "rhel" | "centos")
            # A lógica para Fedora-based...
            ;;
        "arch" | "endeavouros" | "manjaro")
            run_install_arch_family # Chama a nova função super robusta para Arch
            ;;
        *)
            show_message "❌ Distribuicao '$OS' nao suportada."; exit 1 ;;
    esac
    
    # Mensagem Final
    clear
    echo "=================================================================="
    echo "✅ Setup concluído!"
    echo ""
    if [ "$YAY_MISSING_GLOBAL" = true ]; then
        echo -e "\033[1;33mATENÇÃO:\033[0m A dependencia 'python-pythondialog' do AUR nao foi instalada."
        echo "Para usar a interface grafica do mei-git, instale-a manualmente."
        echo ""
    fi
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git\" /usr/local/bin/mei-git"
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""; echo -e "\033[1;32msudo $FINAL_CMD\033[0m"; echo ""
    echo "=================================================================="
}

main