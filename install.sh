#!/usr/bin/env bash
set -euo pipefail

ERROR=$'\033[0;31mError\033[0m'
DONE=$'\033[0;32mdone\033[0m'

GETTER=wget

if ! command -v $GETTER &> /dev/null
then
	if command -v curl &> /dev/null
  then
    GETTER=curl
  else
    echo "$ERROR: Curl or Wget is required to install the latest Goose release."
    exit 1
  fi
fi

if ! command -v unzip &> /dev/null
then
  echo "$ERROR: Unzip is required to install the latest Goose release."
  exit 1
fi

if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null
then
  echo "$ERROR: A C compiler is required to install the latest Goose release."
  exit 1
fi 

echo "* Searching a release..."

TAG=$(curl --silent "https://api.github.com/repos/goose-language/goose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

echo " found '${TAG}'"

DL_LINK="https://github.com/goose-language/goose/releases/download/${TAG}/"

KERNEL=$(uname -a | awk '{print $1}')
FILE=goose_linux.zip

if [[ $KERNEL == "Darwin" ]]
then
	FILE="goose_macos.zip"
elif [[ $KERNEL != "Linux" ]]
then
	echo "$ERROR: Your kernel (${KERNEL}) is currently not supported. Please open an issue at <https://github.com/goose-language/goose/issues/new> to reclaim it."
	exit 1
fi

INSTALL_FOLDER="${HOME}/.goose"

if [[ $# -ge 1 ]]
then
	INSTALL_FOLDER="$1"
fi

if [[ -d $INSTALL_FOLDER ]]
then
	rm -fr $INSTALL_FOLDER
fi

mkdir -p $INSTALL_FOLDER
cd $INSTALL_FOLDER

echo "* Downloading the latest Goose release archive... "
echo "* Downloading ${DL_LINK}/${FILE}..."

if [[ $GETTER == "wget" ]]
then
  wget -q ${DL_LINK}/${FILE}
else
  curl -s -L ${DL_LINK}/${FILE} -o ${FILE}
fi
echo "$DONE"

echo "* Deflating archive..."
unzip -qq ${FILE}
echo "$DONE"

echo "* Cleaning ${INSTALL_FOLDER} directory..."
rm -fr ${FILE}
echo "$DONE"
SHELL=$(echo $SHELL | rev | cut -d'/' -f 1 | rev) # Get only shell binary name.
case $SHELL in
	"bash")
		BASHRC="${HOME}/.bashrc"
		echo "* Configuring ${BASHRC}..."
		echo "\nexport PATH=\"${INSTALL_FOLDER}:\$PATH\"" >> $BASHRC
		echo "export GOOSE=\"${INSTALL_FOLDER}\"" >> $BASHRC
		echo "$DONE"
		;;
	"zsh")
		ZSHRC="${HOME}/.zshrc"
		echo "* Configuring ${ZSHRC}..."
		echo "\nexport PATH=\"${INSTALL_FOLDER}:\$PATH\"" >> $ZSHRC
		echo "export GOOSE=\"${INSTALL_FOLDER}\"" >> $ZSHRC
		echo "$DONE"
		;;
	"fish")
		CONFIG_FISH="${HOME}/.config/fish/config.fish"
		echo "* Configuring ${CONFIG_FISH}..."
		echo "\nset PATH ${INSTALL_FOLDER} \$PATH" >> $CONFIG_FISH
		echo "export GOOSE=\"${INSTALL_FOLDER}\"" >> $CONFIG_FISH
		echo "$DONE"
		;;
	*)
		echo "Your shell cannot be automatically configured."
		echo "Please add \"${INSTALL_FOLDER}\" to your \$PATH"
		echo "And set a \`GOOSE\` environment variable pointing to \"${INSTALL_FOLDER}\"."
		;;
esac
echo 