#!/bin/bash

RATE=2
COUNT=10
DNS_SERVER="10.245.37.36"

usage() {
    echo "Usage: $0 domain_list_file source_ip [A|NAPTR]"
    exit 1
}

write_csv_header() {
    if [ "$QUERY_TYPE" == "A" ]; then
        echo "domain,query_number,answer_a,datetime" > "$OUT_FILE"
    else
        echo "domain,query_number,answer_naptr,datetime" > "$OUT_FILE"
    fi
}

get_a_answer() {
    local domain="$1"
    local src_ip="$2"
    local dns_server="$3"
    dig +short -b "$src_ip" @"$dns_server" "$domain" | paste -sd ";" -
}

get_naptr_answer() {
    local domain="$1"
    local src_ip="$2"
    local dns_server="$3"
    dig +short -b "$src_ip" @"$dns_server" "$domain" NAPTR | paste -sd ";" -
}

query_domain() {
    local domain="$1"
    local src_ip="$2"
    local dns_server="$3"
    local count="$4"
    for ((i=1; i<=count; i++)); do
        {
            local answer
            local datetime
            if [ "$QUERY_TYPE" == "A" ]; then
                answer=$(get_a_answer "$domain" "$src_ip" "$dns_server")
                datetime=$(date +"%Y-%m-%d %H:%M:%S")
                echo "\"$domain\",$i,\"$answer\",\"$datetime\"" >> "$OUT_FILE"
            else
                answer=$(get_naptr_answer "$domain" "$src_ip" "$dns_server")
                datetime=$(date +"%Y-%m-%d %H:%M:%S")
                echo "\"$domain\",$i,\"$answer\",\"$datetime\"" >> "$OUT_FILE"
            fi
        } &
        sleep $(awk "BEGIN {print 1/$RATE}")
    done
}

main() {
    if [ $# -lt 2 ] || [ $# -gt 3 ]; then
        usage
    fi

    DOMAIN_FILE="$1"
    SRC_IP="$2"
    QUERY_TYPE="${3:-A}"
    QUERY_TYPE=$(echo "$QUERY_TYPE" | tr '[:lower:]' '[:upper:]')

    if [ "$QUERY_TYPE" != "A" ] && [ "$QUERY_TYPE" != "NAPTR" ]; then
        echo "Invalid query type: $QUERY_TYPE. Use 'A' or 'NAPTR'."
        exit 1
    fi

    OUT_FILE=$(date +'%Y%m%d_%H%M%S')_DNS_out_file.txt

    write_csv_header

    while read -r DOMAIN; do
        [ -z "$DOMAIN" ] && continue
        query_domain "$DOMAIN" "$SRC_IP" "$DNS_SERVER" "$COUNT"
    done < "$DOMAIN_FILE"

    wait
}

main "$@"
