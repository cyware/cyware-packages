#!/bin/bash

[[ ${DEBUG} = "yes" ]] && set -ex || set -e

# Edit system configuration
systemConfig() {

  echo "Upgrading the system. This may take a while ..."
  yum upgrade -y > /dev/null 2>&1

  # Disable kernel messages and edit background
  mv ${CUSTOM_PATH}/grub/cyware.png /boot/grub2/
  mv ${CUSTOM_PATH}/grub/grub /etc/default/
  grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null 2>&1

  # Enable fips
  mv ${CUSTOM_PATH}/enable_fips.sh /tmp/
  chmod 755 /tmp/enable_fips.sh
  bash /tmp/enable_fips.sh

  # Update Cyware indexer jvm heap
  mv ${CUSTOM_PATH}/automatic_set_ram.sh /etc/
  chmod 755 /etc/automatic_set_ram.sh
  mv ${CUSTOM_PATH}/updateIndexerHeap.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable updateIndexerHeap.service


  # Change root password (root:cyware)
  sed -i "s/root:.*:/root:\$1\$pNjjEA7K\$USjdNwjfh7A\.vHCf8suK41::0:99999:7:::/g" /etc/shadow

  hostname ${HOSTNAME}

  # AWS instance has this enabled
  sed -i "s/PermitRootLogin yes/#PermitRootLogin yes/g" /etc/ssh/sshd_config

  # SSH configuration
  sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config

  # Edit system custom welcome messages
  bash ${CUSTOM_PATH}/messages.sh ${DEBUG} ${CYWARE_VERSION} ${SYSTEM_USER}

  # Install dependencies
  yum install -y libnss3.so xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-utils xorg-x11-fonts-cyrillic \
    xorg-x11-fonts-Type1 xorg-x11-fonts-misc fontconfig freetype ipa-gothic-fonts open-vm-tools

}

# Edit unattended installer
preInstall() {

  # Avoid random passwords
  sed -i "s/passwords+=\(.*\)/passwords+=\(\"\${users[i]}\"\)/g" ${RESOURCES_PATH}/${INSTALLER}
  sed -i "s/api_passwords+=\(.*\)//g" ${RESOURCES_PATH}/${INSTALLER}
  sed -i "s/passwords_checkPassword .*//g" ${RESOURCES_PATH}/${INSTALLER}
  sed -i "s/filecorrect=.*/filecorrect=1/g" ${RESOURCES_PATH}/${INSTALLER}
  sed -i "s/main \"\$@\"//g" ${RESOURCES_PATH}/${INSTALLER}
  cat ${CUSTOM_PATH}/functions.sh >> ${RESOURCES_PATH}/${INSTALLER}
  echo "" >> ${RESOURCES_PATH}/${INSTALLER}
  echo "main \"\$@\"" >> ${RESOURCES_PATH}/${INSTALLER}

}

clean() {

  rm -f /securityadmin_demo.sh
  yum clean all

  systemctl daemon-reload

  # Clear synced files
  rm -rf ${CURRENT_PATH}/* ${CURRENT_PATH}/.gitignore

  # Remove logs
  find /var/log/ -type f -exec bash -c 'cat /dev/null > {}' \;
  find /var/ossec/logs/ -type f -exec bash -c 'cat /dev/null > {}' \;

  cat /dev/null > ~/.bash_history && history -c

}
