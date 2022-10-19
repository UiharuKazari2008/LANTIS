#!/bin/bash
if [ $# -lt 1 ]; then echo "No Input Data"; exit 1; fi
# LANTIS EasyLink 4 #
# OPERATIONS ###########################################################################################################
TEST_HOST_VERIFY () { 
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER:-root} -p ${REMOTE_PORT:-22} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Outbound End-Point: OK"
EOF
}
KEY_EXCHANGE () {
if [ "${REMOTE_SETUP}" = "true" ]; then
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Passing Key to End-Point..."
  ${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT:-22} -i ${SETUP_KEY} ${KEY} ${REMOTE_USER:-root}@${REMOTE_HOST}:${KEY_NAME:-lantis}.key
  ${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER:-root} -p ${REMOTE_PORT:-22} -i ${SETUP_KEY} ${COMMON_OPT} << EOF
    if grep -Fxq "$(cat ${KEY}.pub)" ~/.ssh/authorized_keys
    then
      echo "LANTIS Key Present"
    else
      echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
    fi
EOF
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Passing Key to Source..."
  if [ "${LOCAL_HOST:-127.0.0.1}" = "127.0.0.2" ] || [ "${LOCAL_HOST:-127.0.0.1}" = "localhost" ]; then
    echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
  else
    ${CMD_SCP} ${COMMON_OPT} -o Port=${LOCAL_PORT:-22} -i ${SETUP_KEY} ${KEY} ${LOCAL_USER:-root}@${LOCAL_HOST:-127.0.0.1}:${KEY_NAME:-lantis}.key
    ${CMD_SSH} ${LOCAL_HOST:-127.0.0.1} -l ${LOCAL_USER:-root} -p ${LOCAL_PORT:-22} -i ${SETUP_KEY} ${COMMON_OPT} << EOF
    if grep -Fxq "$(cat ${KEY}.pub)" ~/.ssh/authorized_keys
    then
      echo "LANTIS Key Present"
    else
      echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
    fi
EOF
  fi
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Key Exchange Complete"
fi
}
TEST_HOST_FAILED () { 
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Outbound End-Point: No Access"
KEY_EXCHANGE;
CONNFAILED=1
}
TEST_INET_VERIFY () {
wget -q --spider ${HOST_VERIFY} --timeout=${TIMEOUT_VERIFY_INET}
}
TEST_INET_PASSED () {
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Internet Connection: OK"
}
TEST_INET_FAILED () {
if [ ! -f ./.stat.inet ]; then 
	echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Internet Connection: Failed"; echo > ./.stat.inet
	while [ -f ./.stat.inet ]; do
		if TEST_INET_VERIFY; then TEST_INET_PASSED; rm ./.stat.inet; else sleep ${TIME_FAILED_INET}; fi
	done
fi
}
TEST_CONN_FAILED () {
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Connection was lost!"
sleep ${TIME_FAILED_CONN}
}
LINK () {
KEY_EXCHANGE;
if [ "${LOCAL_OPEN}" = "true" ]; then
  # Use Reverse SSH Tunneling
	REMOTE_PFWD="-R ${REMOTE_LPORT:-65100}:127.0.0.1:${LOCAL_PORT:-22}";
	LOCAL_HOST="127.0.0.1";
	echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Reverse Loopback Connection will be used"
else
  # Use Direct Connection
	REMOTE_PFWD="";
	REMOTE_LPORT="${LOCAL_PORT:-22}";
	if [ ${LOCAL_HOST:-127.0.0.1} = "~" ]; then
	  LOCAL_HOST="$(curl ipinfo.io/ip 2> /dev/null)";
	fi;
fi

echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][>>>] Establishing Remote Master Control..."
#if [ ${DRY} -eq 1 ]; then echo "${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER:-root} -p ${REMOTE_PORT:-22} -i ${KEY} -M ${COMMON_OPT} ${REMOTE_LOCALPFWD} ${LOCAL_PORTPUB} ${REMOTE_PFWD} <<"; fi

