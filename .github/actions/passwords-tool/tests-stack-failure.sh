#!/bin/bash

apiPass="$(cat cyware-install-files/cyware-passwords.txt | awk "/username: 'cyware'/{getline;print;}" | awk '{ print $2 }' | tr -d \' )"
adminPass="$(cat cyware-install-files/cyware-passwords.txt | awk "/username: 'admin'/{getline;print;}" | awk '{ print $2 }' | tr -d \')"

if ! bash cyware-passwords-tool.sh -u wazuuuh | grep "ERROR"; then
   exit 1
elif ! sudo bash cyware-passwords-tool.sh -u admin -p password | grep "ERROR"; then
   exit 1 
elif ! sudo bash cyware-passwords-tool.sh -au cyware -ap "${adminPass}" -u cyware -p password -A | grep "ERROR"; then
   exit 1
elif ! curl -s -u cyware:cyware -k -X POST "https://localhost:55000/security/user/authenticate" | grep "Invalid credentials"; then
   exit 1
elif ! curl -s -u wazuuh:"${apiPass}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "Invalid credentials"; then
   exit 1
elif ! curl -s -XGET https://localhost:9200/ -u admin:admin -k | grep "Unauthorized"; then
   exit 1
elif ! curl -s -XGET https://localhost:9200/ -u adminnnn:"${adminPass}" -k | grep "Unauthorized"; then
   exit 1
fi
