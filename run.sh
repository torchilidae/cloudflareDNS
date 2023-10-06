#!/bin/bash

# Cloudflare API credentials
ZONE_ID=${CF_ZONE_ID}
API_KEY=${CF_TOKEN}

# URL for Cloudflare API
API_URL="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"

# Function to update or create DNS record
update_or_create_dns_record() {
    local hostname="$1"
    local new_ip="$2"

    # Find the DNS record by hostname
    response=$(curl -s -X GET "${API_URL}?name=${hostname}&type=A" \
        -H "Authorization: Bearer ${CF_TOKEN}")

    record_id=$(echo "$response" | jq -r '.result[0].id')

    if [ -n "$record_id" ]; then
        # Update the existing DNS record with the new IP
        update_response=$(curl -s -X PUT "${API_URL}/${record_id}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${hostname}\",\"content\":\"${new_ip}\"}")

        if [ "$(echo "$update_response" | jq -r '.success')" == "true" ]; then
            echo "Successfully updated ${hostname} to ${new_ip}"
        else
            echo "Failed to update ${hostname}: $(echo "$update_response" | jq -r '.errors[0].message')"
        fi
    else
        # Create a new DNS record
        create_response=$(curl -s -X POST "${API_URL}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${hostname}\",\"content\":\"${new_ip}\"}")

        if [ "$(echo "$create_response" | jq -r '.success')" == "true" ]; then
            echo "Successfully created ${hostname} with IP ${new_ip}"
        else
            echo "Failed to create ${hostname}: $(echo "$create_response" | jq -r '.errors[0].message')"
        fi
    fi
}

# Load data from JSON file
input_file="records.json"
if [ -f "$input_file" ]; then
    data=$(cat "$input_file")

    # Iterate through records and update or create them
    for row in $(echo "${data}" | jq -c '.records[]'); do
        hostname=$(echo "$row" | jq -r '.hostname')
        new_ip=$(echo "$row" | jq -r '.new_ip')
        update_or_create_dns_record "$hostname" "$new_ip"
    done
else
    echo "Input JSON file not found: ${input_file}"
fi
