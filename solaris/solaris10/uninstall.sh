#!/bin/sh
# uninstall script for cyware-agent
# Cyware, Inc 2015

control_binary="cyware-control"

if [ ! -f /var/ossec/bin/${control_binary} ]; then
  control_binary="ossec-control"
fi

## Stop and remove application
/var/ossec/bin/${control_binary} stop
rm -rf /var/ossec/

## stop and unload dispatcher
#/bin/launchctl unload /Library/LaunchDaemons/com.cyware.agent.plist

# remove launchdaemons
rm -f /etc/init.d/cyware-agent
rm -rf /etc/rc2.d/S97cyware-agent
rm -rf /etc/rc3.d/S97cyware-agent

## Remove User and Groups
userdel cyware 2> /dev/null
groupdel cyware 2> /dev/null

exit 0
