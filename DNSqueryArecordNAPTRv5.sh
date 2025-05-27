#!/bin/bash

RATE=2
COUNT=10

usage() {
    echo "Usage: $0 domain_list_file source_ip dns_server_list_file [A|NAPTR]"
    exit 1
}

cleanup() {
    ls -1t *_DNS_out_file.txt 2>/dev/null | tail -n +3 | xargs -r rm --
}

write_csv_header() {
    if [ "$QUERY_TYPE" == "A" ]; then
        echo "domain,dns_server,query_number,answer_a,datetime" > "$OUT_FILE"
    else
        echo "domain,dns_server,query_number,answer_naptr,datetime" > "$OUT_FILE"
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
                echo "\"$domain\",\"$dns_server\",$i,\"$answer\",\"$datetime\"" >> "$OUT_FILE"
            else
                answer=$(get_naptr_answer "$domain" "$src_ip" "$dns_server")
                datetime=$(date +"%Y-%m-%d %H:%M:%S")
                echo "\"$domain\",\"$dns_server\",$i,\"$answer\",\"$datetime\"" >> "$OUT_FILE"
            fi
        } &
        sleep $(awk "BEGIN {print 1/$RATE}")
    done
}

main() {
    if [ $# -lt 3 ] || [ $# -gt 4 ]; then
        usage
    fi

    DOMAIN_FILE="$1"
    SRC_IP="$2"
    DNS_SERVER_FILE="$3"
    QUERY_TYPE="${4:-A}"
    QUERY_TYPE=$(echo "$QUERY_TYPE" | tr '[:lower:]' '[:upper:]')

    if [ "$QUERY_TYPE" != "A" ] && [ "$QUERY_TYPE" != "NAPTR" ]; then
        echo "Invalid query type: $QUERY_TYPE. Use 'A' or 'NAPTR'."
        exit 1
    fi

    OUT_FILE=$(date +'%Y%m%d_%H%M%S')_DNS_out_file.txt

    write_csv_header

    while read -r DOMAIN; do
        [ -z "$DOMAIN" ] && continue
        while read -r DNS_SERVER; do
            [ -z "$DNS_SERVER" ] && continue
            query_domain "$DOMAIN" "$SRC_IP" "$DNS_SERVER" "$COUNT"
        done < "$DNS_SERVER_FILE"
    done < "$DOMAIN_FILE"

    cleanup
    wait
}

main "$@"