CONNECTION_COMMAND="${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER:-root} -p ${REMOTE_PORT:-22} -i ${KEY} ${COMMON_OPT} \
-o ControlMaster=auto -o ControlPath=${LOCAL_CONTROLMASTER_INTERFACE:-.LANTIS}_${CONNECTION_NAME}"
if [ ${1} = 1 ]; then
  pkill -f "^bash ./.port-mapper.lantis.bash \"${1}\"$"
  bash ./.port-mapper.lantis.bash "${1}" >> "${LOG_FILE}" &
  ${CONNECTION_COMMAND} ${LOCAL_PORTPUB} ${REMOTE_PFWD} << "EOL"
  if [ ! -f "${KEY_NAME:-lantis}.key" ]; then echo \"MISSING KEY\" && exit 1; fi
  pkill -f "^${CMD_SSH}.*${REMOTE_LPORT}$" > /dev/null
  echo "[${CONNECTION_NAME}][$(date ${DATE_FORMAT})][INFO][<<<] Linked!"
  ${CONNECT_REMOTE_COMMANDS:-}
  if [ "${DISABLE_LOCAL_LINK:-false}" == "false" ]; then
  ${CMD_SSH} ${LOCAL_HOST:-127.0.0.1} -l ${LOCAL_USER:-root} -p ${REMOTE_LPORT} -i ${KEY_NAME:-lantis}.key ${COMMON_OPT} \
    -o ControlMaster=auto \
    -o ControlPath=${LOCAL_CONTROLMASTER_INTERFACE:-.LANTIS}_${CONNECTION_NAME} \
    ${LOCAL_OPT}${REMOTE_PORTPUB} &;
  fi;
  echo "[${CONNECTION_NAME}][$(date ${DATE_FORMAT})][ERR!][<<<] ETOL";
  ${DROPPED_REMOTE_COMMANDS:-}
EOL
else
  pkill -f "^bash ./.port-mapper.lantis.bash \"${1}\"$"
  ${CONNECTION_COMMAND} << "EOF"
  pkill -f "^$${CMD_SSH} ${LOCAL_HOST:-127.0.0.1} -l ${LOCAL_USER:-root} -p ${REMOTE_LPORT} -i ${KEY_NAME:-lantis}.key.$" > /dev/null;
EOF
fi

if [ ${DRY} -eq 1 ]; then exit 0; fi
}
# SET VARS #############################################################################################################
REMOTE_PORTPUB=""; LOCAL_PORTPUB=""; DRY=0; LOCAL_OPEN="false"; REMOTE_KILL="false"; REMOTE_SETUP="false"; LOOPCON=1; LOCAL_PFWD=""; REMOTE_LOCALPFWD=""; REMOTE_LPORT="22";
TIME_FAILED_CONN=2; TIME_FAILED_INET=5; TIMEOUT_VERIFY_INET=15; HOST_VERIFY="https://google.com"; DATE_FORMAT='+%d/%m/%Y %H:%M:%S'
CMD_SSH="ssh"; CMD_SCP="scp"; KEY=lantis.key; SETUP_KEY="$HOME/.ssh/id_rsa"; LOCAL_OPT="-N -o ExitOnForwardFailure=yes"; FILENAME="";
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
LOCAL_CONTROLMASTER_INTERFACE=".LANTIS_INTERFACE"; REMOTE_CONTROLMASTER_INTERFACE=".LANTIS_INTERFACE";
source ./.lantis.config
source ./.watchdog.lantis.config
# PARSE INPUT ##########################################################################################################
while getopts "m:c:n:X:" opt; do
  case $opt in
  	X) DRY=${OPTARG};;
  	m) OPER_MODE=${OPTARG};;
    n) CONNECTION_NAME=${OPTARG};;
    c) FILENAME="${OPTARG}";;
    \?) echo "This should not be used directly"; exit 1;;
    :) echo "This should not be used directly"; exit 1;;
  esac
done
# MAIN RUNTIME #########################################################################################################
READ_FILE() {
  # Option Selector
  if [ "${FORWARD_PUBLIC}" = "true" ]; then REMOTE_PORTPUB=" -g"; fi
  if [ "${REVERSE_PUBLIC}" = "true" ] && [ "${1}" = "1" ]; then LOCAL_PORTPUB=" -g"; fi

  # Unique Generate Key Name
  KEY_NAME="$(cat ${KEY}.pub | md5sum | awk '{print $1}')"
  echo "Key Name: ${KEY_NAME:-lantis}"
}
source $FILENAME
READ_FILE ${2};

while [ ${LOOPCON} -eq 1 ]; do
	while [ -f ./.stat.inet ]; do sleep 2; done
	if TEST_INET_VERIFY; then TEST_INET_PASSED
		{ TEST_HOST_VERIFY 
		} || { TEST_HOST_FAILED 
		}; LINK ${OPER_MODE}; if [ ${OPER_MODE} -eq 2 ]; then LOOPCON=0; fi
	else TEST_INET_FAILED; fi; TEST_CONN_FAILED
done
