#!/usr/bin/env bash

set -eu
set -o pipefail

DIR=$1
shift
COMMAND=$1
shift

ENTRYPOINT=$DIR/default.nix
source $DIR/scripts/utils.sh

list() {
    paste -d' ' <(echo -e $(nix-instantiate $DIR/lib.nix -A list --eval --strict | tr -d "\"") | column -t -R 2) <(nix-env -f $ENTRYPOINT -q -a -c --no-name --description) | grep --color -E '^|>|<'
}

install() {
    local pkgs="$@"
    log-run "nix-env -f $ENTRYPOINT -iA $pkgs"
}

uninstall() {
    local pkgs="$@"
    log-run "nix-env -e $pkgs"
}

update() {
    log "Updating toolbox ..."
    pushd $DIR 2>&1 >/dev/null
    if [[ ! $(git rev-parse --abbrev-ref HEAD) == "master" ]]; then
      log-error "I am not on the master branch. Aborting"
      exit 1
    fi
    log-run "git fetch origin"
    if [[ $(git rev-parse origin/master) == $(git rev-parse HEAD) ]]; then
      log "Already up-to-date!"
    else
      log-run "git pull origin master"
    fi
    log-run "nix-env -f $ENTRYPOINT -u -b"
    popd 2>&1 >/dev/null
}

doctor() {
    OK="\e[32mOK\e[0m"
    X="\e[31mX\e[0m"
    FAIL=""

    log "Running sanity checks:\n"

    if _isNixInstalled
    then
        echo -e "- Nix installed :  $OK"
    else
        echo -e "- Nix installed :  $X"
        FAIL="."
    fi

    if _isSubstituterConfigured
    then
        echo -e "- toolbox binary cache : $OK"
    else
        echo -e "- toolbox binary cache : $X"
        FAIL="."
    fi

    if [[ $FAIL = "" ]]; then
        echo -e "\nAll essential tests passed."
    else
        echo -e "\nSome tests failed. Try running the init command:\n"
        echo -e "  ./toolbox init\n"
        echo -e "Check the 'Manual Configuration' section of the README.md if you continue to experience problems."
        exit 1
    fi
}

make-shell() {
    sha=$(git -C $DIR rev-parse origin/master)
    log "Using commit $sha for this development shell"
    url="https://git.corp.cloudwatt.com/api/v4/projects/jpbraun%2Ftoolbox/repository/archive?sha=$sha"
    log "Calculating sha256 for $url"
    sha256=$(nix-prefetch-url --unpack $url 2>/dev/null)
    log "Writing shell.nix file"
    cat <<EOF > shell.nix
# Generated by: toolbox make-shell ${@}
let
  toolboxSrc = builtins.fetchTarball {
    url = "$url";
    sha256 = "$sha256";
  };
  toolbox = import toolboxSrc {};
  pkgs = import <nixpkgs> {};
in
  pkgs.runCommand "deps" {
    buildInputs = with toolbox; [
      ${@}
    ];
  } ""
EOF

    log "To activate the development shell:"
    log " - add 'use_nix' in an .envrc file to load tools with direnv"
    log " - or run 'nix-shell' to spawn a new shell with the tools"
}

case "$COMMAND" in
    list)
        list "$@"
        ;;
    install)
        check_args_greater $# 1 "install"
        install "$@"
        ;;
    uninstall)
        check_args_greater $# 1 "uninstall"
        uninstall "$@"
        ;;
    update)
        update "$@"
        ;;
    make-shell)
        check_args_greater $# 1 "make-shell"
        make-shell "$@"
        ;;
    doctor)
        doctor
        ;;
    *)
        echo "Error: unknown command: $COMMAND"
        usage
        exit 1
esac