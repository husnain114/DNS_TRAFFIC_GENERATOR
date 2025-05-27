#!/bin/bash

RATE=2
COUNT=10
SRC_IP="10.245.37.43"
DNS_SERVER="10.245.37.36"

if [ $# -ne 1 ]; then
    echo "Usage: $0 domain_list_file"
    exit 1
fi

DOMAIN_FILE="$1"

while read -r DOMAIN; do
    [ -z "$DOMAIN" ] && continue
    for ((i=1; i<=COUNT; i++)); do
        dig -b $SRC_IP @$DNS_SERVER $DOMAIN > /dev/null &
        sleep $(awk "BEGIN {print 1/$RATE}")
    done
done < "$DOMAIN_FILE"

wait
