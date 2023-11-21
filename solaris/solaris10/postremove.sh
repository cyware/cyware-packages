#!/bin/sh
# postremove script for cyware-agent
# Cyware, Inc 2015

if getent passwd cyware > /dev/null 2>&1; then
  userdel cyware
fi

if getent group cyware > /dev/null 2>&1; then
  groupdel cyware
fi
