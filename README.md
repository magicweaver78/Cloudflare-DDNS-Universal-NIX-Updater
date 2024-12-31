# Cloudflare DDNS Updater - *NIX Universal Script

This script was developed for my need to update specific DNS `A` (IPv4) and `AAAA` (IPv6)record name entries in my Cloudflare account with the dynamic IPv4 & IPv6 addresses provided by my ISP. The goal was to have a single script that was...
  * Deployable on ANY *NIX like operating system
  * Easily configurable
  * Automatically discovers the public IPv4 and/or IPv6 assigned without needing for complex probing of device network interfaces
  * Secure (relatively speaking)

As of this moment, I feel this script is perfect for my needs and it's not likely to be developed further other than mandatory maintenance for it's continued operations in my own environment. Should you have a better approach and/or idea, you're welcome to fork this script and enhance it for your needs. Credit/acknowledgement is not necessary but it is appreciated if you're forking this script.

**This script has been tested with the following NIX based opertaing systems...**
  * ASUSWRT-Merlin (version 388.y)
  * Synology DSM (version 7.x)
  * OS X/Mac OS
  * Debian (Bullseye)

**Note:** This script is designed to only **update a single record name** that currently exists. You will need to create the `A` and/or `AAAA` record in your Cloudflare account before using this script.

**Requirements:**
  * [Cloudflare API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) - A unique API token to update the DNS record name. This method is more secure than the traditional email login ID and password as specific permissions can be assigned to each token.
  * [Cloudflare Zone ID](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/) - A unique HEX16 string that identifies the specific domain name that contains the domain name record you wish to update
  * Record Name - As the script only **UPDATES** the record name `A` and `AAAA` records, you will need to first create it in Cloudflare.
  * Record TTL - This is the Time-to-Live (TTL) for the Record Name. If you're unsure, you can leave it at the default automatic (1).
  * curl binary - Used to perform http(s) POSTs and/or GETs
  * jq binary - A command line (CLI) JSON processor
  * logger binary - Used to record the results of the actions into the local syslog/messages

