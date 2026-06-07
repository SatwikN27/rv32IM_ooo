#!/usr/bin/env bash
set -e

VENV_DIR=".venv"

create_venv() {
  echo -e "\e[32mCreating new venv\e[0m"
  python3.9 -m venv "$VENV_DIR"
  source "$VENV_DIR/bin/activate"
  pip install -U pip setuptools wheel
  pip install scons rich pyyaml
  echo -e "\e[32mDone creating venv\e[0m"
}

if [[ -n "$VIRTUAL_ENV" ]]; then
  echo -e "\e[33mDeactivate current venv first\e[0m"
  exit 1
fi

if [[ "$1" == "clean" ]]; then
  rm -rf "$VENV_DIR"
  exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
  create_venv
else
  source "$VENV_DIR/bin/activate"
fi

export OLD_PS1="$PS1"
export PS1="(venv) [\[\e[36m\]\w\[\e[0m\]] \$ "

echo -e "\e[32mEntering venv shell (exit to leave)\e[0m"
exec "$SHELL" -i
