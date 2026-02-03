# Use `hub` as our git wrapper:
#   http://defunkt.github.com/hub/
hub_path=$(which hub)
if (( $+commands[hub] ))
then
  alias git=$hub_path
fi

#functions
git_commit() {
    # Verifica que se haya pasado un argumento (mensaje de commit)
    if [ -z "$1" ]; then
        echo "Error: No commit message provided."
        echo "Usage: gcommit <commit_message> [no-verify]"
        return 1
    fi

    # Inicializa la opción de no-verify
    local no_verify_option=""

    # Verifica si el segundo argumento es 'no-verify'
    if [ "$2" = "no-verify" ]; then
        no_verify_option="--no-verify"
    fi

    # Realiza el commit con o sin la opción --no-verify
    git commit $no_verify_option -m "$1"
}



# The rest of my fun git aliases
alias gl='git pull --prune'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp='git push origin HEAD'

# Remove `+` and `-` from start of diff lines; just rely upon color.
alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/" | less -r'

alias gc='git_commit'
alias gca='git commit -a'
alias gco='git checkout'
alias gcb='git copy-branch-name'
alias gb='git branch'
alias gs='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias gac='git add -A && git commit -m'
alias ge='git-edit-new'
