#!/bin/sh

# CloudFlare DDNS Universal Updater v0.1.1
# Script written by Adrian Van (adrian.van@ultimatelair.com)
# Adapted from scripts written by...
#   * alphabt for ASUSWRT-Merlin [https://github.com/alphabt/asuswrt-merlin-ddns-cloudflare]
#   * insistant-afk for Synology DSM [https://github.com/insistent-afk/cloudflare-ddns-for-synology]
#
# What's different/unique...
#   * Truly universal and doesn't require the Bourne Again SHell (BASH)
#   * Doesn't require python for parsing returned JSON output instead relies on jq
#   * Doesn't require a login email and password but instead uses the API TOKEN
#   * A single script to update both A and AAAA records
#   * Uses an external service to determine the public facing IPv4 and IPv6 addresses
#   * Automatically determines if IPv6 records need updating by detecting GUA IPv6

# Basic Information MUST be filled out
API_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # CF API Token
ZONE_ID="00000000000000000000000000000000"	      # CF zone (hex16) ID
RECORD_NAME="sub.domain-name.tld"		      # DNS record name, e.g. sub.example.com
RECORD_TTL="1"					      # TTL in seconds (1=auto)

# Web services used to detect Public Facing IPv4 & IPv6 respectively.
IPv4_QUERY_SITE="https://api.ipify.org"		     # Site used to obtain public IPv4
IPv6_QUERY_SITE="https://api6.ipify.org"	     # Site used to obtain public IPv6

# Actual Code Starts Here DO NOT EDIT BELOW THIS LINE!
Get_DNS_Record_Info() {
  local record_name=$1
  local type=$2
  local api_token=$3
  local zone_id=$4

  local record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${type}&name=${record_name}" -H "Authorization: Bearer ${api_token}" -H "Content-Type:application/json")

  echo $record_info
}

Update_DNS_Record() {
  local record_name=$1
  local record_id=$2
  local type=$3
  local ip=$4
  local record_ttl=$5
  local api_token=$6
  local zone_id=$7

  local output=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" -H "Authorization: Bearer ${api_token}" -H "Content-Type: application/json" --data "{\"type\":\"${type}\",\"name\":\"${record_name}\",\"content\":\"${ip}\",\"ttl\":${record_ttl},\"proxied\":false}" | jq -r ".success")

  echo $output
}

# Environment Check - Running on ASUSWRT-Merlin?
ASUSWRT=false
if [ $(uname -o) = "ASUSWRT-Merlin" ]; then
  ASUSWRT=true
fi

# Sanity Check - Is CloudFlare accessible with given tokens?
SANITY_CHECK_CF=$(Get_DNS_Record_Info $RECORD_NAME A $API_TOKEN $ZONE_ID | jq -r ".success")

if [ $SANITY_CHECK_CF != "true" ]; then
  if [ $ASUSWRT = "true" ]; then
    /sbin/ddns_custom_updated 0
  fi
  logger -t ddns -p user.warning "Authentication Failed! Check API Token/Zone ID/Record Name/Internet Connection."
  echo "badauth"
  exit 1;
fi

# Get Public facing IPv4 & IPv6
IPv4=$(curl -fs4 $IPv4_QUERY_SITE)
IPv6=$(curl -fs6 $IPv6_QUERY_SITE)

# Get Current IPv4 Info from CloudFlare
IPv4_RECORD_INFO=$(Get_DNS_Record_Info $RECORD_NAME A $API_TOKEN $ZONE_ID)
IPv4_RECORD_ID=$(echo $IPv4_RECORD_INFO | jq -r ".result[0].id")
IPv4_RECORD_IP=$(echo $IPv4_RECORD_INFO | jq -r ".result[0].content")

# If the IPv6 query returns an address assume the need to update IPv4 & IPv6
if [ $IPv6 != "" ]; then
  # Get Current IPv6 Info from CloudFlare
  IPv6_RECORD_INFO=$(Get_DNS_Record_Info $RECORD_NAME AAAA $API_TOKEN $ZONE_ID)
  IPv6_RECORD_ID=$(echo $IPv6_RECORD_INFO | jq -r ".result[0].id")
  IPv6_RECORD_IP=$(echo $IPv6_RECORD_INFO | jq -r ".result[0].content")

  # Check to see if any changes to the IP addresses for the records
  if [ $IPv4 = $IPv4_RECORD_IP ] && [ $IPv6 = $IPv6_RECORD_IP ]; then
    if [ $ASUSWRT = "true" ]; then
      /sbin/ddns_custom_updated 1
    fi
    logger -t ddns -p user.info "No IP change detected, no DNS update required."
    echo "nochg";
    exit 0;
  else
  # Otherwise update the records accordingly
    RESPONSE_IPv4=$(Update_DNS_Record $RECORD_NAME $IPv4_RECORD_ID A $IPv4 $RECORD_TTL $API_TOKEN $ZONE_ID)
    RESPONSE_IPv6=$(Update_DNS_Record $RECORD_NAME $IPv6_RECORD_ID AAAA $IPv6 $RECORD_TTL $API_TOKEN $ZONE_ID)

    if [ $RESPONSE_IPv4 = "true" ]; then
      logger -t ddns -p user.info "IPv4 Address for $RECORD_NAME was changed to $IPv4."
    else
      logger -t ddns -p user.warning "IPv4 Address for $RECORD_NAME FAILED to update!"
    fi

    if [ $RESPONSE_IPv6 = "true" ]; then
      logger -t ddns -p user.info "IPv6 Address for $RECORD_NAME was changed to $IPv6."
    else
      logger -t ddns -p user.warning "IPv6 Address for $RECORD_NAME FAILED to update!"
    fi

    if [ $RESPONSE_IPv4 = "true" ] && [ $RESPONSE_IPv6 = "true" ]; then
      if [ $ASUSWRT = "true" ]; then
        /sbin/ddns_custom_updated 1
      fi
      echo "good"
    else
      if [ $ASUSWRT = "true" ]; then
        /sbin/ddns_custom_updated 0
      fi
      echo "badauth"
    fi
  fi
else
  if [ $IPv4 = $IPv4_RECORD_IP ]; then
    if [ $ASUSWRT = "true" ]; then
      /sbin/ddns_custom_updated 1
    fi
    logger -t ddns -p user.info "No IP change detected, no DNS update required."
    echo "nochg";
    exit 0;
  else
    RESPONSE_IPv4=$(Update_DNS_Record $RECORD_NAME $IPv4_RECORD_ID A $IPv4 $RECORD_TTL $API_TOKEN $ZONE_ID)

    if [ $RESPONSE_IPv4 = "true" ]; then
      if [ $ASUSWRT = "true" ]; then
        /sbin/ddns_custom_updated 1
      fi
      logger -t ddns -p user.info "IPv4 Address for $RECORD_NAME was changed to $IPv4."
      echo "good"
    else
      if [ $ASUSWRT = "true" ]; then
        /sbin/ddns_custom_updated 0
      fi
      logger -t ddns -p user.warning "IPv4 Address for $RECORD_NAME FAILED to update!"
      echo "badauth"
    fi
  fi
fi
