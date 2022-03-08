#!/bin/bash

. /etc/default/virtualbox

# Enable/disable service
if [ "${VBOXWEB_USER}" == "" ]; then
	exit 0
fi

# Implementation of user control, execute several commands as another (predefined) user,
if [ "${VBOXWEB_USER}" == "${USER}" ]; then
  su_command="/bin/bash -c"
else
  su_command="su - ${VBOXWEB_USER} -s /bin/bash -c"
fi

# Check for VirtualBox binary path
if [[ ${PATH} =~ (^|\:)${VBOX_BIN_PATH}(\:|$) ]]; then
  echo "VBox bin path already in \$PATH"
else
  if [ "$VBOX_BIN_PATH" != "" ]; then
    PATH = "$PATH:$VBOX_BIN_PATH";
  else
    echo -n "\$VBOX_BIN_PATH is empty???. Trying to locate.."
    ${su_command} "which VBoxManage > /dev/null 2>&1" \
    && { echo " OK Found on path"; } \
    || { echo " FAIL Not found on path"; exit 1; }
  fi
fi

declare -A AUTOSTART
declare -A AUTONOSEQ
NOSEQ=0

autostart_getall() {
  local LIST
  local MACHINES
  local STARTUP
  local VMNAME
  local SEQ

  MACHINES=$($su_command "VBoxManage list vms | awk '{ print \$NF }' | sed -e 's/[{}]//g'")
	for UUID in $MACHINES; do
		STARTUP=$($su_command "VBoxManage getextradata $UUID 'pvbx/startupMode'" | awk '{ print $NF }')
		if [ "${STARTUP}" == "auto" ]; then
			VMNAME=$($su_command "VBoxManage showvminfo $UUID | sed -n '0,/^Name:/s/^Name:[ \t]*//p'")
      SEQ=$($su_command "VBoxManage getextradata $VMNAME 'pvbx/startupSequence'" | awk '{ print $NF }')
      echo "startupSequence: [${SEQ}]"
      if [[ ${SEQ} =~ ^[0-9]+$ ]]; then
        AUTOSTART[${SEQ}]=${VMNAME}
      else
        let NOSEQ=NOSEQ+1
        AUTONOSEQ[${NOSEQ}]=${VMNAME}
      fi
			echo "$(basename $0): starting machine ${VMNAME} ..."
			# $su_command "VBoxManage startvm $UUID --type headless" >>/var/log/vb.log
		fi
	done
}

autostart_getall

echo "AUTOSTART: ${AUTOSTART[*]}"
echo "AUTONOSEQ: ${AUTONOSEQ[*]}"