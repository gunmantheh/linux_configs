#!/usr/bin/env bash
echo "=== System Install Starting! ==="


# Variables
DL_DIR="$HOME/Downloads/EnvSetup" && mkdir -p "$DL_DIR"
BIN_DIR="$HOME/bin" && mkdir -p "$BIN_DIR"

source /etc/os-release #loads $UBUNTU_CODENAME
export DEBIAN_FRONTEND=noninteractive

# phpVer=7.3
# vboxVer=6.1
# mysqlVer=10.2
# mysqlAptVer="0.8.14-1"
# mysqlRootPass="pass"
# mysqlType="mariadb"


# Helper Functions
downloadFile() {
  FILE="$DL_DIR/${2:-$(basename "$1")}"
  wget "$1" -qO "$FILE"
}
installDeb() {
  downloadFile "$1" $2 && sudo -E dpkg -i "$FILE" 
}
setDebConf() {
  echo $@ | sudo debconf-set-selections
}
addSource() {   # Usage: addSource <line> <filename> [keyUrl]
  echo "$1" | sudo tee "/etc/apt/sources.list.d/$2"
  [ -n "$3" ] && downloadFile "$3" && sudo apt-key add "$FILE" || echo "[ERR] addSource $1";
}


# Initial Clean & Update
  sudo apt purge -y hexchat thunderbird nodejs
  sudo apt autoremove -y
  sudo apt update


# Install Packages (default sources)
  sudo apt install -y git curl nano build-essential neovim tmux ncdu ranger
  sudo apt install -y software-properties-common
  sudo apt install -y openssh-server openvpn
  sudo apt install -y nfs-kernel-server tlp
  sudo apt install -y fonts-firacode
  sudo apt install -y flatpak snapd
  sudo apt install -y filezilla

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install starfish
curl -sS https://starship.rs/install.sh | sh


# Install Packages (custom sources)

  # Repos
  #sudo add-apt-repository -y "ppa:ondrej/php"


  addSource "deb https://dl.google.com/linux/chrome/deb/ stable main" "google-chrome.list" "https://dl.google.com/linux/linux_signing_key.pub"


  # Packages
  sudo apt update
  sudo apt install -y google-chrome-stable

# Install Flatpaks

  # Repos
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  # Packages
  flatpak install -y flathub org.kde.okular
  flatpak install -y flathub org.qbittorrent.qBittorrent
#  flatpak install -y flathub com.github.gijsgoudzwaard.image-optimizer


# Install Snaps
  sudo snap install brave
  sudo snap install chromium
  sudo snap install btop


# Custom Installs

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  # Conditional
  [ "$ID" = "linuxmint" ] && sudo apt install -y mint-meta-codecs
  [ ! $(command -v vlc) ] && flatpak install -y flathub org.videolan.VLC
  [ ! $(command -v gimp) ] && flatpak install -y flathub org.gimp.GIMP
  [ ! $(command -v libreoffice) ] && flatpak install -y flathub org.libreoffice.LibreOffice

  # Teamviewer
  installDeb "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"

#   # Slack (deb installer w/ non-static URL)
#   SLACK_URL=$(curl -s https://slack.com/downloads/instructions/ubuntu | grep 'amd64.deb"' | sed -E 's/.*"(http[^"]+amd64.deb)".*/\1/')
#   [[ -n $SLACK_URL ]] && installDeb "$SLACK_URL"

