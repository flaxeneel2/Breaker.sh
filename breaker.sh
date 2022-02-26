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


#################################################
#                   Functions                   #
#################################################

load_jabba () {
  if [[ ! -d "/home/container/.jabba" ]]; then
    echo -e "${PURPLE}Jabba not found! Insalling jabba${DGRAY}"
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash -s -- --skip-rc && . /home/container/.jabba/jabba.sh
    echo -e "${NORMAL}"
  fi;
  source /home/container/.jabba/jabba.sh
}

install_paper () {
  echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}PaperMC"
  read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" OPTION_TWO
  if [[ "$OPTION_TWO" = "1" ]]; then
    load_jabba
    ask_till_valid "${PURPLE}Please choose the minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_paper_versions PAPER_VERSION "$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions')"
    echo -e "${PURPLE}Installing PaperMC${DGRAY}"
  fi
}

display_paper_versions () {
  curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions | .[] | "\u001b[32m\(.)"'
}

#This function takes 3 arguments
# $1: message: The message to repeat on fail
# $2: special_input: A special input that will trigger a special function if entered
# $3: handler: The handler for if special_input is entered
# $4: variable: The variable to store the answer to
# $5: accepted_values: optional, if set, function will check if the input is valid or not
ask_till_valid () {
  while [ -z "$ANSWER" ]; do
    echo -e "$1"
    read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" ANSWER
    if [[ ${ANSWER,,} == "${2,,}" ]]; then
      $3
      unset ANSWER
      continue
    fi
    if [ -n "$5" ]; then
      if [ "$(jq --arg ver "$ANSWER" 'index($ver)' <<< "$5")" == "null" ]; then
        echo -e "${RED}Invalid input! Please try again"
        unset ANSWER
      fi
    fi
  done
  declare -g "${4}"="$ANSWER"
  unset "$ANSWER"
}

################################################
#                     Main                     #
################################################

#toilet -f smblock --filter border:metal 'Breaker.sh'
echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Minecraft java"
echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Minecraft bedrock"
echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Discord Bots"
read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" OPTION
if [[ "$OPTION" = "1" ]]; then
  install_paper
else
  echo "2"
fi
