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

    # Check if new_ips is null or empty
    if [ -z "$new_ips" ]; then
        echo "No new IPs specified for ${hostname}. Skipping..."
        return
    fi

    # If new_ips is an array, iterate through it
    if [ "$(jq 'type' <<< "$new_ips")" == "array" ]; then
        for new_ip in $(echo "$new_ips" | jq -r '.[]'); do
            # Create or update each IP address
            create_or_update_response=$(curl -s -X POST "${API_URL}/${hostname}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"A\",\"name\":\"${hostname}\",\"content\":\"${new_ip}\"}")

            if [ "$(echo "$create_or_update_response" | jq -r '.success')" == "true" ]; then
                echo "Successfully created or updated ${hostname} with IP ${new_ip}"
            else
                echo "Failed to create or update ${hostname} with IP ${new_ip}: $(echo "$create_or_update_response" | jq -r '.errors[0].message')"
            fi
        done
    else
        # If new_ips is a single IP address, create or update it
        create_or_update_response=$(curl -s -X POST "${API_URL}/${hostname}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${hostname}\",\"content\":\"${new_ips}\"}")

        if [ "$(echo "$create_or_update_response" | jq -r '.success')" == "true" ]; then
            echo "Successfully created or updated ${hostname} with IP ${new_ips}"
        else
            echo "Failed to create or update ${hostname} with IP ${new_ips}: $(echo "$create_or_update_response" | jq -r '.errors[0].message')"
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
        new_ips=$(echo "$row" | jq -r '.new_ips')
        echo "Processing: hostname=${hostname}, new_ips=${new_ips}"
        update_or_create_dns_records "$hostname" "$new_ips"
    done
else
    echo "Input JSON file not found: ${input_file}"
fi
