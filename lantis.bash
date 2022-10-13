#!/bin/bash

# LANTIS EasyLink 2 #
if [ -f ./.stat.inet ]; then rm -f ./.stat.inet; echo "[---------][$(date "${DATE_FORMAT}")][WARN] Watchdog State Control will be dropped"; fi
# OPERATIONS ###########################################################################################################
HEADER() {
cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Yukimi Kazari
      Academy City Research

EOF
}
USAGE(){
cat << EOF
 support : help.lantis.project@acr.moe

 LANTIS EasyLink Router 4 - Usage:
 
 Launch ================================================================
 -l  Launch a Connecion           -L  Launch ALL Connections
 
 Drop ==================================================================
 -k  Drop a Connection            -K  Drop ALL Connections

 Extra Options (MUST be set before a action) ===========================
 -C  Use another port list (Default: ./ports.lantis.csv)
 -X  Dry Run (Does not do any action but test full connection)
 -Z  Display Setup Guide

 NOTE: You can give multiple actions (ex: -l admin -k ssh -l rdp)

EOF
}
if [ $# -lt 1 ]; then HEADER; USAGE; exit 0; fi
SETUPGUIDE(){
cat << EOF
 support : help.lantis.project@acr.moe

 Setup Guide:

 1) Generate a SSH key in ~/.ssh/id_rsa
      [root@local]~ ssh-keygen –b 4086
 2) Add id_rsa.pub to /root /.ssh/authorized_keys on the remote server
 3) Generate a SSH key for LANTIS in your current directory where the script will stay
      [root@local]~/LANTIS ssh-keygen –b 4096 –f lantis.key
 
EOF
}
RESET_VARS() {
  unset CONNECTION_NAME
  unset CONTROL_INTERFACE
  unset ENABLED
  unset REMOTE_HOST
  unset REMOTE_PORT
  unset REMOTE_USER
  unset REMOTE_SETUP
  unset REMOTE_KILL
  unset LOCAL_OPEN
  unset LOCAL_HOST
  unset LOCAL_PORT
  unset LOCAL_USER
  unset FORWARD_PORTS
  unset REVERSE_PORTS
  unset FORWARD_PUBLIC
  unset REVERSE_PUBLIC
  unset EXTRA_COMMANDS
}
FORKER () {
  RESET_VARS;
  # shellcheck disable=SC1090
  source "${1}";
  if [ "${ENABLED}" = "true" ] && [ "${2}" = "1" ] || [ "${2}" = "2" ]; then
    echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] $(if [ "${2}" = 1 ]; then echo "Launching"; elif [ "${2}" = 2 ]; then echo "Dropping"; fi) Connection...";

    if [ ${DRY} -eq 1 ]; then
      echo "./.watchdog.lantis.bash -n ${CONNECTION_NAME} -m ${2} -X ${DRY} -c ${1}";
      bash ./.watchdog.lantis.bash -n ${CONNECTION_NAME} -m ${2} -X ${DRY} -c "${1}";
    else
      pkill -f "^bash ./.watchdog.lantis.bash -n ${CONNECTION_NAME} *." > /dev/null;
      nohup bash ./.watchdog.lantis.bash -n "${CONNECTION_NAME}"  -m ${2} -X ${DRY} -c ${1} >> "${LOG_FILE}" &;
    fi
    sleep $(if [ ${2} = 1 ]; then echo "${TIME_LAUNCH_PAUSE}"; elif [ ${2} = 2 ]; then echo "${TIME_DROP_PAUSE}"; fi);
  fi
}
WATCHDOG() {
  for CONNECTION_FILE in "${CONNECTIONS_FOLDER}"/*.rc; do
      FORKER "${CONNECTION_FILE}" ${1};
  done
}
# SET VARS #############################################################################################################
DRY=0; CONNECTIONS_FOLDER="./connections"; LOG_FILE="./lantis.log"; TIME_LAUNCH_PAUSE=4; TIME_DROP_PAUSE=2; DATE_FORMAT='+%d/%m/%Y %H:%M:%S'
source ./.lantis.config
# MAIN RUNTIME #########################################################################################################
echo "= LANTIS Router 4 - Academy City Research ========="
echo "[---------][$(date "${DATE_FORMAT}")][ OK ] System Ready"
# PARSE INPUT ##########################################################################################################
while getopts "C:XLl:Kk:Z" opt; do 
  case $opt in
  	C) CONNECTIONS_FOLDER="${OPTARG}";;
    X) DRY=1;;
    L) HEADER; WATCHDOG 1;;
    l) WATCHDOG 1 ${OPTARG};;
    K) HEADER; WATCHDOG 2;;
    k) WATCHDOG 2 ${OPTARG};;
      Z) HEADER; SETUPGUIDE; exit 0;;
      \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
      :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
