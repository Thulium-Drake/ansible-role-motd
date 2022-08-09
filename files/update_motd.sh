#!/bin/bash
# What? Generate a MOTD
# Who? Thulium (thulium@element-networks.nl)
#      R3boot  (r3boot@r3blog.nl)
# This file is Ansible managed, your changes will be lost!

if [ -f /etc/os-release ];
then
  source /etc/os-release
  OS_NAME=$PRETTY_NAME
else
  OS_NAME='OS type not detected'
fi
UPTIME=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
UPTIME_DAYS=$(expr $(echo $UPTIME) / 86400)
UPTIME=$(expr $UPTIME - $(expr $UPTIME_DAYS \* 86400))
UPTIME_HOURS=$(expr $(echo $UPTIME) / 3600)
UPTIME=$(expr $UPTIME - $(expr $UPTIME_HOURS \* 3600))
UPTIME_MINS=$(expr $(echo $UPTIME) / 60)
RAM_SIZE=$(free -h | grep ^Mem: | awk '{print $2}')
RAM_FREE=$(free -h | grep ^Mem: | awk '{print $4}')
HOSTNAME=$(hostname -f)

FILESYSTEMS="ext.?|xfs|jfs|jffs|simfs|reiserfs|fat|ffs|ufs|vxfs|zfs"
# Exclude filesystems with the following text in their path/type
EXLC_FILESYSTEMS="autofs"

case "$(uname -s)" in
  'Linux')
    DF="df"
    ;;
  'FreeBSD','OpenBSD','NetBSD','HP-UX')
    # Non-Linux's dont come with GNU df by default. This makes sure we can run
    # the correct binary
    DF='gdf'
    if [ -z "$(which ${DF} 2>/dev/null)" ]; then
      echo "GNU df not found, please install the appropriate package for your OS"
      exit 1
    fi
    ;;
esac

TMPFILE=$(mktemp)
echo "" > ${TMPFILE}
echo "Hostname: $HOSTNAME" >> ${TMPFILE}
echo "OS: $OS_NAME" >> ${TMPFILE}
echo "" >> ${TMPFILE}
echo "RAM: $RAM_FREE free of $RAM_SIZE" >> ${TMPFILE}
echo "" >> ${TMPFILE}
echo "Disk status:" >> ${TMPFILE}
cat /proc/mounts | egrep -w ${FILESYSTEMS} | egrep -v ${EXLC_FILESYSTEMS} | awk '{print $2}' | while read FS; do
  FREE=$(${DF} -h ${FS} | egrep -v '^File' |awk '{print $4}')
  echo "${FS} has ${FREE} free" >> ${TMPFILE}
done
echo "" >> ${TMPFILE}
echo "This system is managed by Ansible" >> ${TMPFILE}
echo "" >> ${TMPFILE}
echo "Uptime   : ${UPTIME_DAYS} days ${UPTIME_HOURS}h${UPTIME_MINS}m" >> ${TMPFILE}
echo "" >> ${TMPFILE}
cat /etc/issue >> ${TMPFILE}
echo "" >> ${TMPFILE}
cat /etc/motd_ansible_timestamp >> ${TMPFILE}
mv ${TMPFILE} /etc/motd
chmod 0644 /etc/motd
