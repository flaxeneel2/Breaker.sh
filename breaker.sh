#!/bin/bash

################################################
#                    Colors                    #
################################################

#reset
NC='\033[0m'

#normal colors
RED='\033[0;31m'
BLACK='\033[0;30m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
DGRAY='\033[1;30m'

#light colors
LRED='\033[0;31m'
LBLACK='\033[0;30m'
LGREEN='\033[0;32m'
LYELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LPURPLE='\033[1;35m'
LCYAN='\033[1;36m'
LWHITE='\033[1;37m'

#text types
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
UNDERLINE=$(tput smul)
BLINK=$(tput blink)
REV=$(tput rev)
STANDOUT=$(tput smso)

################################################
#                     Main                     #
################################################

#toilet -f smblock --filter border:metal 'Breaker.sh'
echo -e "${PURPLE}1${LPURPLE}) ${PURPLE}Minecraft java"
echo -e "${PURPLE}2${LPURPLE}) ${PURPLE}Minecraft bedrock"
echo -e "${PURPLE}3${LPURPLE}) ${PURPLE}Discord Bots"
read -p "${NORMAL}Selection: " OPTION
if [[ "$OPTION" = "1" ]]; then
  echo -e "${PURPLE}1${LPURPLE}) ${PURPLE}PaperMC"
  read -p "${NORMAL}Selection: " OPTION_TWO
  if [[ "$OPTION_TWO" = "1" ]]; then
    echo -e "${PURPLE}Installing PaperMC${DGRAY}"
  fi

else
  echo "2"
fi