## **Acknowledgements:**
The basis for my script was derived from the following persons...
  * [alphabt](https://github.com/alphabt/asuswrt-merlin-ddns-cloudflare) for use in the ASUSWRT-Merlin environment
  * [insistant-afk](https://github.com/insistent-afk/cloudflare-ddns-for-synology) for use in the Synology DSM environment

## How-to:
The script _should_ run in any *NIX like environment with the required binaries available, however for ASUSWRT-Merlin and Synology DSM users there are some specialised customisations you can do to take advantage of internal automations.

You can jump directly to the [ASUSWRT-Merlin](#ASUSWRT-Merlin_HowTo) or [Synology DSM](#SynologyDSM_HowTo) section or just keep reading

<a name="General_HowTo" />

### General
This method applies to and works with ALL *NIX based systems including ASUSWRT-Merlin & Synology DSM systems without using the specialised customisations.

  1. Create the `A` and `AAAA` record names in your Cloudflare account just remember that that...
     | RECORD TYPE | SUGGESTED INITIAL VALUE | DESCRIPTION |
     | :---------: | :---------------------: | :---------- |
     | `A` | 0.0.0.0 | The IPv4 address that is used to reach your router or server. The default `0.0.0.0` is just a precaution, it will be overwritten by the script. | 
     | `AAAA` | :: | The IPv6 address that is used to reach your server. The default `::` is just a precaution, it will be overwritten by the script. |

  3. Download the script to your system using...

     curl
     ```
     curl -O -L https://raw.githubusercontent.com/magicweaver78/Cloudflare-DDNS-Universal-NIX-Updater/main/cloudflare-ddns-updater.sh
     ```

     -or-

     wget
     ```
     wget https://raw.githubusercontent.com/magicweaver78/Cloudflare-DDNS-Universal-NIX-Updater/main/cloudflare-ddns-updater.sh
     ```

  4. Open the downloaded script with your favourite text editor (i.e. vi, nano, etc) and edit the following parameters/variables to include your specific information...
     | VARIABLE NAME | PURPOSE | EXAMPLE |
     | :------------ | :------ | :------ |
     | `API_TOKEN=`  | Your [Cloudflare API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) | `API_TOKEN="0a1b2c3d4e5FG6HIjKlm556601024mn0b"` |
     | `ZONE_ID=`    | Your [Cloudflare Zone ID](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/) | `ZONE_ID="9a00ffddc299eed866f11b76509fe0a88"` |
     | `RECORD_NAME=`| The A/AAAA record name you want to update | `RECORD_NAME="sub-name.domain-name.tld"` |
     | `RECORD_TTL=` | The TTL value in seconds for the record name (default 1 for auto) | `RECORD_TTL="1"` |

  3. Save the changes and exit the text editor.

  4. Make the script executable
     ```chmod +x cloudflare-ddns-updater.sh```
  
  5. Run the script to sanity check
     ```./cloudflare-ddns-updater.sh```
  
  6. Move the script to a convenient location of your choice (i.e. `/bin`)
     ```mv ./cloudflare-ddns-update.sh /bin```
  
  7. You could manually run the script or setup some from of automation using [crontab](https://www.cyberciti.biz/faq/how-do-i-add-jobs-to-cron-under-linux-or-unix-oses/) or [watchdog](https://www.squash.io/using-a-watchdog-process-to-trigger-bash-scripts-in-linux/)

<a name="ASUSWRT-Merlin_HowTo" />

### ASUSWRT-Merlin
These steps are specific for ASUSWRT-Merlin users only and may not work on other Linux based router OSes.

  1. Create the `A` and `AAAA` record names in your Cloudflare account just remember that that...
     | RECORD TYPE | SUGGESTED INITIAL VALUE | DESCRIPTION |
     | :---------: | :---------------------: | :---------- |
     | `A` | 0.0.0.0 | The IPv4 address that is used to reach your router or server. The default `0.0.0.0` is just a precaution, it will be overwritten by the script. | 
     | `AAAA` | :: | The IPv6 address that is used to reach your server. The default `::` is just a precaution, it will be overwritten by the script. |
  
  2. Please perform the following on your ASUSWRT-Merlin device prior to the next steps...
     * [Enable the JFFS partition](https://github.com/RMerl/asuswrt-merlin.ng/wiki/JFFS) in the NVRAM.
     * [Enable SSH login](https://github.com/RMerl/asuswrt-merlin.ng/wiki/SSH)
  
  3. Login to your ASUSWRT-Merlin device via SSH and navigate to the `/jffs/scripts` directory
     ```
     cd /jffs/scripts
     ``` 

  5. Download the script to your system using...

     curl
     ```
     curl -o ddns-start -L https://raw.githubusercontent.com/magicweaver78/Cloudflare-DDNS-Universal-NIX-Updater/main/cloudflare-ddns-updater.sh
     ```

     -or-

     wget
     ```
     wget -O ddns-start https://raw.githubusercontent.com/magicweaver78/Cloudflare-DDNS-Universal-NIX-Updater/main/cloudflare-ddns-updater.sh
     ```

  6. Open the downloaded script with your favourite text editor (i.e. vi, nano, etc) and edit the following parameters/variables to include your specific information...
     | VARIABLE NAME | PURPOSE | EXAMPLE |
     | :------------ | :------ | :------ |
     | `API_TOKEN=`  | Your [Cloudflare API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) | `API_TOKEN="0a1b2c3d4e5FG6HIjKlm556601024mn0b"` |
     | `ZONE_ID=`    | Your [Cloudflare Zone ID](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/) | `ZONE_ID="9a00ffddc299eed866f11b76509fe0a88"` |
     | `RECORD_NAME=`| The A/AAAA record name you want to update | `RECORD_NAME="sub-name.domain-name.tld"` |
     | `RECORD_TTL=` | The TTL value in seconds for the record name (default 1 for auto) | `RECORD_TTL="1"` |

  7. Save the changes and exit the text editor.
  
  8. Make the script executable
     ```chmod +x ddns-start```
  
  5. Run the script to sanity check
     ```./ddns-start```

  6. Log into the ASUSWRT-Merlin web UI and...
     1. Go to **Advanced Settings >> WAN >> DDNS**
     2. Set the Server to Custom
     3. Click the Apply button

<a name="SynologyDSM_HowTo" />

### Synology DSM
These steps are specific for Synology NAS users only running DSM 7.x and may not work on other Synology devices.

  1. Create the `A` and `AAAA` record names in your Cloudflare account just remember that that...
     | RECORD TYPE | SUGGESTED INITIAL VALUE | DESCRIPTION |
     | :---------: | :---------------------: | :---------- |
     | `A` | 0.0.0.0 | The IPv4 address that is used to reach your router or server. The default `0.0.0.0` is just a precaution, it will be overwritten by the script. | 
     | `AAAA` | :: | The IPv6 address that is used to reach your server. The default `::` is just a precaution, it will be overwritten by the script. |

  2. Please [Enable SSH Login](https://geekistheway.com/2020/07/05/enabling-ssh-on-your-synology-dsm/) on your Synology NAS before moving to the next steps

  3. Login into your Synology NAS via SSH with admin privileges and switch to `root` user with...
     ```sudo -i```
 
  4. Download the script to your system using...

     curl
     ```
     curl -O -L https://raw.githubusercontent.com/magicweaver78/Cloudflare-DDNS-Universal-NIX-Updater/main/cloudflare-ddns-updater.sh
     ```

     -or-

     wget
     ```
     wget https://raw.githubusercontent.com/magicweaver78/Cloudflare-DDNS-Universal-NIX-Updater/main/cloudflare-ddns-updater.sh
     ```

  5. Open the downloaded script with your favourite text editor (i.e. vi, nano, etc) and edit the following parameters/variables to include your specific information...
     | VARIABLE NAME | PURPOSE | EXAMPLE |
     | :------------ | :------ | :------ |
     | `API_TOKEN=`  | Your [Cloudflare API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) | `API_TOKEN="0a1b2c3d4e5FG6HIjKlm556601024mn0b"` |
     | `ZONE_ID=`    | Your [Cloudflare Zone ID](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/) | `ZONE_ID="9a00ffddc299eed866f11b76509fe0a88"` |
     | `RECORD_NAME=`| The A/AAAA record name you want to update | `RECORD_NAME="sub-name.domain-name.tld"` |
     | `RECORD_TTL=` | The TTL value in seconds for the record name (default 1 for auto) | `RECORD_TTL="1"` |

  6. Save the changes and exit the text editor.

  7. Make the script executable
     ```chmod +x cloudflare-ddns-updater.sh```
  
  8. Run the script to sanity check
     ```./cloudflare-ddns-updater.sh```
  
  9. Move the script to `/sbin` directory
     ```mv ./cloudflare-ddns-update.sh /sbin```

  10. Update the Synology DDNS provider config file with the commands...
      ```
      cat >> /etc.defaults/ddns_provider.conf << EOF
      [Cloudflare DDNS]
        modulepath=/sbin/cloudflare-ddns-updater.sh
        queryurl=https://www.cloudflare.com
        website=https://www.cloudflare.com
      EOF
      ```

   11. Log into your Synology NAS DSM UI with administrative privileges
       1. Go to **Panel >> External Access >> DDNS >> Add**
       2. Select **Cloudflare DDNS** from the **Service Provider** drop down
       3.Enter something into the required fields (Note: this information is never used as all the necessary information has been entered into the script directly)
       4. Click **TEST CONNECTION**
       5. Click **OK** when done

## FAQ

  1. **Why didn't you separate out the configuration variables to ensure security?**
     To ensure maximum compability across as many *NIX environment as possible, I opted to use standard `sh` shell commands. The ability to import variables via a separate file is only available in the `bash` shell and specially compiled `sh` shells.

  2. **Your script looks like a derivative/clone of this other script. What gives?**
     I admit that my script was derived/adapted from [alphabt](https://github.com/alphabt/asuswrt-merlin-ddns-cloudflare) and [insistant-afk](https://github.com/insistent-afk/cloudflare-ddns-for-synology). I believe their scripts are also based on other scripts written. If you feel that my script is closer in function to one you have written (and published), please reach out so that I can review and give credit/acknowledgement where due.

  3. __I downloaded your script and used it on this other *NIX platform and it's buggy. Can you fix it?__
     If you can get me enough information (i.e. your platform, the exact circumstances on how you got the error) I would be glad to look into it and fix it, if it's not to complex. However I have to caveat with the point that the script was originally written for my own use but felt it sufficient for public release/sharing. I can only test on platforms/environments I have access to.

     I strongly encourage you to fork the script and fix/enhance it. However if you wish to contribute fixes/enhancements to the script, I would be happy to review and include it in a future release with proper credit/acnknowledgement to your contribution.

  4. **I only need to update the `AAAA` record in my DNS, can you tweak your script for that?**
     Since I update **ONLY IPv4** or **IPv4 AND IPv6**, I don't feel the need to tweak my script for a function I (foreseeably) will never use. I encourage you to fork the script and make the necessary enhancements for your use case or you could wait until I have a need to have **IPv6 ONLY** update.

  5. **Can you modify the/create a script that would work with xyz DDNS service/provider/host?**
     Short answer, no.

     Long answer, I wrote this script for my specific needs and decided to share it online for other people who have an identical/similar need with Cloudflare DDNS updates. As I don't use the DDNS service/provider/host that you are suggesting, I'm not compelled to invest my limited availability to develop/debug/maintain something I don't foresee using. I encourage you to fork the script and enahnce/modify it for your needs.
