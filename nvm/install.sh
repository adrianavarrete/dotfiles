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

# Configure npm to use bash for scripts so BASH_ENV is sourced
# This ensures npm_config_prefix is unset before nvm runs
npm config set script-shell /bin/bash

exit 0