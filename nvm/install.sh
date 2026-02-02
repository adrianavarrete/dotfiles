#!/bin/sh
#
# NVM
#
# This installs nvm

# Check for Homebrew
if test ! $(which nvm)
then
  echo "  Installing nvm for you."

  # Install nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

fi

exit 0