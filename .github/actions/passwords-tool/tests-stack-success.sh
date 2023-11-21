#!/bin/bash

users=( admin kibanaserver kibanaro logstash readall snapshotrestore )
api_users=( cyware cyware-wui )

echo '::group:: Change indexer password, password providing it.'

bash cyware-passwords-tool.sh -u admin -p LN*X1v.VNtCZ5sESEtLfijPAd39LXGAI
if curl -s -XGET https://localhost:9200/ -u admin:LN*X1v.VNtCZ5sESEtLfijPAd39LXGAI -k -w %{http_code} | grep "401"; then
    exit 1
fi
echo '::endgroup::'

echo '::group:: Change indexer password without providing it.'

indx_pass="$(bash cyware-passwords-tool.sh -u admin | awk '/admin/{ print $NF }' | tr -d \' )"
if curl -s -XGET https://localhost:9200/ -u admin:"${indx_pass}" -k -w %{http_code} | grep "401"; then
    exit 1
fi

echo '::endgroup::'

echo '::group:: Change all passwords except Cyware API ones.'

mapfile -t pass < <(bash cyware-passwords-tool.sh -a | awk '{ print $NF }' | sed \$d | sed '1d' )
for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${pass[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'

echo '::group:: Change all passwords.'

cyware_pass="$(cat cyware-install-files/cyware-passwords.txt | awk "/username: 'cyware'/{getline;print;}" | awk '{ print $2 }' | tr -d \' )"

mapfile -t passall < <(bash cyware-passwords-tool.sh -a -au cyware -ap "${cyware_pass}" | awk '{ print $NF }' | sed \$d ) 
passindexer=("${passall[@]:0:6}")
passapi=("${passall[@]:(-2)}")

for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passindexer[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

for i in "${!api_users[@]}"; do
    if curl -s -u "${api_users[i]}":"${passapi[i]}" -w "%{http_code}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'

echo '::group:: Change single Cyware API user.'

bash cyware-passwords-tool.sh -au cyware -ap "${passapi[0]}" -u cyware -p BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 -A 
    if curl -s -w "%{http_code}" -u cyware:BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
echo '::endgroup::'

echo '::group:: Change all passwords except Cyware API ones using a file.'

mapfile -t passfile < <(bash cyware-passwords-tool.sh -f cyware-install-files/cyware-passwords.txt | awk '{ print $NF }' | sed \$d | sed '1d' )
for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passfile[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done
echo '::endgroup::'

echo '::group:: Change all passwords from a file.'
mapfile -t passallf < <(bash cyware-passwords-tool.sh -f cyware-install-files/cyware-passwords.txt -au cyware -ap BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 | awk '{ print $NF }' | sed \$d ) 
passindexerf=("${passallf[@]:0:6}")
passapif=("${passallf[@]:(-2)}")

for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passindexerf[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

for i in "${!api_users[@]}"; do
    if curl -s -u "${api_users[i]}":"${passapif[i]}" -w "%{http_code}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'
