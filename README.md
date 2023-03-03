# What's this?

This is a simple Bash script I'm using on my Ubuntu 22.04 LTS Zabbix server to send alerts via the german SMS gateway http://www.smsflatrate.net/
I'm german so need to send SMS to a german subscriber number - hence the choice. Drop me a note if you manage to find a cheaper gateway ;)

# Features

- configurable rate limit (currently only second resolution so fastest you can send is 1 SMS/second)
- takes care of URL-encoding input parameters as necessary
- (hopefully) concurrency safe

# Usage

- Copy the script to a suitable location on your Zabbix server (I manually created /home/zabbix for that). Make sure to assign the right permissions so that the script is readable and executable by the user running your Zabbix instance.
- Edit the script and set the following parameters:
  - API_KEY (mandatory)
  - FROM (optional, defaults to "zabbix")
  - PREFIX (optional prefix for each message you send)
- Configure a new media-type on your Zabbix
- Test the media type
- Assign it to users as you see fit using the subscriber number in INTERNATIONAL FORMAT (SMS gateway requirement) as "To"
