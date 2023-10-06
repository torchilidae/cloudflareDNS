#!/bin/bash

# Your Cloudflare API credentials
ACCOUNT_ID=${CF_ACCOUNT_ID}
ZONE_ID=${CF_ZONE_ID}
API_KEY=${CF_TOKEN}

echo ${CF_ZONE_ID}
echo $CF_ZONE_ID

curl 'https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A' --header 'Authorization:  Bearer ${CF_TOKEN}'