#!/bin/bash
if [ $# -lt 1 ]; then echo "No Input Data"; exit 1; fi
# LANTIS EasyLink 4 #
# OPERATIONS ###########################################################################################################
TEST_HOST_VERIFY () { 
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Outbound End-Point: OK"
EOF
}
KEY_EXCHANGE () {
if [ ${REMOTE_SETUP} -eq 1 ]; then
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Passing Key to End-Point..."
  ${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT} ${SETUP_KEY} ${REMOTE_USER}@${REMOTE_HOST}:${KEY}
  ${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${SETUP_KEY} ${COMMON_OPT} << EOF
    if grep -Fxq "$(cat ${KEY}.pub)" ~/.ssh/authorized_keys
    then
      echo "LANTIS Key Present"
    else
      echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
    fi
EOF
  echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Passing Key to Local..."
  if [ ${LOCAL_HOST} = "~" ] || [ ${LOCAL_OPEN} -eq 0 ]; then echo "$(cat ${KEY}.pub)" >> ~/.ssh/authorized_keys
  else
    ${CMD_SCP} ${COMMON_OPT} -o Port=${REMOTE_PORT} ${SETUP_KEY} ${LOCAL_USER}@${LOCAL_HOST}:${KEY}
    ${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${SETUP_KEY} ${COMMON_OPT} << EOF
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
if [ ${LOCAL_OPEN} -eq 0 ]; then # Use Reverse SSH Tunneling
	REMOTE_PFWD="-R ${REMOTE_LPORT:-65100}:127.0.0.1:${LOCAL_PORT:-22}"; LOCAL_HOST="127.0.0.1"; echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Reverse Conection will be used"
elif [ ${LOCAL_OPEN} -eq 1 ]; then # Use Direct Connection
	REMOTE_LPORT="${LOCAL_PORT:-22}"; REMOTE_PFWD="";	if [ ${LOCAL_HOST} = "~" ]; then LOCAL_HOST="$(curl ipinfo.io/ip 2> /dev/null)"; fi; fi
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][>>>] Establishing Control..." 
echo "${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_LOCALPFWD} ${LOCAL_PORTPUB} ${REMOTE_PFWD} <<"
${CMD_SSH} ${REMOTE_HOST} -l ${REMOTE_USER} -p ${REMOTE_PORT} -i ${KEY} ${COMMON_OPT} ${REMOTE_LOCALPFWD} ${LOCAL_PORTPUB} ${REMOTE_PFWD} << EOF
	if [ ${1} = 1 ]; then
	  if [ ! -f "${KEY}" ]; then echo "MISSING KEY" && exit 1; fi
		if [ ${REMOTE_KILL} -eq 1 ]; then netstat -tlpn | grep ":${REMOTE_FWDPORT} " | sed -n 's@.* \([0-9]*\)/.*@kill \1@p' | sh > /dev/null; fi
		echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][<<<] Linked!"; pkill -f "^${CMD_SSH}.*${LOCAL_PFWD_LAST}$" > /dev/null
		echo "${LOCAL_USER}@${LOCAL_HOST}:${REMOTE_LPORT} -i ${KEY} ${COMMON_OPT} ${LOCAL_OPT}${REMOTE_PORTPUB} ${LOCAL_PFWD}"
		if [ ${DRY} -eq 0 ]; then ${CMD_SSH} ${LOCAL_HOST} -l ${LOCAL_USER} -p ${REMOTE_LPORT} -i ${KEY} ${COMMON_OPT} ${LOCAL_OPT}${REMOTE_PORTPUB} ${LOCAL_PFWD}; fi
		echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!][<<<] ETOL"
	elif [ ${1} = 2 ]; then
		echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO][<<<] Dropping...!"
		if [ ${DRY} -eq 1 ]; then pgrep -f "^${CMD_SSH}.*${LOCAL_PFWD_LAST}$"; else pkill -f "^${CMD_SSH}.*${LOCAL_PFWD_LAST}$" > /dev/null; fi; fi
EOF
if [ ${DRY} -eq 1 ]; then exit 0; fi
}
# SET VARS #############################################################################################################
REMOTE_PORTPUB=""; LOCAL_PORTPUB=""; DRY=0; LOCAL_OPEN=1; REMOTE_KILL=0; REMOTE_SETUP=0; LOOPCON=1; LOCAL_PFWD=""; REMOTE_LOCALPFWD=""; REMOTE_LPORT="22";
TIME_FAILED_CONN=2; TIME_FAILED_INET=5; TIMEOUT_VERIFY_INET=15; HOST_VERIFY="https://google.com"; DATE_FORMAT='+%d/%m/%Y %H:%M:%S'
CMD_SSH="ssh"; CMD_SCP="scp"; KEY=lantis.key; SETUP_KEY="$HOME/.ssh/id_rsa"; LOCAL_OPT="-N -o ExitOnForwardFailure=yes"
COMMON_OPT="-C -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
source ./.watchdog.lantis.config
# PARSE INPUT ##########################################################################################################
while getopts "m:n:h:p:q:u:H:P:U:D:d:LlSRKX" opt; do
  case $opt in
  	m) OPER_MODE=${OPTARG};;
    n) CONNECTION_NAME=${OPTARG};;
    h) REMOTE_HOST=${OPTARG};;
    p) REMOTE_PORT=${OPTARG};;
    u) REMOTE_USER=${OPTARG};;
    H) LOCAL_HOST=${OPTARG};;
    P) LOCAL_PORT=${OPTARG};;
    q) REMOTE_LPORT=${OPTARG};;
    U) LOCAL_USER=${OPTARG};;
    D) LOCAL_PFWD="${LOCAL_PFWD}-L ${OPTARG} "; LOCAL_PFWD_LAST=${OPTARG};;
    d) REMOTE_LOCALPFWD="${REMOTE_LOCALPFWD}-L ${OPTARG} "; REMOTE_LOCALPFWD_LAST=${OPTARG};;
    L) REMOTE_PORTPUB=" -g";;
    l) LOCAL_PORTPUB=" -g";;
    S) REMOTE_SETUP=1;;
    R) LOCAL_OPEN=0;;
    K) REMOTE_KILL=1;;
    X) DRY=1;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done
# MAIN RUNTIME #########################################################################################################
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] DATA LOADED"
while [ ${LOOPCON} -eq 1 ]; do
	while [ -f ./.stat.inet ]; do sleep 2; done
	if TEST_INET_VERIFY; then TEST_INET_PASSED
		{ TEST_HOST_VERIFY 
		} || { TEST_HOST_FAILED 
		}; LINK ${OPER_MODE}; if [ ${OPER_MODE} -eq 2 ]; then LOOPCON=0; fi
	else TEST_INET_FAILED; fi; TEST_CONN_FAILED
done
