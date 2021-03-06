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
    echo -e "${PURPLE}Jabba not found! Installing jabba!"
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash -s -- --skip-rc | awk -W interactive -v c="$DGRAY" '{ print c $0 }' && . /home/container/.jabba/jabba.sh
  fi;
  source /home/container/.jabba/jabba.sh
  if [ -z "$JAVA_VERSION" ]; then
    echo -e "${PURPLE}Looks like you have not chosen a java version for your server! Please choose a java version"
    tip "You can set the java version in the startup section to skip this prompt!"
    echo -e "${PURPLE}Recommended values:"
    echo -e "${PURPLE}Java ${LPURPLE}8${PURPLE} for Minecraft 1.12.2 or older"
    echo -e "${PURPLE}Java ${LPURPLE}11${PURPLE} for Minecraft 1.12.2 to Minecraft 1.16.5"
    echo -e "${PURPLE}Java ${LPURPLE}17${PURPLE} for Minecraft 1.17 or newer."
    read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" JAVA_VERSION
  fi
  if [ "$JAVA_VERSION" = "8" ]; then
    JAVA_VERSION="adopt@1.8-0"
  elif [ "$JAVA_VERSION" = "11" ]; then
    JAVA_VERSION="adopt@1.11.0-0"
  elif [ "$JAVA_VERSION" = "17" ]; then
    JAVA_VERSION="openjdk@1.17.0"
  fi
  echo -e "${PURPLE}Installing java ${LPURPLE}${JAVA_VERSION}${PURPLE}!"
  jabba install "$JAVA_VERSION" >> /dev/null 2>&1
  sleep 0.5
  jabba use "$JAVA_VERSION"
}

install_buildtools () {
  if ! [ -f "/home/container/.breaker/buildtools/BuildTools.jar" ]; then
    mkdir /home/container/.breaker/buildtools -p
    echo -e "${DGRAY}Installing buildtools..."
    curl -s -L https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar -o /home/container/.breaker/buildtools/BuildTools.jar
  fi

}


##############################
#           Spigot           #
##############################

compile_spigot () {
  install_buildtools
  cd /home/container/.breaker/buildtools || return
  echo "${DGRAY}Compiling spigot..."
  java -Xms256M -Xmx"${SERVER_MEMORY}"M -jar BuildTools.jar --rev "${!1}" --compile SPIGOT | awk -W interactive -v c="$DGRAY" '{ print c $0 }'
  mv /home/container/.breaker/buildtools/Spigot/Spigot-Server/target/spigot-*.jar /home/container/server.jar
  find . ! -name 'BuildTools.jar' -exec rm -rf {} + > /dev/null 2>&1
}

install_spigot () {
  load_jabba
  SPIGOT_VERSIONS_LIST=$(curl -s https://hub.spigotmc.org/versions/ | grep -i -E -w '"(.*.json)"' -o | tr '\n' ', ' | awk '{ print "[" substr($0, 1, length($0)-1) "]" }')
  ask_till_valid "${PURPLE}Please choose the minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_spigot_versions SPIGOT_VERSION "$(echo "${SPIGOT_VERSIONS_LIST}" | jq -r '. | map(. | sub(".json";""))')"
  echo -e "${PURPLE}Installing Spigot ${LPURPLE}${SPIGOT_VERSION}"
  compile_spigot SPIGOT_VERSION
}

display_spigot_versions () {
  if [ -z "${SPIGOT_VERSIONS_LIST+x}" ];  then
      SPIGOT_VERSIONS_LIST=$(curl -s https://hub.spigotmc.org/versions/ | grep -i -E -w '"(.*.json)"' -o | tr '\n' ', ' | awk '{ print "[" substr($0, 1, length($0)-1) "]" }')
  fi
  echo "$SPIGOT_VERSIONS_LIST" | jq -r '.[] | sub(".json";"") | select(test(".*\\..*")) | "\u001b[32m\(.)"'
}

##############################
#           Purpur           #
##############################

install_purpur () {
  PURPUR_VERSIONS_LIST=$(curl -s https://api.purpurmc.org/v2/purpur)
  ask_till_valid "${PURPLE}Please choose the minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_purpur_versions PURPUR_VERSION "$(echo "${PURPUR_VERSIONS_LIST}" | jq -r '.versions')"
  echo -e "${PURPLE}Installing Purpur ${LPURPLE}${PURPUR_VERSION}"
  curl -s "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" -o server.jar
  echo -e "${PURPLE}Purpur installed!"
  run_jar
}

display_purpur_versions () {
  if [ -z "${PURPUR_VERSIONS_LIST+x}" ];  then
      PURPUR_VERSIONS_LIST=$(curl -s https://api.purpurmc.org/v2/purpur)
    fi
    echo "$PURPUR_VERSIONS_LIST" | jq -r '.versions | .[] | "\u001b[32m\(.)"'
}


#############################
#           Paper           #
#############################

install_paper () {
  PAPER_VERSIONS_LIST=$(curl -s https://papermc.io/api/v2/projects/paper)
  ask_till_valid "${PURPLE}Please choose the minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_paper_versions PAPER_VERSION "$(echo "${PAPER_VERSIONS_LIST}" | jq -r '.versions')"
  echo -e "${PURPLE}Installing PaperMC${DGRAY}"
  get_latest_paper_build PAPER_VERSION LATEST_PAPER_BUILD
  curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_PAPER_BUILD}.jar" -o server.jar
  echo -e "${PURPLE}PaperMC installed!"
  run_jar
}

display_paper_versions () {
  if [ -z "${PAPER_VERSIONS_LIST+x}" ];  then
    PAPER_VERSIONS_LIST=$(curl -s https://papermc.io/api/v2/projects/paper)
  fi
  echo "$PAPER_VERSIONS_LIST" | jq -r '.versions | .[] | "\u001b[32m\(.)"'
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
  echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Purpur"
  echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Spigot"
  read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" OPTION_TWO
  if [ "$OPTION_TWO" = "1" ]; then
    install_paper
  elif [ "$OPTION_TWO" = "2" ]; then
    install_purpur
  elif [ "$OPTION_TWO" = "3" ]; then
    install_spigot
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

tip () {
  if [ "$TIPS" = "1" ]; then
    echo -e "${YELLOW}Tip: $1"
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
