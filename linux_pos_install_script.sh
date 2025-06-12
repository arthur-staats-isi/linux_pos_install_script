#!/bin/bash

## ---------------------------------------------------------------------------------------
## ------------------	Script pós instalação do linux (base Ubuntu) 	------------------
## ------------------	Data: 11/06/2025		                        ------------------
## ------------------	Autor: Arthur Staats				            ------------------
## ------------------	Versão: 1.1					                    ------------------
## ---------------------------------------------------------------------------------------

set -e

# Verifica se o zenity está instalado
if ! command -v zenity &> /dev/null; then
    echo "Zenity não encontrado. Instale com: sudo apt install zenity"
    exit 1
fi

# Função de confirmação
function ask_install() {
    zenity --question --title="Instalação de Pacotes" --text="$1" --ok-label="Sim" --cancel-label="Não"
    return $?
}

# Atualizações básicas e instalação de dependências
sudo apt update | zenity --progress --pulsate --no-cancel --auto-close --title="Dependências" --text="Update de repositórios..." --width=400
sudo apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release | zenity --progress --pulsate --no-cancel --auto-close --title="Dependências" --text="Instalando dependências..." --width=400

# Verifica qual comando de pacote será usado
PACKAGE_MANAGER="apt"

# Primeira notificação para o usuário
zenity --info --title="Instalador de pacotes" --text="Instalação interativa de ferramentas e utilitários.\nClique em OK para começar."

# APT-FAST
if ask_install "Instalar o apt-fast (acelera atualizações)?"; then
    sudo add-apt-repository -y ppa:apt-fast/stable | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Adicionando repositório do apt-fast..." --width=400
    sudo apt update | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Update de repositórios..." --width=400
    sudo apt install -y apt-fast
    PACKAGE_MANAGER="apt-fast"
fi

# UPDATE & UPGRADE
if ask_install "Deseja atualizar todos os pacotes do sistema (recomendado)?"; then
    if [[ "$PACKAGE_MANAGER" == "apt-fast" ]]; then
        sudo apt-fast update
        sudo apt-fast upgrade -y
    else
        sudo apt update
        sudo apt upgrade -y
    fi
fi

# Zsh + Oh My Zsh + plugins
if ask_install "Instalar Zsh + Oh My Zsh + plugins (git, autosuggestions, syntax-highlighting)?"; then
    sudo $PACKAGE_MANAGER install -y zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    sed -i 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
fi

# Verifica se ZSH está instalado
ZSH_INSTALLED=false
if command -v zsh >/dev/null 2>&1; then
    ZSH_INSTALLED=true
fi

# Tornar Zsh padrão, se instalado
if [[ "$ZSH_INSTALLED" = true ]]; then
    if ask_install "Deseja tornar o Zsh o terminal padrão?"; then
        chsh -s "$(which zsh)"
        zenity --info --title="Instalador de pacotes" --text="Zsh foi configurado como padrão.\nClique em OK para continuar."
    fi
fi

# ESP-IDF
if ask_install "Instalar o ESP-IDF?"; then
    TEMP_DIR=$(mktemp -d)

    # Clona apenas os metadados (sem recursão)
    git clone --quiet --filter=blob:none --bare https://github.com/espressif/esp-idf.git "$TEMP_DIR/esp-idf" | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Buscando versões disponíveis do ESP-IDF..." --width=400

    # Coleta e ordena as tags (versões)
    TAGS=$(git --git-dir="$TEMP_DIR/esp-idf" tag -l 'v*' | sort -Vr)

    if [ -z "$TAGS" ]; then
        zenity --error --text="Não foi possível obter as versões do ESP-IDF."
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Gera lista formatada para o Zenity (uma versão por linha)
    SELECTED_TAG=$(echo "$TAGS" | zenity --list \
        --title="Escolha a versão do ESP-IDF" \
        --text="Selecione uma versão para instalar:" \
        --column="Versões" \
        --height=500 \
        --width=300)

    rm -rf "$TEMP_DIR"

    if [ -z "$SELECTED_TAG" ]; then
        zenity --warning --text="Instalação do ESP-IDF cancelada pelo usuário."
        exit 1
    fi

    # Remove o 'v' e monta diretório padrão
    CLEAN_VERSION="${SELECTED_TAG#v}"
    ESP_IDF_BASE="$HOME/esp/v$CLEAN_VERSION"
    ESP_IDF_PATH="$ESP_IDF_BASE/esp-idf"

    ESP_IDF_BASE="$HOME/esp/v$CLEAN_VERSION"
    ESP_IDF_PATH="$ESP_IDF_BASE/esp-idf"

    if [ -d "$ESP_IDF_PATH" ]; then
        zenity --question --title="ESP-IDF já existe" --text="A versão $SELECTED_TAG já está instalada em:\n$ESP_IDF_PATH\n\nDeseja sobrescrever?"

        if [ $? -eq 0 ]; then
            rm -rf "$ESP_IDF_PATH"
        else
            zenity --info --text="Instalação do ESP-IDF v$CLEAN_VERSION cancelada."
            exit 0
        fi
    fi

    mkdir -p "$ESP_IDF_BASE"
    cd "$ESP_IDF_BASE"

    git clone --recursive --branch "$SELECTED_TAG" https://github.com/espressif/esp-idf.git | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Clonando repositório do ESP-IDF..." --width=400

    cd esp-idf
    ./install.sh | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando ESP-IDF..." --width=400    

    if ask_install "Incluir ESP-IDF no .bashrc?"; then
        grep -qxF "source $ESP_IDF_PATH/export.sh" ~/.bashrc || echo "source $ESP_IDF_PATH/export.sh" >> ~/.bashrc
    fi

    if [[ "$ZSH_INSTALLED" = true ]]; then
        if ask_install "Incluir ESP-IDF no .zshrc?"; then
            grep -qxF "source $ESP_IDF_PATH/export.sh" ~/.zshrc || echo "source $ESP_IDF_PATH/export.sh" >> ~/.zshrc
        fi
    fi
    zenity --info --title="Instalador de pacotes" --text="Instalação do ESP-IDF $SELECTED_TAG finalizada em: $ESP_IDF_PATH\nClique em OK para continuar."
