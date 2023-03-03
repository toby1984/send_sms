#!/bin/bash

#
# Script to send an SMS to my mobile using www.smsflatrate.de
#
# (C) 2023 tobias.gierke@code-sourcery.de
# last update: 2023-03-03

# message to send
# Zabbix uses 
# $1 - TO (must a be an international subscriber number)
# $2 - SUBJECT
# $3 - BODY

# Base directory
BASEDIR="/home/zabbix"

# send at most 1 SMS every 60 minutes
RATE_LIMIT_SECONDS="1800" 

# Debug/Dry-run mode is turned on when flag is != 0
DEBUG="0"

# SMS gateway API key
API_KEY=""

if [ "$#" -lt "2" ] ; then
  echo "ERROR: Invalid command.line"
  echo "Usage: <intl. subscriber number> <message>"
  exit 1
fi

TO="$1"
FROM=""
export MESSAGE="$2"

# truncate to fit into one SMS
export PREFIX=""
MESSAGE=`echo "${PREFIX}${MESSAGE}" | /usr/bin/sed 's/\(.\{155\}\).*/\1.../'`

# Zabbix message types will be invoked in parallel when
# multiple triggers using the message type fire around the same time
# 
export LOCKFILE="${BASEDIR}/.${TO}.sms_lock"
DROP_COUNTER_FILE="${BASEDIR}/dropped_sms.${TO}"

# File to store timestamp of last invocation
TS_FILE="${BASEDIR}/last_sms_timestamp.${TO}"

# URL-encode parameters
if [ -z "$TO" -o -z "$FROM" -o -z "$MESSAGE" -o -z "$API_KEY" ] ; then
  echo "ERROR: Required parameters are missing."
  exit 1
fi

MESSAGE=`/usr/bin/urlencode "${MESSAGE}"`
FROM=`/usr/bin/urlencode "${FROM}"`
TO=`/usr/bin/urlencode "${TO}"`

function releaseLock() {
    rm -f "$LOCKFILE"
    trap - INT TERM EXIT
}

function logDebug() {
  if [ "$DEBUG" != "0" ] ; then
     echo "DEBUG: $1" 
  fi
}

LOCK_COUNTER="10"

logDebug "Acquiring lock $LOCKFILE"
until ( set -o noclobber; echo "$$" > "$LOCKFILE" ) 2>/dev/null ; do
  logDebug "Waiting for lock file...retries left: $LOCK_COUNTER"
  LOCK_COUNTER=$(( $LOCK_COUNTER - 1 ))
  if [ "$LOCK_COUNTER" == "0" ] ; then
    echo "ERROR: Failed to acquire atomic lock ${LOCKFILE} too many times, giving up."
    exit 1
  fi
  sleep 1
done
# make sure lock gets cleaned up if we crash
trap 'rm -f "$LOCKFILE"; exit $?' INT TERM EXIT
logDebug "Acquired lock"

# =====================
# Begin of critical section: check invocation rate & maybe increase drop counter
# =====================

timestamp=`/usr/bin/date +%s`
if [ -e $TS_FILE ] ; then
  lastTimestamp=`cat $TS_FILE`
  delta=$(( $timestamp - $lastTimestamp ))
  if [ "$delta" -lt "$RATE_LIMIT_SECONDS"  ] ; then
    dropCount="1"	  
    if [ -e $DROP_COUNTER_FILE ] ; then
      dropCount=`cat $DROP_COUNTER_FILE`
      dropCount=$(( $dropCount + 1 ))
    fi
    echo $dropCount  >$DROP_COUNTER_FILE
    echo "ERROR: Rate limit exceeded. Dropped SMS so far: $dropCount"
    releaseLock
    exit 1
  fi
  logDebug "Rate limit not exceeded."
  if [ -e $DROP_COUNTER_FILE ] ; then
    rm $DROP_COUNTER_FILE
  fi
fi
echo $timestamp >$TS_FILE
releaseLock

# =======================
# End of critical section
# =======================
    
# send SMS
export url="https://www.smsflatrate.net/schnittstelle.php?key=${API_KEY}&from=${FROM}&to=${TO}&text=${MESSAGE}&type=1"

if [ "$DEBUG" == "0" ] ; then
  result=`/usr/bin/curl --no-progress-meter "$url"`
  if [ "$result" != "100" ] ; then
  	echo "ERROR: API responded with $result"
  	exit 1
  fi
else
  echo "DEBUG: Using URL $url"
  echo "DEBUG: Debug-mode turned on, will not perform API call."
fi

exit 0
