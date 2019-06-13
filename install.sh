#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "please run with sudo."
    exit
fi

if [ $# -eq 0 ]; then
    echo "no username supplied"
    echo "usage: install.sh <username>"
    exit
fi

USER_NAME=$1
GO_VERSION=1.12.2
NODE_VERSION=12
DOCKER_CHANNEL="stable"
DOCKER_COMPOSE_VERSION=1.24.0

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

echo " -> Installing Base Packages"
apt-get install -y \
    apt-transport-https \
    autoconf \
    automake \
    build-essential \
    curl \
    software-properties-common 

# Go
if [ -f "/usr/local/go/bin/go" ]; then
    echo "Go already installed..."
else
    echo " -> Installing Go"
    curl -sSL https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz
    tar -C /usr/local -xvf /tmp/go.tar.gz
fi

echo " -> Installing Development Environment Tooling"
apt-get install -y \
    awscli \
    bzr \
    ca-certificates \
    gnupg-agent \
    htop \
    jq \
    lastpass-cli \
    libncurses5-dev libncursesw5-dev \
    libtool \
    silversearcher-ag \
    sshpass \
    tree \
    tmux \
    vim

echo " -> Installing nodejs ${NODE_VERSION}"
# nodejs
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
apt-get install -y nodejs

echo " -> Installing nodejs tools"
# nodejs tools
npm install -g @vue/cli

echo " -> Installing Docker CE 🐋"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    ${DOCKER_CHANNEL}"
apt-get update
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io
usermod -aG docker ${USER_NAME}

echo " -> Cleaning up apt"
apt-get autoremove -y
apt-get autoclean -y
apt-get clean

echo " -> Installing Docker Compose"
if [ -f "/usr/local/bin/docker-compose" ]; then
	echo "docker-compose already installed..."
else
	curl -s -L \
		"https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
		-o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
fi

echo " -> Installing dotfiles and vim configuration"
su - $USER_NAME <<'EOSU'
USER_NAME=$(whoami)
cd /home/$USER_NAME/.dotfiles
for f in shell/*; do
if [[ "$f" == *bash_* ]] && [[ "$f" != *bash_profile* ]] ; then
    continue;
fi
ln -sfn /home/$USER_NAME/.dotfiles/shell/$(basename $f) /home/$USER_NAME/.$(basename $f)
done

mkdir -p /home/$USER_NAME/.config
mkdir -p /home/$USER_NAME/.local/share/lpass
touch ~/.sudo_as_admin_successful

rm -rf /home/$USER_NAME/.vim
echo " -> Installing vim-plug"
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo " -> Installing vim plugins" && \
    vim +PlugInstall +qall > /dev/null && \
    echo " -> Installing go binaries required by vim-go" && \
    vim +'silent :GoInstallBinaries' +qall > /dev/null
EOSU

echo " -> Adding /etc configuration"
for file in $(find /home/$USER_NAME/.dotfiles/etc -type f -not -name ".*.swp"); do
    f=$(echo $file | sed -e "s|/home/${USER_NAME}/\.dotfiles||");
    mkdir -p $(dirname $f);
    ln -snf $file $f;
done

echo " -> Adding /usr configuration"
for file in $(find /home/$USER_NAME/.dotfiles/usr -type f -not -name ".*.swp"); do
    f=$(echo $file | sed -e "s|/home/${USER_NAME}/\.dotfiles||");
    mkdir -p $(dirname $f);
    ln -snf $file $f;
done

echo " -> Ensure CA certificates are up-to-date"
update-ca-certificates

# ip forwarding
sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sysctl -e -p /etc/sysctl.conf || true

