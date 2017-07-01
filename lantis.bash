#!/bin/bash

# LANTIS EasyLink 2 #
# OPERATIONS ###########################################################################################################
HEADER() {
cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research

EOF
}
USAGE(){
cat << EOF
 support : help.lantis.project@acr.moe

 LANTIS EasyLink Router 2 - Usage:
 
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
SETUPGUIDE(){
cat << EOF
 support : help.lantis.project@acr.moe

 Setup Guide:

 1) Generate a SSH key in ~/.ssh/id_rsa
      [root@local]~ ssh-keygen –b 4086
 2) Add id_rsa.pub to /root /.ssh/authorized_keys on the remote server
 3) Generate a SSH key for LANTIS in your current directory where the script will stay
      [root@local]~/LANTIS ssh-keygen –b 4096 –f lantis.key
 4) Add the entry to the port list with the setup bit set to 1, run that connection
 5) You should be fine as long as your destination host allows your default ssh key

 CSV File Guide:
 
 NOTE: You can use "^" to use last value
 NOTE: You can use "~" for Local Host to use your current Public IP (Updated on Connection Drop)
 NOTE: Disabled connections are still read
 NOTE: You can only use Public Ports 1-2014 if you are using Remote User root
 WARN: There is little input verification, make sure you know what your doing
 WARN: You cannot use the same local port when using Bypass NAT
 
 1 ) Enable or Disale Connection [e,d]
 2 ) Connection Name [string.no spaces]
 3 ) Remote Host [string]
 4 ) Remote Port [int]
 5 ) Remote User [string]
 6 ) Local Host [~ for dynamic ip]
 7 ) Local Port [int]
 8 ) Local User [string]
 9 ) Setup End Point [y or n]
 10) Bypass Inbound NAT [y or n]
 11) Hijack Port [y or n]
 12) Public Server Port [int]
 13) Local Server Host [string]
 14) Local Server Port [int]
 15) Public or Remote Host-Only [p or l]
 
