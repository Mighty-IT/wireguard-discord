#!/bin/bash
# Send a message to Discord when a client is connected or disconnected from wireguard tunnel
#
# This script was modified by me and the source was from https://github.com/alfiosalanitri/wireguard-client-connection-notification
# The original script was written by Alfio Salanitri <www.alfiosalanitri.it> and are licensed under MIT License.
# Credits: This script is inspired by https://github.com/pivpn/pivpn/blob/master/scripts/wireguard/clientSTAT.sh

# check if wireguard exists
if ! command -v wg &> /dev/null; then
        printf "Sorry, but wireguard is required. Install it and try again.\n"
        exit 1;
fi


# variables
NOW=$(date +%s)
CURRENT_PATH=$(pwd)
CLIENTS_DIRECTORY="$CURRENT_PATH/clients"
PEERS_FILE="$CURRENT_PATH/peers"
TIMEOUT="3" # after X minutes the clients will be considered disconnected
WEBHOOK="" # Place your Discord Webhook URL here
WIREGUARD_CLIENTS=$(wg show wg0 dump | tail -n +2) # remove first line from list
if [ "" == "$WIREGUARD_CLIENTS" ]; then
        printf "No wireguard clients.\n"
        exit 1
fi




while IFS= read -r LINE; do
        public_key=$(awk '{ print $1 }' <<< "$LINE")
        remote_ip=$(awk '{ print $3 }' <<< "$LINE" | awk -F':' '{print $1}')
        last_seen=$(awk '{ print $5 }' <<< "$LINE")
        
        # By default, the client name is just the sanitized public key containing only letters and numbers.
        client_name=$(echo "$public_key" | sed 's/[^a-zA-Z0-9]//g')

        # check the peers file if it does not exist.
        if [ ! -f "$PEERS_FILE" ]; then
                echo "No peers file found. Falling back to pub key"
        else
                friendly_name=$(grep "$public_key" $PEERS_FILE | cut -d ':' -f 2)
        fi
       
        # check if the wireguard directory keys exists (created by pivpn)
        if [ -d "/etc/wireguard/keys/" ]; then
                # if the public_key is stored in the /etc/wireguard/keys/username_pub file, save the username in the client_name var
                client_name_by_public_key=$(grep -R "$public_key" /etc/wireguard/keys/ | awk -F"/etc/wireguard/keys/|_pub:" '{print $2}' | sed -e 's./..g')
                if [ "" != "$client_name_by_public_key" ]; then
                        client_name=$client_name_by_public_key
                fi
        fi
        client_file="$CLIENTS_DIRECTORY/$client_name.txt"

        # create the client file if it does not exist.
        if [ ! -f "$client_file" ]; then
                echo "offline" > "$client_file"
        fi

        # setup notification variable
        send_notification="no"

        # last client status
        last_connection_status=$(cat "$client_file")

        # elapsed seconds from last connection
        last_seen_seconds=$(date -d @"$last_seen" '+%s')

        # if the user is online
        if [ "$last_seen" -ne 0 ]; then

                # elapsed minutes from last connection
                last_seen_elapsed_minutes=$((10#$(($NOW - $last_seen_seconds)) / 60))

                # if the previous state was online and the elapsed minutes are greater than TIMEOUT, the user is offline
                if [ $last_seen_elapsed_minutes -gt $TIMEOUT ] && [ "online" == "$last_connection_status" ]; then
                        echo "offline" > "$client_file"
                        send_notification="disconnected"
                # if the previous state was offline and the elapsed minutes are lower than timeout, the user is online
                elif [ $last_seen_elapsed_minutes -le $TIMEOUT ] && [ "offline" == "$last_connection_status" ]; then
                        echo "online" > "$client_file"
                        send_notification="connected"
                fi
        else
                # if the user is offline
                if [ "offline" != "$last_connection_status" ]; then
                        echo "offline" > "$client_file"
                        send_notification="disconnected"
                fi
        fi

        # send notifications
        if [ "no" != "$send_notification" ]; then
                printf "The client %s is %s\n" "$client_name" $send_notification
                if [ -z "${friendly_name}" ]; then
                message="$client_name  **$send_notification** from remote IP address: **$remote_ip**"
                curl -s -X POST $WEBHOOK -d "{\"content\": \":computer:  $message\"}" -H "Accept: application/json" -H "Content-Type:application/json"
                else
                message="$friendly_name  **$send_notification** from remote IP address: **$remote_ip**"
                curl -s -X POST $WEBHOOK -d "{\"content\": \":computer:  $message\"}" -H "Accept: application/json" -H "Content-Type:application/json"
                fi

        else
                printf "The client %s is %s, no notification will be sent. Friendly name: %s\n" "$client_name" $(cat "$client_file") "$friendly_name"
        fi

done <<< "$WIREGUARD_CLIENTS"
exit 0
