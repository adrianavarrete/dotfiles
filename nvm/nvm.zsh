# Load nvm
export NVM_DIR="$HOME/.nvm"

# Unset npm_config_prefix to avoid conflicts with nvm
# This can be set by Homebrew's node or global npm config
unset npm_config_prefix

# BASH_ENV is sourced before non-interactive bash scripts (like npm run scripts)
# This ensures npm_config_prefix is unset even when npm re-sets it
export BASH_ENV="$DOTFILES/nvm/nvm-env.sh"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export DVM_DIR="$HOME/.dvm"
export PATH="$DVM_DIR/bin:$PATH"


autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc