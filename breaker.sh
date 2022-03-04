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

##############################
#        Dependencies        #
##############################

load_jabba () {
  if [[ ! -d "/home/container/.jabba" ]]; then
    echo -e "${PURPLE}Jabba not found! Insalling jabba${DGRAY}"
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash -s -- --skip-rc && . /home/container/.jabba/jabba.sh | awk -v c="$DGRAY" '{print c $0}'
    echo -e "${NORMAL}"
  fi;
  source /home/container/.jabba/jabba.sh
  if [ -z "$JAVA_VERSION" ]; then
    echo -e "${PURPLE}Looks like you have not chosen a java version for your server! Please choose a java version"
    if [ -z "${NO_TIPS+x}" ]; then
      echo -e "${YELLOW}Tip: You can set the java version in the startup section to skip this prompt!"
    fi
    echo -e "${PURPLE}Recommended values:"
    echo -e "${PURPLE}Java ${LPURPLE}8${PURPLE} for Minecraft 1.12.2 or older"
    echo -e "${PURPLE}Java ${LPURPLE}11${PURPLE} for Minecraft 1.12.2 to Minecraft 1.16.5"
    echo -e "${PURPLE}Java ${LPURPLE}17${PURPLE} for Minecraft 1.17 or newer."
    read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" JAVA_VERSION
    if [ "$JAVA_VERSION" = "8" ]; then
      JAVA_VERSION="adopt@1.8-0"
    elif [ "$JAVA_VERSION" = "11" ]; then
      JAVA_VERSION="adopt@1.11.0-0"
    elif [ "$JAVA_VERSION" = "17" ]; then
      JAVA_VERSION="openjdk@1.17.0"
    fi
  fi
  jabba install "$JAVA_VERSION"
  jabba use "$JAVA_VERSION"
}

#############################
#           Paper           #
#############################

install_paper () {
  ask_till_valid "${PURPLE}Please choose the minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_paper_versions PAPER_VERSION "$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions')"
  echo -e "${PURPLE}Installing PaperMC${DGRAY}"
  get_latest_paper_build PAPER_VERSION LATEST_PAPER_BUILD
  curl "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_PAPER_BUILD}.jar" -o server.jar
  echo -e "${PURPLE}PaperMC installed!"
  load_jabba
}

display_paper_versions () {
  curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions | .[] | "\u001b[32m\(.)"'
}

get_latest_paper_build () {
  if [ -n "$1" ] && [ -n "$2" ]; then
    declare -g "${2}"="$(curl -s https://papermc.io/api/v2/projects/paper/versions/"${!1}" | jq -r '.builds[-1]')"
  else
    echo "Looks like flax forgot to pass arguments for getting latest paper build!";
  fi;
}



##############################
#          Submenus          #
##############################

install_minecraft_java () {
  echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}PaperMC"
  read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" OPTION_TWO
  if [[ "$OPTION_TWO" = "1" ]]; then
    install_paper
  fi
}

##############################
#            Misc            #
##############################

#This function takes 5 arguments
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


run_jar () {
  load_jabba
  if [ "$SMART_STARTUP" = "1" ] || [ "${SMART_STARTUP,,}" = "true" ]; then
    echo -e "${PURPLE}Using optimized startup parameters"
    java -Xms256M -Xmx$((SERVER_MEMORY - (SERVER_MEMORY/10)))M  -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar "${SERVER_JARFILE}" | awk -W interactive -v c="$PURPLE" '{ print $0 } { if ($0 ~ ")! For help, type") { print c "Looks like your server is up!" } }'
  else
    echo -e "${PURPLE}Using normal startup parameters"
    java -Xms256M -Xmx"${SERVER_MEMORY}"M -jar "${SERVER_JARFILE}" | awk -W interactive -v c="$PURPLE" '{ print $0 } { if ($0 ~ ")! For help, type") { print c "Looks like your server is up!" } }'
  fi
}

################################################
#                     Main                     #
################################################

echo -e " ${LPURPLE}/${PURPLE}\$\$\$\$\$\$\$                                ${LPURPLE}/${PURPLE}\$\$"
echo -e "${LPURPLE}| ${PURPLE}\$\$${LPURPLE}__ ${PURPLE} \$\$                              ${LPURPLE}| ${PURPLE}\$\$"
echo -e "${LPURPLE}| ${PURPLE}\$\$  ${LPURPLE}\\ ${PURPLE}\$\$  ${LPURPLE}/${PURPLE}\$\$\$\$\$\$   ${LPURPLE}/${PURPLE}\$\$\$\$\$\$   ${LPURPLE}/${PURPLE}\$\$\$\$\$\$ ${LPURPLE}|${PURPLE} \$\$   ${LPURPLE}/${PURPLE}\$\$  ${LPURPLE}/${PURPLE}\$\$\$\$\$\$   ${LPURPLE}/${PURPLE}\$\$\$\$\$\$"
echo -e "${LPURPLE}| ${PURPLE}\$\$\$\$\$\$\$  ${LPURPLE}/${PURPLE}\$\$${LPURPLE}__  ${PURPLE}\$\$ ${LPURPLE}/${PURPLE}\$\$${LPURPLE}__  ${PURPLE}\$\$ ${LPURPLE}|____  ${PURPLE}\$\$${LPURPLE}| ${PURPLE}\$\$  ${LPURPLE}/${PURPLE}\$\$${LPURPLE}/ /${PURPLE}\$\$${LPURPLE}__  ${PURPLE}\$\$${LPURPLE} /${PURPLE}\$\$${LPURPLE}__  ${PURPLE}\$\$"
echo -e "${LPURPLE}| ${PURPLE}\$\$${LPURPLE}__  ${PURPLE}\$\$${LPURPLE}| ${PURPLE}\$\$${LPURPLE}  \\__/|${PURPLE} \$\$\$\$\$\$\$\$ ${LPURPLE} /${PURPLE}\$\$\$\$\$\$\$${LPURPLE}| ${PURPLE}\$\$\$\$\$\$${LPURPLE}/ | ${PURPLE}\$\$\$\$\$\$\$\$${LPURPLE}| ${PURPLE}\$\$  ${LPURPLE}\\__/"
echo -e "${LPURPLE}| ${PURPLE}\$\$  ${LPURPLE}\\ ${PURPLE}\$\$${LPURPLE}| ${PURPLE}\$\$      ${LPURPLE}| ${PURPLE}\$\$${LPURPLE}_____/ /${PURPLE}\$\$${LPURPLE}__  ${PURPLE}\$\$${LPURPLE}| ${PURPLE}\$\$${LPURPLE}_  ${PURPLE}\$\$ ${LPURPLE}| ${PURPLE}\$\$${LPURPLE}_____/| ${PURPLE}\$\$"
echo -e "${LPURPLE}| ${PURPLE}\$\$\$\$\$\$\$${LPURPLE}/|${PURPLE} \$\$      ${LPURPLE}|  ${PURPLE}\$\$\$\$\$\$\$${LPURPLE}|${PURPLE}  \$\$\$\$\$\$\$${LPURPLE}| ${PURPLE}\$\$ ${LPURPLE}\\ ${PURPLE} \$\$${LPURPLE}|${PURPLE}  \$\$\$\$\$\$\$${LPURPLE}|${PURPLE} \$\$"
echo -e "${LPURPLE}|_______/ |__/       \\_______/ \\_______/|__/  \__/ \\_______/|__/"

if [ -f "server.jar" ]; then
  echo -e "${PURPLE}Starting your server..."
  run_jar
else
  echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Minecraft java"
  echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Minecraft bedrock"
  echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Discord Bots"
  read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" OPTION
  if [[ "$OPTION" = "1" ]]; then
    install_minecraft_java
  else
    echo "2"
  fi
fi
