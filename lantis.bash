#!/bin/bash
# LANTIS EasyLink 2 #
# Stop if no options
RUN=0; DRY=0; PORT_LIST="ports.lantis.csv"
# Display Usage
USAGE(){
cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research
	
 support : help.lantis.project@acr.moe

 Usage:

 Remote Host ===========================================================
 -h  Host to connect to (IP Address or FQDN) (REQUIRED)
 -p  SSH Port (Default: 22)
 -u  User to login as (Default: root)

 Local Host ============================================================
 -P  SSH Port (Default: 65500)
 -U  User to login as (Default: root)

 Router ================================================================
 -H  Local Server (Default: 127.0.0.1)
 -a  Public Port 1   -A Server Port 1 (Default: 80)
 -b  Public Port 2   -B Server Port 2 (Default: 443)

 Extra Options =========================================================
 -K  Key to use for both directions (Default: lantis.key + .pub)
 -R  Use Reverse SSH Tunneling to bypass inbound NAT requirements. 
       Useful if you dont have access to the firewall or router.
 -K  Kill zombie SSH sessions to make way for this connection
 -S  Setup Remote Server
 -C  Source File to use
 -Z  Display Setup Guide

EOF
}
# Display Setup Guide
SETUPGUIDE(){
cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research
	
 support : help.lantis.project@acr.moe

 Setup Guide:

 1) Generate a SSH key in ~/.ssh/id_rsa
      [root@local]~ ssh-keygen –b 4086
 2) Add id_rsa.pub to /root /.ssh/authorized_keys on the remote server
 3) Generate a SSH key for LANTIS in your current directory where the script will stay
      [root@local]~/LANTIS ssh-keygen –b 4096 –f lantis.key
 4) Run this script with –S to auto-setup the remote server and any other options you need like -R
      [root@local]~/LANTIS lantis.bash –h 123.45.67.89 –S 
 5) You should be fine as long as your destination host allows your default ssh key
 6) Normaly use:
      [root@local]~/LANTIS nohup bash lantis.bash –h 123.45.67.89
      nohup: ignoring input and appending output to ‘nohup.out’
      [root@local]~/LANTIS tail nohup.out

EOF
}
# Parse Options
while getopts "RrKkXCZ" opt; do 
  case $opt in
	R) RUN=2;REQ_CONNECTION_NAME=${OPTARG};;
	r) RUN=1;;
	K) RUN=4;REQ_CONNECTION_NAME=${OPTARG};;
	k) RUN=3;;
	X) DRY=1;;
	C) PORT_LIST==${OPTARG};;
    Z) SETUPGUIDE; exit;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
# Display Usage with no options
if [ $# -lt 1 ]; then USAGE; exit; fi

WATCHDOG_GEN() {
while read in; do # For Each Connection #################################################
# e;test;remote.com;22;root;127.0.0.1;22;root;n;y;y;8989;192.168.0.2;8894;p

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
LOCAL_FWDPORT=$(echo $in | awk -F '[;]' '{print $14}')     #Server Local Port[int]
L_REMOTE_FWDPUB=$(echo $in | awk -F '[;]' '{print $15}')   #Public or Local[P or L]

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
if [ ${L_REMOTE_FWDPUB} != "^" ]; then REMOTE_FWDPUB=${L_REMOTE_FWDPUB}; fi

EXTRA_OPT=""
if [ ${REMOTE_FWDPUB} = "p" ]; then EXTRA_OPT="${EXTRA_OPT} -L"; fi
if [ ${REMOTE_SETUP} = "y" ]; then EXTRA_OPT="${EXTRA_OPT} -S"; fi
if [ ${LOCAL_OPEN} = "y" ]; then EXTRA_OPT="${EXTRA_OPT} -R"; fi
if [ ${REMOTE_KILL} = "y" ]; then EXTRA_OPT="${EXTRA_OPT} -K"; fi

if [ ${RUN} -eq 2 ] && [ ${CONNECTION_NAME} != "${REQ_CONNECTION_NAME}" ]; then CONNECTION_STATUS="s"; fi
if [ ${RUN} -eq 2 ] && [ ${CONNECTION_NAME} = "${REQ_CONNECTION_NAME}" ]; then CONNECTION_STATUS="e"; fi
if [ ${CONNECTION_STATUS} = "e" ]; then
echo "[${CONNECTION_NAME}][$(date)][INFO] Launching..."
if [ ${DRY} -eq 1 ]; then echo ">>>> -n ${CONNECTION_NAME} -h ${REMOTE_HOST} -p ${REMOTE_PORT} -u ${REMOTE_USER} \
-H ${LOCAL_HOST} -P ${LOCAL_PORT} -U ${LOCAL_USER} -D ${LOCAL_FWDHOST} -t ${REMOTE_FWDPORT} -T ${LOCAL_FWDPORT}${EXTRA_OPT}"
bash ./watchdog.lantis.bash -n ${CONNECTION_NAME} -h ${REMOTE_HOST} -p ${REMOTE_PORT} -u ${REMOTE_USER} \
-H ${LOCAL_HOST} -P ${LOCAL_PORT} -U ${LOCAL_USER} -D ${LOCAL_FWDHOST} -t ${REMOTE_FWDPORT} -T ${LOCAL_FWDPORT}${EXTRA_OPT} -X ${DRY};
else nohup bash ./watchdog.lantis.bash -n ${CONNECTION_NAME} -h ${REMOTE_HOST} -p ${REMOTE_PORT} -u ${REMOTE_USER} \
-H ${LOCAL_HOST} -P ${LOCAL_PORT} -U ${LOCAL_USER} -D ${LOCAL_FWDHOST} -t ${REMOTE_FWDPORT} -T ${LOCAL_FWDPORT}${EXTRA_OPT} & fi
sleep 7
elif [ ${CONNECTION_STATUS} = "d" ]; then
echo "[${CONNECTION_NAME}][$(date)][ERR!] DISABLED"
fi
done < ${PORT_LIST} # For Each Connection ########################################### 
}

cat << EOF
     __    ___    _   _________________
    / /   /   |  / | / /_  __/  _/ ___/
   / /   / /| | /  |/ / / /  / / \__ \ 
  / /___/ ___ |/ /|  / / / _/ / ___/ / 
 /_____/_/  |_/_/ |_/ /_/ /___//____/  
 Lain Anonymous NetworkIng System
 by : Academy City Research

EOF
echo "= LANTIS Router 3 - Academy City Research ========="
echo "[---------][$(date)][ OK ] System Ready"
if [ ${RUN} -eq 1 ]; then WATCHDOG_GEN;
elif [ ${RUN} -eq 2 ]; then WATCHDOG_GEN; fi
