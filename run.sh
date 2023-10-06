#!/bin/bash

# Cloudflare API credentials
ZONE_ID=${CF_ZONE_ID}
API_KEY=${CF_TOKEN}

# URL for Cloudflare API
API_URL="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"

# Function to update or create DNS records for a hostname
update_or_create_dns_records() {
    local hostname="$1"
    local new_ips="$2"

    # Find the DNS records by hostname
    response=$(curl -s -X GET "${API_URL}?name=${hostname}&type=A" \
        -H "Authorization: Bearer ${CF_TOKEN}")

    record_ids=$(echo "$response" | jq -r '.result[].id')

    # Delete existing DNS records
    for record_id in $record_ids; do
        delete_response=$(curl -s -X DELETE "${API_URL}/${record_id}" \
            -H "Authorization: Bearer ${CF_TOKEN}")
    done

    # Create new DNS records with the new IPs
    for new_ip in ${new_ips[@]}; do
        create_response=$(curl -s -X POST "${API_URL}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${hostname}\",\"content\":\"${new_ip}\"}")

        if [ "$(echo "$create_response" | jq -r '.success')" == "true" ]; then
            echo "Successfully created ${hostname} with IP ${new_ip}"
        else
            echo "Failed to create ${hostname} with IP ${new_ip}: $(echo "$create_response" | jq -r '.errors[0].message')"
        fi
    done
}

# Load data from JSON file
input_file="records.json"
if [ -f "$input_file" ]; then
    data=$(cat "$input_file")

    # Iterate through records and update or create them
    for row in $(echo "${data}" | jq -c '.records[]'); do
        hostname=$(echo "$row" | jq -r '.hostname')
        new_ips=$(echo "$row" | jq -r '.new_ips[]')
        update_or_create_dns_records "$hostname" "$new_ips"
    done
else
    echo "Input JSON file not found: ${input_file}"
fi