EOF
}
FORKER () {
echo "[${CONNECTION_NAME}][$(date)][INFO] $(if [ ${1} = 1 ]; then echo "Launching"; elif [ ${1} = 2 ]; then echo "Dropping"; fi) Connection..."
if [ ${DRY} -eq 1 ]; then 
	echo "./watchdog.lantis.bash -n ${CONNECTION_NAME} -h ${REMOTE_HOST} -p ${REMOTE_PORT} -u ${REMOTE_USER} \
	-H ${LOCAL_HOST} -P ${LOCAL_PORT} -U ${LOCAL_USER} -D ${LOCAL_FWDHOST} -t ${REMOTE_FWDPORT} -T ${LOCAL_FWDPORT}${EXTRA_OPT}"
	bash ./watchdog.lantis.bash -n ${CONNECTION_NAME} -h ${REMOTE_HOST} -p ${REMOTE_PORT} -u ${REMOTE_USER} \
	-H ${LOCAL_HOST} -P ${LOCAL_PORT} -U ${LOCAL_USER} -D ${LOCAL_FWDHOST} -t ${REMOTE_FWDPORT} -T ${LOCAL_FWDPORT}${EXTRA_OPT} -m ${1} -X ${DRY}
else 
	pkill -f "bash ./watchdog.lantis.bash -n ${CONNECTION_NAME}*" > /dev/null
	nohup bash ./watchdog.lantis.bash -n ${CONNECTION_NAME} -h ${REMOTE_HOST} -p ${REMOTE_PORT} -u ${REMOTE_USER} \
	-H ${LOCAL_HOST} -P ${LOCAL_PORT} -U ${LOCAL_USER} -D ${LOCAL_FWDHOST} -t ${REMOTE_FWDPORT} -T ${LOCAL_FWDPORT}${EXTRA_OPT} -m ${1} &> ${LOG_FILE} & 
fi
sleep $(if [ ${1} = 1 ]; then echo "${TIME_LAUNCH_PAUSE}"; elif [ ${1} = 2 ]; then echo "${TIME_DROP_PAUSE}"; fi)
}
WATCHDOG() {
while read in; do
if [[ $(echo $in | awk -F '[ ]' '{print $1}') != "#" ]]; then
	SKIP=0; EXTRA_OPT=""; 
	CONNECTION_STATUS=$(echo $in | awk -F '[;]' '{print $1}')  #Enabled[E or D]
	CONNECTION_NAME=$(echo $in | awk -F '[;]' '{print $2}')    #Name[string]
	L_REMOTE_HOST=$(echo $in | awk -F '[;]' '{print $3}')      #Remote Host[string]
	L_REMOTE_PORT=$(echo $in | awk -F '[;]' '{print $4}')      #Remote Port[string]
	L_REMOTE_USER=$(echo $in | awk -F '[;]' '{print $5}')      #Remote User[string]
	L_LOCAL_HOST=$(echo $in | awk -F '[;]' '{print $6}')       #Local Host[string]
	L_LOCAL_PORT=$(echo $in | awk -F '[;]' '{print $7}')       #Local Port[string]
	L_LOCAL_USER=$(echo $in | awk -F '[;]' '{print $8}')       #Local User[string]
	L_REMOTE_SETUP=$(echo $in | awk -F '[;]' '{print $9}')     #Remote Setup[strng]
	L_LOCAL_OPEN=$(echo $in | awk -F '[;]' '{print $10}')      #Bypass NAT[int]
	L_REMOTE_KILL=$(echo $in | awk -F '[;]' '{print $11}')     #Kill Access[int]
	REMOTE_FWDPORT=$(echo $in | awk -F '[;]' '{print $12}')    #Server Remote Port[int]
	L_LOCAL_FWDHOST=$(echo $in | awk -F '[;]' '{print $13}')   #Server Local Host[string]
	L_LOCAL_FWDPORT=$(echo $in | awk -F '[;]' '{print $14}')   #Server Local Port[int]
	L_REMOTE_FWDPUB=$(echo $in | awk -F '[;]' '{print $15}')   #Public or Local[P or L]
	# Read Value in Memory if "^"
	if [ ${L_REMOTE_HOST}   != "^" ]; then REMOTE_HOST=${L_REMOTE_HOST};     fi
	if [ ${L_REMOTE_PORT}   != "^" ]; then REMOTE_PORT=${L_REMOTE_PORT};     fi
	if [ ${L_REMOTE_USER}   != "^" ]; then REMOTE_USER=${L_REMOTE_USER};     fi
	if [ ${L_LOCAL_HOST}    != "^" ]; then LOCAL_HOST=${L_LOCAL_HOST};       fi
	if [ ${L_LOCAL_PORT}    != "^" ]; then LOCAL_PORT=${L_LOCAL_PORT};       fi
	if [ ${L_LOCAL_USER}    != "^" ]; then LOCAL_USER=${L_LOCAL_USER};       fi
	if [ ${L_REMOTE_SETUP}  != "^" ]; then REMOTE_SETUP=${L_REMOTE_SETUP};   fi
	if [ ${L_LOCAL_OPEN}    != "^" ]; then LOCAL_OPEN=${L_LOCAL_OPEN};       fi
	if [ ${L_REMOTE_KILL}   != "^" ]; then REMOTE_KILL=${L_REMOTE_KILL};     fi
	if [ ${L_LOCAL_FWDHOST} != "^" ]; then LOCAL_FWDHOST=${L_LOCAL_FWDHOST}; fi
	if [ ${L_LOCAL_FWDPORT} != "^" ]; then LOCAL_FWDPORT=${L_LOCAL_FWDPORT}; fi
	if [ ${L_REMOTE_FWDPUB} != "^" ]; then REMOTE_FWDPUB=${L_REMOTE_FWDPUB}; fi
	# Option Selector
	if [ ${REMOTE_FWDPUB} -eq 1 ]; then EXTRA_OPT="${EXTRA_OPT} -L"; fi
	if [ ${REMOTE_SETUP} -eq 1 ]; then EXTRA_OPT="${EXTRA_OPT} -S"; fi
	if [ ${LOCAL_OPEN} -eq 1 ]; then EXTRA_OPT="${EXTRA_OPT} -R"; fi
	if [ ${REMOTE_KILL} -eq 1 ]; then EXTRA_OPT="${EXTRA_OPT} -K"; fi
	# Run Selector
	if   [ ${1} -eq 1 ] && [ ${#} -eq 1 ] && [ ${CONNECTION_STATUS} = "e" ]; then FORKER ${1}
	elif [ ${1} -eq 1 ] && [ ${#} -eq 2 ] && [ ${CONNECTION_STATUS} = "e" ] && [ ${CONNECTION_NAME} = "${2}" ]; then FORKER ${1}
	elif [ ${1} -eq 2 ] && [ ${#} -eq 1 ] && [ ${CONNECTION_STATUS} = "e" ]; then FORKER ${1}
	elif [ ${1} -eq 2 ] && [ ${#} -eq 2 ] && [ ${CONNECTION_NAME} = "${2}" ]; then FORKER ${1}; fi
fi
done < $PORT_LIST
}
# MAIN RUNTIME #########################################################################################################
echo "= LANTIS Router 3 - Academy City Research ========="
echo "[---------][$(date)][ OK ] System Ready"
if [ $# -lt 1 ]; then USAGE; exit 0; fi
DRY=0; PORT_LIST="./ports.lantis.csv"; LOG_FILE="./lantis.log"; TIME_LAUNCH_PAUSE=4; TIME_DROP_PAUSE=2
source ./lantis.config
while getopts "C:XLl:Kk:Z" opt; do 
  case $opt in
  	C) PORT_LIST="${OPTARG}";;
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