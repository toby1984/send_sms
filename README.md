# What's this?

This is a simple Bash script I'm using on my Ubuntu 22.04 LTS Zabbix server to send alerts via the german SMS gateway http://www.smsflatrate.net/
I'm german so need to send SMS to a german subscriber number - hence the choice. Drop me a note if you manage to find a cheaper gateway ;)

# Features

- configurable rate limit (currently only second resolution so fastest you can send is 1 SMS/second)
- takes care of URL-encoding input parameters as necessary
- (hopefully) concurrency safe

# Usage

- Find out where your Zabbix installation expects custom scripts by looking for the 'AlertScriptsPath' configuration parameter in /etc/zabbix/zabbix_server.conf
  Since the directory is part of the installation and at least on Ubuntu defaults to something in /usr/lib, I prefer to instead manually create a /home/zabbix folder owned by the
  zabbix user (with appropriate permissions ofc) and symlink the script
- Copy the script to your server
  Make sure to assign the right permissions so that the script is readable and executable by the user running your Zabbix instance
- Edit the script and set the following parameters:
  - API_KEY (mandatory)
  - FROM (optional, defaults to "zabbix")
  - PREFIX (optional prefix for each message you send)
  - RATE_LIMIT_SECONDS (defaults to 1 message per recipient every 60 minutes)
- Configure a new media-type on your Zabbix

  ![Zabbix Configuration](https://github.com/toby1984/send_sms/blob/master/zabbix_config.png?raw=true)
- Test the media type
- Assign it to users as you see fit using the subscriber number in INTERNATIONAL FORMAT (SMS gateway requirement) as "To"
