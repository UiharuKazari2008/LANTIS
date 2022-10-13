#!/bin/bash
if [ $# -lt 1 ]; then echo "No Input Data"; exit 1; fi
# LANTIS EasyLink 4 #
# OPERATIONS ###########################################################################################################
TEST_HOST_VERIFY () { 
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Outbound End-Point: OK"
EOF
}
KEYEXCOMPLETED=0
KEY_EXCHANGE () {
if [ "${REMOTE_SETUP}" = "true" ]; then
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Passing Key to End-Point..."
  ${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT} -i ${SETUP_KEY} ${KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY_NAME:-lantis}.key
  ${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} << EOF
    if grep -Fxq "$(cat ${KEY}.pub)" ~/.ssh/authorized_keys
    then
      echo "LANTIS Key Present"
    else
      echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
    fi
EOF
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Passing Key to Local..."
  if [ ${LOCAL_HOST} = "~" ] || [ "${LOCAL_OPEN}" = "true" ]; then echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
  else
    ${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT} -i ${SETUP_KEY} ${KEY} ${LOCAL_USER}@${LOCAL_HOST}:${KEY_NAME:-lantis}.key
    ${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} << EOF
    if grep -Fxq "$(cat ${KEY}.pub)" ~/.ssh/authorized_keys
    then
      echo "LANTIS Key Present"
    else
      echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
    fi
EOF
  fi
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Key Exchange Complete"
  KEYEXCOMPLETED=1
fi
}
TEST_HOST_FAILED () { 
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Outbound End-Point: No Access"
KEY_EXCHANGE;
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
if [ ${KEYEXCOMPLETED} -eq 0 ]; then KEY_EXCHANGE; fi;
if [ "${LOCAL_OPEN}" = "true" ]; then # Use Reverse SSH Tunneling
	REMOTE_PFWD="-R ${REMOTE_LPORT:-65100}:127.0.0.1:${LOCAL_PORT:-22}"; LOCAL_HOST="127.0.0.1"; echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Reverse Conection will be used"
else # Use Direct Connection
	REMOTE_LPORT="${LOCAL_PORT:-22}"; REMOTE_PFWD="";	if [ ${LOCAL_HOST} = "~" ]; then LOCAL_HOST="$(curl ipinfo.io/ip 2> /dev/null)"; fi; fi
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][>>>] Establishing Control..." 
if [ ${DRY} -eq 1 ]; then echo "${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_LOCALPFWD} ${LOCAL_PORTPUB} ${REMOTE_PFWD} <<"; fi
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_LOCALPFWD} ${LOCAL_PORTPUB} ${REMOTE_PFWD} << EOF
	if [ ${1} = 1 ]; then
	  if [ ! -f "${KEY_NAME:-lantis}.key" ]; then echo "MISSING KEY" && exit 1; fi
		if [ "${REMOTE_KILL}" = "true" ]; then netstat -tlpn | grep ":${REMOTE_FWDPORT} " | sed -n 's@.* \([0-9]*\)/.*@kill \1@p' | sh > /dev/null; fi
		echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][<<<] Linked!"; pkill -f "^${CMD_SSH}.*${LOCAL_PFWD_LAST}$" > /dev/null
    ${CONNECT_REMOTE_COMMANDS:-}
		if [ ${DRY} -eq 1 ]; then echo "${LOCAL_USER}@${LOCAL_HOST}:${REMOTE_LPORT} -i ${KEY_NAME:-lantis}.key ${COMMON_OPT} ${LOCAL_OPT}${REMOTE_PORTPUB} ${LOCAL_PFWD}"; else
		${CMD_SSH} ${LOCAL_HOST} -l ${LOCAL_USER} -p ${REMOTE_LPORT} -i ${KEY_NAME:-lantis}.key ${COMMON_OPT} ${LOCAL_OPT}${REMOTE_PORTPUB} ${LOCAL_PFWD}; fi
		echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!][<<<] ETOL"
		${DROPPED_REMOTE_COMMANDS:-}
	elif [ ${1} = 2 ]; then
		echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][<<<] Dropping...!"
		${DISCONNECT_REMOTE_COMMANDS:-}
		if [ ${DRY} -eq 1 ]; then pgrep -f "^${CMD_SSH}.*${LOCAL_PFWD_LAST}$"; else pkill -f "^${CMD_SSH}.*${LOCAL_PFWD_LAST}$" > /dev/null; fi;
  fi
EOF
if [ ${DRY} -eq 1 ]; then exit 0; fi
}
# SET VARS #############################################################################################################
REMOTE_PORTPUB=""; LOCAL_PORTPUB=""; DRY=0; LOCAL_OPEN="false"; REMOTE_KILL="false"; REMOTE_SETUP="false"; LOOPCON=1; LOCAL_PFWD=""; REMOTE_LOCALPFWD=""; REMOTE_LPORT="22";
TIME_FAILED_CONN=2; TIME_FAILED_INET=5; TIMEOUT_VERIFY_INET=15; HOST_VERIFY="https://google.com"; DATE_FORMAT='+%d/%m/%Y %H:%M:%S'
CMD_SSH="ssh"; CMD_SCP="scp"; KEY=lantis.key; SETUP_KEY="$HOME/.ssh/id_rsa"; LOCAL_OPT="-N -o ExitOnForwardFailure=yes"; FILENAME="";
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
source ./.watchdog.lantis.config
# PARSE INPUT ##########################################################################################################
while getopts "m:c:n:X" opt; do
  case $opt in
  	X) DRY=1;;
  	m) OPER_MODE=${OPTARG};;
    n) CONNECTION_NAME=${OPTARG};;
    c) FILENAME="${OPTARG}";;
    \?) echo "This should not be used directly"; exit 1;;
    :) echo "This should not be used directly"; exit 1;;
  esac
done
# MAIN RUNTIME #########################################################################################################
source $FILENAME
# Port List Converter
if [ -n "${FORWARD_PORTS}" ]; then
  for _PORT_SET in ${FORWARD_PORTS}; do
    LOCAL_PFWD="${LOCAL_PFWD}-L ${_PORT_SET} ";
    LOCAL_PFWD_LAST=${_PORT_SET};
  done;
fi
if [ -n "${REVERSE_PORTS}" ] && [ "${2}" = "1" ]; then
  for _PORT_SET in ${REVERSE_PORTS}; do
    REMOTE_LOCALPFWD="${REMOTE_LOCALPFWD}-L ${_PORT_SET} ";
  done;
fi;

# Option Selector
if [ "${FORWARD_PUBLIC}" = "true" ]; then REMOTE_PORTPUB=" -g"; fi
if [ "${REVERSE_PUBLIC}" = "true" ] && [ "${2}" = "1" ]; then LOCAL_PORTPUB=" -g"; fi

# Unique Generate Key Name
KEY_NAME="$(cat ${KEY}.pub | md5sum | awk '{print $1}')"
echo "Key Name: ${KEY_NAME:-lantis}"

echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] DATA LOADED"
while [ ${LOOPCON} -eq 1 ]; do
	while [ -f ./.stat.inet ]; do sleep 2; done
	if TEST_INET_VERIFY; then TEST_INET_PASSED
		{ TEST_HOST_VERIFY 
		} || { TEST_HOST_FAILED 
		}; LINK ${OPER_MODE}; if [ ${OPER_MODE} -eq 2 ]; then LOOPCON=0; fi
	else TEST_INET_FAILED; fi; TEST_CONN_FAILED
done
