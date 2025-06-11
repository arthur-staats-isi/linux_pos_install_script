# Script de pós-instalação para Linux baseado no Ubuntu 22.04

Este script automatiza a instalação de dependências no Ubuntu 22.04 ou distribuições derivadas.

## ✅ Funcionalidades

- Atualização do sistema
- Instalação das dependências desejadas:
  - Instalação de [apt-fast](https://github.com/ilikenwf/apt-fast)
  - Instalação de Zsh + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) + plugin [autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) + plugin [syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
  - Instalação de [HTOP](https://github.com/htop-dev/htop)
  - Instalação do Google Chrome
  - Instalação do VS Code
  - Instalação da extensão [ESP-IDF no VS Code](https://github.com/espressif/vscode-esp-idf-extension)
  - Instalação do [KiCad 9.x.x](https://www.kicad.org/)
  - Instalação do [ROS2 Humble](https://docs.ros.org/en/humble/index.html)
  - Instalação do Docker + Docker Compose

## 🖥️ Pré-requisitos

- Conexão com a internet
- Acesso root (`sudo`)
- Zenity
  - Instalação: `sudo apt install zenity`

## ⚙️ Instruções

1. Clone o repositório:

```bash
git clone https://github.com/arthur-staats-isi/linux_pos_install_script.git
```

2. Entre na pasta do script:

```bash
cd linux_pos_install_script
```

3. Altere as permissões do script:

```bash
chmod +x linux_pos_install_script.sh
```

4. Execute o script:

```bash
./linux_pos_install_script.sh
```
