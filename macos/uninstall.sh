#!/bin/sh

## Stop and remove application
sudo /Library/Ossec/bin/cyware-control stop
sudo /bin/rm -r /Library/Ossec*

## stop and unload dispatcher
/bin/launchctl unload /Library/LaunchDaemons/com.cyware.agent.plist

# remove launchdaemons
/bin/rm -f /Library/LaunchDaemons/com.cyware.agent.plist

## remove StartupItems
/bin/rm -rf /Library/StartupItems/CYWARE

## Remove User and Groups
/usr/bin/dscl . -delete "/Users/cyware"
/usr/bin/dscl . -delete "/Groups/cyware"

/usr/sbin/pkgutil --forget com.cyware.pkg.cyware-agent
/usr/sbin/pkgutil --forget com.cyware.pkg.cyware-agent-etc

# In case it was installed via Puppet pkgdmg provider

if [ -e /var/db/.puppet_pkgdmg_installed_cyware-agent ]; then
    rm -f /var/db/.puppet_pkgdmg_installed_cyware-agent
fi

echo
echo "Cyware agent correctly removed from the system."
echo

exit 0