#   # Composer (php installer)
#   downloadFile "https://getcomposer.org/installer" "composer_install.php" && \
#     php -f "$FILE" -- --install-dir="$BIN_DIR" && \
#     mv "$BIN_DIR/composer.phar" "$BIN_DIR/composer"
#   "$BIN_DIR/composer" global selfupdate && "$BIN_DIR/composer" global update

  # Jetbrains Toolbox (tar.gz archive)
  downloadFile "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA" "jetbrains-toolbox.tar.gz" && \
    tar -xzf "$FILE" -C $DL_DIR && \
    mv -f "$(find $DL_DIR -maxdepth 2 -name jetbrains-toolbox | head -n1)" "$BIN_DIR/jetbrains-toolbox"

  # NodeJS (shell installer)
  downloadFile "https://raw.githubusercontent.com/creationix/nvm/master/install.sh" "nvm_install.sh" && \
    bash "$FILE" && source $HOME/.nvm/nvm.sh && nvm install node

  # MS Fonts (apt install w/ EULA)
  setDebConf "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true"
  sudo -E apt install -y ttf-mscorefonts-installer

  # MySQL (.deb apt repo) - dev.mysql.com/downloads/repo/apt/
#   setDebConf "mysql-apt-config mysql-apt-config/unsupported-platform select ubuntu ${UBUNTU_CODENAME}"
#   setDebConf "mysql-apt-config mysql-apt-config/repo-codename select ${UBUNTU_CODENAME}"
#   setDebConf "mysql-apt-config mysql-apt-config/repo-distro select ubuntu"
#   installDeb "https://dev.mysql.com/get/mysql-apt-config_${mysqlAptVer}_all.deb"
  sudo apt update

#   # MySQL/MariaDB Server/Client
#   if [[ "$mysqlType" = "mariadb" ]]; then
#     setDebConf "mariadb-server-${mysqlVer} mysql-server/root_password password ${mysqlRootPass}"
#     setDebConf "mariadb-server-${mysqlVer} mysql-server/root_password_again password ${mysqlRootPass}"
#     sudo -E apt install -y mariadb-server-${mysqlVer} mariadb-client-${mysqlVer}
#   else
#     setDebConf "mysql-apt-config mysql-apt-config/select-server select mysql-${mysqlVer}"
#     setDebConf "mysql-community-server mysql-community-server/root-pass password ${mysqlRootPass}"
#     setDebConf "mysql-community-server mysql-community-server/re-root-pass password ${mysqlRootPass}"
#     sudo -E apt install -y mysql-server mysql-client
#   fi

  # MySQL Workbench
#   sudo -E apt install -y mysql-workbench-community


# Configuration

  # Enable all magic SysRq keys
  sudo sed -i '/^#kernel.sysrq=1/s/^#//' /etc/sysctl.d/99-sysctl.conf

  # inotify: Raise max watches for IDEs
  echo "fs.inotify.max_user_watches=524288" | sudo tee "/etc/sysctl.d/40-max-user-watches.conf" >/dev/null

  # Vagrant Sudoers
#   echo 'Cmnd_Alias VAGRANT_HOSTS_ADD = /bin/sh -c echo "*" >> /etc/hosts' | sudo tee "/etc/sudoers.d/vagrant_hostsupdater"
#   echo 'Cmnd_Alias VAGRANT_HOSTS_REMOVE = /bin/sed -i -e /*/ d /etc/hosts' | sudo tee -a "/etc/sudoers.d/vagrant_hostsupdater"
#   echo '%sudo ALL=(root) NOPASSWD: VAGRANT_HOSTS_ADD, VAGRANT_HOSTS_REMOVE' | sudo tee -a "/etc/sudoers.d/vagrant_hostsupdater"

  # Permissions
  sudo chown -R $USER: $BIN_DIR/*
  sudo chmod -R 774 $BIN_DIR/*

  sudo chmod 600 $HOME/.ssh/id_rsa*
  sudo chmod 644 $HOME/.ssh/id_rsa*.pub

  sudo chgrp -R sudo /opt
  sudo chmod -R ug+w /opt
  find /opt -type d -exec sudo chmod g+s {} \;


# Cleanup
sudo apt install -y -f
sudo apt autoremove -y
sudo apt clean

cp -rf ./.tmux.conf ~/
cp -rf ./.vimrc ~/
cp -rf ./.zshrc ~/
echo "=== System Install Complete! (Reboot Recommended) ==="

# Download font https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/CascadiaCode.zip