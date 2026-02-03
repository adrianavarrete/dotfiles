#!/bin/sh
#
# NVM
#
# This installs nvm

# Check if nvm is already installed
if [ ! -d "$HOME/.nvm" ]
then
  echo "  Installing nvm for you."

  # Install nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  echo "  nvm is already installed."
fi

exit 0