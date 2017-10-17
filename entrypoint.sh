#!/bin/bash

MYSQL_SERVER=${MYSQL_SERVER:-mysql}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_SCHEMA=${MYSQL_SCHEMA:-pdns}
MYSQL_USER=${MYSQL_USER:-pdns}
MYSQL_PASSWD=${MYSQL_PASSWD:-pdns}
API_KEY=${API_KEY:-genericapikey}
MASTER=${MASTER:-yes}
SLAVE=${SLAVE:-no}
SLAVE_CYCLE_INTERVAL=${SLAVE_CYCLE_INTERVAL:-60}
DEFAULT_TTL=${DEFAULT_TTL:-3600}
DEFAULT_SOA_NAME=${DEFAULT_SOA_NAME:-$(hostname -f)}
DEFAULT_SOA_MAIL=${DEFAULT_SOA_MAIL}
ALLOW_AXFR_IPS=${ALLOW_AXFR_IPS:-127.0.0.0/8}
ALSO_NOTIFY=${ALSO_NOTIFY}
ALLOW_NOTIFY_FROM=${ALLOW_NOTIFY_FROM}

OPTIONS=()
OPTIONS+="--api=yes "
OPTIONS+="--api-key=${API_KEY} "
OPTIONS+="--webserver=yes "
OPTIONS+="--webserver-address=0.0.0.0 "
OPTIONS+="--launch=gmysql "
OPTIONS+="--gmysql-host=${MYSQL_SERVER} "
OPTIONS+="--gmysql-port=${MYSQL_PORT} "
OPTIONS+="--gmysql-user=${MYSQL_USER} "
OPTIONS+="--gmysql-dbname=${MYSQL_SCHEMA} "
OPTIONS+="--gmysql-password=${MYSQL_PASSWD} "
OPTIONS+="--default-ttl=${DEFAULT_TTL} "
OPTIONS+="--default-soa-name=${DEFAULT_SOA_NAME} "
OPTIONS+="--allow-axfr-ips=${ALLOW_AXFR_IPS} "
OPTIONS+="--slave-cycle-interval=${SLAVE_CYCLE_INTERVAL} "

# Master/Slave management
if [[ ${SLAVE} == "yes" ]]
then
  OPTIONS+="--slave=${SLAVE} "

  # ALLOW_NOTIFY_FROM must be set
  if [[ -z ${ALLOW_NOTIFY_FROM} ]]; then
    echo "ALLOW_NOTIFY_FROM is not set, please configure this when to turn slave mode on."
    exit 1
  fi

  OPTIONS+="--allow-notify-from=${ALLOW_NOTIFY_FROM} "

elif [[ ${MASTER} == "yes" ]]
then
  OPTIONS+="--master=${MASTER} "
else
  echo "Error, PowerDNS must be configured in either master or slave mode"
  exit 1
fi

# also-notify
if [[ -n ${ALSO_NOTIFY} ]]
then
  OPTIONS+="--also-notify=$ALSO_NOTIFY "
fi

# default-soa-email
if [[ -n ${DEFAULT_SOA_MAIL} ]]; then
  OPTIONS+="--default-soa-mail=${DEFAULT_SOA_MAIL} "
fi

# Check if the DB exist
# Create the DNS
# Create the tables

# Start PowerDNS
#export MYSQL_PWD=pdns
RESULT=$(mysql -u pdns -h ${MYSQL_SERVER} -p${MYSQL_PASSWD} -N -B -e 'use pdns; show tables' | wc -l)
echo "Number of detected tables: ${RESULT}"
#if 0 then init DB
#if 1 then let it go

if [[ ${RESULT} == 0 ]]
then
  echo "Database is not set"
  echo "Init DB"
  mysql -u ${MYSQL_USER} -p${MYSQL_PASSWD} -h ${MYSQL_SERVER} < init.sql
else
  echo "Database exist and some tables were found."
  echo "Assuming this is not the first launch"
fi

pdns_server ${OPTIONS}
