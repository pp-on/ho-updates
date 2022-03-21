#!/bin/bash
UNAME="$(uname -a)"

case $( echo "${UNAME}" | tr '[:upper:]' '[:lower:]') in
  linux)
    printf 'linux\n'
    ;;
  *wsl*)
    printf 'wsl\n'
    ;;
  msys*|cygwin*|mingw*)
    # or possible 'bash on windows'
    printf 'Git Bash\n'
    ;;
  nt|win*)
    printf 'windows\n'
    ;;
  *)
    printf 'unknown\n'
    ;;
esac
