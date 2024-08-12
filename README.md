# wireguard-discord
Discord Notifications for connecting and disconnecting clients poor mans monitoring.
By default it will run every minute the check. When the last handshake is older than three minutes, the host will be marked as disconnected.
Feel free to modify the timeout in the script.

## Requirements
- Wireguard installed
- Root privileges on the system
- Discord Webhook URL

## How to use / install
- Clone the repository
- Create Webhook URL and update the variable in the script (https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
- Add line below in crontab for root user (crontab -e)

```bash
* * * * * cd /path/to/wireguard-discord.sh && /path/to/wireguard-discord.sh > /dev/null 2>&1
```


## Optional
When you create a file called peers in the same directory you can map the public key to a friendly_name. So you can enjoy a more beautiful output.

```bash
# Examples <PubKey>:<friendly_name>
p1u3qhsPEjdisazsd/da+dLkdasmTwbqArZC/xM6HRw=:Client-01
bQg8zIRXJcöoaish/aslkbc+asc0Lz4rjyf5SQpNn3Q=:Client-02
```

![image](https://github.com/user-attachments/assets/1dd529fc-673f-4032-95c9-94c499f522c9)






----------
Most of the script is from ❤️ https://github.com/alfiosalanitri/wireguard-client-connection-notification ❤️. 
So props out to him. I just want to use discord webhooks so i modified and removed some parts of it.
