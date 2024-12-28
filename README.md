## Cloudflare DDNS Updater - *NIX Unviversal Script

This script was developed to update your unique DNS records name with your non-fixed IPv4 and IPv6 address provided by your ISP.

**Requirements:**
* Cloudflare API Token - You will require a API token to update the DNS record name. This method is more secure than the traditional email login ID and password as specific permissions can be assigned to each token. Head to https://developers.cloudflare.com/fundamentals/api/get-started/create-token/ to learn more about the API Token.
* Cloudflare Zone ID - This is a unique HEX16 string that identifies the specific domain name that contains the domain name record you wish to update
* Record Name - As the script only UPDATES the record name A and AAAA records, you will need to first create it in Cloudflare and note that name here
* Record TTL - This is the Time to Live (TTL) for the Record Name. If you're unsure, you can leave it at the default automatic (1).
* curl binary - Used to perform http(s) post and/or gets
* jq binary - Used to processed JSON results returned by API queries
* logger binary - Used to record the results of the actions into the local syslog/messages

**This script has been tested with the following NIX based opertaing systems...**
* Mac OS
* Debian
* ASUSWRT-Merlin
* Synology DSM

**Note:** This script is designed to only update a single record name that currently exists. You will need to create the A and/or AAAA record in your Cloudflare account.

## How-to:

## General
1. After downloading/copying the script to your target system edit the script with your favourite text editor and enter...
* API Token into the `API_TOKEN` variable
* Zone ID into the `ZONE_ID` variable
* Record/dub-domain Name into the `RECORD_NAME` variable
* TTL value into the `RECORD_TTL` variable

2. Save the changes and exit the editor
3. Make the script executeable with the command `chmod +x <script name>`
4. Run the script to sanity check that you get everything configured right

## ASUSWRT-Merlin
1. Make sure the configured script is copied into the `/jffs/scripts`
2. Make sure the script is named `ddns-start`
3. Make sure the script is executable with the command `chmod +x /jffs/scripts ddns-start`
4. Login into your ASUS router web interface and go to **_WAN >> DDNS_** and select **_CUSTOM_** from the server dropdown
5. Host Name configuration is not necessary
6. Forced Update Interval is at your discreetion
7. Be sure to click **APPLY**

## Synology DSM
1. Login into your Synology NAS via SSH (if you haven't please read https://geekistheway.com/2020/07/05/enabling-ssh-on-your-synology-dsm/)
2. Copy the script into the `/sbin` folder with a unique name (i.e. `cloudflare-ddns-updater.sh`)
3. Make sure the script is executable with the command `chmod +x /sbin/cloudflare-ddns-updater.sh`
4. Add the following lines into your Synolody DDNS Provider config file with the commands..
```
   cat >> /etc.defaults/ddns_provider.conf << EOF
   [Cloudflare DDNS]
        modulepath=/sbin/cloudflare-ddns-updater.sh
        queryurl=https://www.cloudflare.com
        website=https://www.cloudflare.com
   EOF
 ```  
5. Log into your DSM Web UI with administrative privileges
6. Go to Control **Panel > External Access > DDNS > Add**
7. Select `Cloudflare DDNS` from the Service Provider drop down
8. Enter something into the required field (Note: this information is never used as all the necessary information has been entered into the script directly)
9. Click **TEST CONNECTION**
10. Click **OK** when done

## Debian (or any other NIX platform)
1. 
   
