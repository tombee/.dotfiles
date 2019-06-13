#!/bin/bash
set -e

echo -n "Enter your email (e.g. jbloggs@gmail.com) and press [ENTER]: "
read email
echo -n "Enter your full name (e.g. Joe Bloggs) and press [ENTER]: "
read fullname

echo " -> Logging into LastPass"
lpass login --trust "${email}"

echo " -> Creating ~/.bash_profile.local"
cat << EOF > $HOME/.bash_profile.local
export USER_EMAIL="${email}"
export USER_FULL_NAME="${fullname}"
EOF

echo " -> Configuring ~/.gitconfig"
git config --global user.email "${email}"
git config --global user.name "${fullname}"
git config --global core.eol lf
git config --global core.autocrlf input
git config --global core.excludesfile ~/.gitignore_global
