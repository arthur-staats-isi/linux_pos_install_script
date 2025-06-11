#!/bin/bash

## ---------------------------------------------------------------------------------------
## ------------------	Script pós instalação do linux (base Ubuntu) 	------------------
## ------------------	Data: 10/06/2025				------------------
## ------------------	Autor: Arthur Staats				------------------
## ------------------	Versão: 1.0					------------------
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

# Atualizações básicas
sudo apt update && sudo apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Verifica qual comando de pacote será usado
PACKAGE_MANAGER="apt"

zenity --info --title="Instalador de pacotes" --text="Instalação interativa de ferramentas e utilitários.\nClique em OK para começar."

# APT-FAST
if ask_install "Instalar o apt-fast (acelera atualizações)?"; then
    sudo add-apt-repository -y ppa:apt-fast/stable
    sudo apt update
    sudo apt install -y apt-fast
    PACKAGE_MANAGER="apt-fast"
fi

# UPDATE & UPGRADE
if ask_install "Deseja atualizar todos os pacotes do sistema (recomendado)?"; then
    if [[ "$PACKAGE_MANAGER" == "apt-fast" ]]; then
        sudo apt-fast update && sudo apt-fast upgrade -y
    else
        sudo apt update && sudo apt upgrade -y
    fi
fi

# Zsh + Oh My Zsh + plugins
ZSH_INSTALLED=false
if ask_install "Instalar Zsh + Oh My Zsh + plugins (git, autosuggestions, syntax-highlighting)?"; then
    sudo $PACKAGE_MANAGER install -y zsh
    ZSH_INSTALLED=true
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    sed -i 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
fi

# Tornar Zsh padrão, se instalado
if [[ "$ZSH_INSTALLED" = true ]]; then
    if ask_install "Deseja tornar o Zsh o terminal padrão?"; then
        chsh -s "$(which zsh)"
    fi
fi

# Htop
if ask_install "Instalar o htop?"; then
    sudo $PACKAGE_MANAGER install -y htop
fi

# GOOGLE CHROME
if ask_install "Instalar o Google Chrome?"; then
    wget -q -O google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo $PACKAGE_MANAGER install -y ./google-chrome.deb
    rm google-chrome.deb
fi

# VS CODE
if ask_install "Instalar o Visual Studio Code?"; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm microsoft.gpg
    sudo $PACKAGE_MANAGER update
    sudo $PACKAGE_MANAGER install -y code
fi

#if ask_install "Instalar o ESP-IDF?"; then
#    mkdir -p ~/esp
#    cd ~/esp
#
#    if [ -d esp-idf ]; then
#        cd esp-idf
#        git pull
#    else
#        git clone --recursive https://github.com/espressif/esp-idf.git
#        cd esp-idf
#    fi
#
#    # Pergunta qual versão instalar (branch ou tag)
#    ESP_IDF_VERSION=$(zenity --entry --title="Versão do ESP-IDF" --text="Digite a versão (tag/branch) do ESP-IDF para instalar:" --entry-text="release/v5.0")
#
#    if [ -n "$ESP_IDF_VERSION" ]; then
#        git checkout "$ESP_IDF_VERSION"
#        git submodule update --init --recursive
#    fi
#
#    ./install.sh
#
#    # Evitar duplicar linha no .bashrc
#    if ask_install "Incluir ESP-IDF no .bashrc?"; then
#        grep -qxF 'source ~/esp/esp-idf/export.sh' ~/.bashrc || echo 'source ~/esp/esp-idf/export.sh' >> ~/.bashrc
#    fi
#
#    if [[ "$ZSH_INSTALLED" = true ]]; then
#        if ask_install "Incluir ESP-IDF no .zshrc?"; then
#            grep -qxF 'source ~/esp/esp-idf/export.sh' ~/.zshrc || echo 'source ~/esp/esp-idf/export.sh' >> ~/.zshrc
#        fi
#    fi
#fi


# Extensão VS Code
if ask_install "Instalar a extensão ESP-IDF no VS Code?"; then
    code --install-extension espressif.esp-idf-extension
fi

# KICAD
if ask_install "Instalar o KiCad 9?"; then
    sudo add-apt-repository -y ppa:kicad/kicad-9.0-releases
    sudo $PACKAGE_MANAGER update
    sudo $PACKAGE_MANAGER install -y kicad
fi

# ROS 2 Humble
if ask_install "Instalar o ROS 2 Humble?"; then
    sudo $PACKAGE_MANAGER install -y software-properties-common
    sudo add-apt-repository universe
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    sudo $PACKAGE_MANAGER update
    sudo $PACKAGE_MANAGER install -y ros-humble-desktop
#    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
    sudo $PACKAGE_MANAGER install -y python3-colcon-common-extensions python3-rosdep
    sudo rosdep init || true
    rosdep update
fi

# Docker
if ask_install "Instalar Docker + Docker Compose?"; then
    sudo $PACKAGE_MANAGER remove -y docker docker-engine docker.io containerd runc || true
    sudo $PACKAGE_MANAGER install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo $PACKAGE_MANAGER update
    sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
fi

# Pyenv
if ask_install "Instalar Python com pyenv?"; then
    sudo $PACKAGE_MANAGER install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
        curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    curl https://pyenv.run | bash
#    echo -e '\n# Pyenv' >> ~/.bashrc
#    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
#    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
#    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
#    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
fi

zenity --info --title="Concluído" --text="✅ Instalação finalizada!\nReinicie o terminal ou a sessão para aplicar todas as mudanças."
