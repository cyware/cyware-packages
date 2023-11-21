#!/bin/sh
# preremove script for cyware-agent
# Cyware, Inc 2015

control_binary="cyware-control"

if [ ! -f /var/ossec/bin/${control_binary} ]; then
  control_binary="ossec-control"
fi

/var/ossec/bin/${control_binary} stop