fi

# Htop
if ask_install "Instalar o htop?"; then
    sudo $PACKAGE_MANAGER install -y htop | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando htop..." --width=400
    zenity --info --title="Instalador de pacotes" --text="Instalação do htop finalizada.\nClique em OK para continuar."
fi

# GOOGLE CHROME
if ask_install "Instalar o Google Chrome?"; then
    wget -q -O google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Download do Google Chrome..." --width=400
    sudo $PACKAGE_MANAGER install -y ./google-chrome.deb | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando o Google Chrome..." --width=400
    rm google-chrome.deb
    zenity --info --title="Instalador de pacotes" --text="Instalação do Google Chrome finalizada.\nClique em OK para continuar."
fi

# VS CODE
if ask_install "Instalar o Visual Studio Code?"; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Obtendo pacote do VS Code..." --width=400
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Obtendo pacote do VS Code..." --width=400
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Inserindo VS Code na lista de pacotes..." --width=400
    rm microsoft.gpg
    sudo $PACKAGE_MANAGER update | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Update de repositórios..." --width=400
    sudo $PACKAGE_MANAGER install -y code | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando o VS Code..." --width=400
    zenity --info --title="Instalador de pacotes" --text="Instalação do VS Code finalizada.\nClique em OK para continuar."
fi

# Extensão ESP-IDF para VS Code
if ask_install "Instalar a extensão ESP-IDF no VS Code?"; then
    code --install-extension espressif.esp-idf-extension | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando extensão do ESP-IDF para VS Code..." --width=400
    zenity --info --title="Instalador de pacotes" --text="Instalação da extensão do ESP-IDF para VS Code finalizada.\nClique em OK para continuar."
fi

# KICAD
if ask_install "Instalar o KiCad 9?"; then
    sudo add-apt-repository -y ppa:kicad/kicad-9.0-releases | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Adicionando repositório do KiCad 9.X.X..." --width=400
    sudo $PACKAGE_MANAGER update | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Update de repositórios..." --width=400
    sudo $PACKAGE_MANAGER install -y kicad | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando o KiCad 9.X.X..." --width=400
    zenity --info --title="Instalador de pacotes" --text="Instalação do KiCad 9 finalizada.\nClique em OK para continuar."
fi

# ROS 2 Humble
#if ask_install "Instalar o ROS 2 Humble?"; then
#    sudo $PACKAGE_MANAGER install -y software-properties-common | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando dependências para o ROS2..." --width=400
#    sudo add-apt-repository universe | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Adicionando repositório universe para ROS2..." --width=400
#    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Adicionando repositório universe para ROS2..." --width=400
#    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
#    sudo $PACKAGE_MANAGER update
#    sudo $PACKAGE_MANAGER install -y ros-humble-desktop
#    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
#    sudo $PACKAGE_MANAGER install -y python3-colcon-common-extensions python3-rosdep
#    sudo rosdep init || true
#    rosdep update
#fi

# Docker
if ask_install "Instalar Docker + Docker Compose?"; then
    sudo $PACKAGE_MANAGER remove -y docker docker-engine docker.io containerd runc || true 
    sudo $PACKAGE_MANAGER install -y ca-certificates curl gnupg | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando dependências para Docker..." --width=400
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Obtendo pacote do Docker..." --width=400
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo $PACKAGE_MANAGER update | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Update de repositórios..." --width=400
    sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | zenity --progress --pulsate --no-cancel --auto-close --title="Instalador de pacotes" --text="Instalando Docker..." --width=400
    sudo usermod -aG docker "$USER"
    zenity --info --title="Instalador de pacotes" --text="Instalação do Docker finalizada.\nClique em OK para continuar."
fi

zenity --info --title="Concluído" --text="✅ Instalação finalizada!\nReinicie o terminal ou a sessão para aplicar todas as mudanças."
