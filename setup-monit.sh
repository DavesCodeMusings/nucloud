# Set NETADDR and NETMASK for manual.
#NETADDR='192.168.1.0'
#NETMASK='255.255.255.0'

if [ "$NETADDR" == "" ] || [ "$NETMASK" == "" ]; then
  INTERFACE=$(ip route show | awk '/^default/ { print $5 }')
  echo "Detecting network configuration for device ${INTERFACE}..."
  NETCIDR=$(ip route show | grep "dev ${INTERFACE} scope link" | cut -d' ' -f1)
  NETADDR=$(ipcalc -n $NETCIDR 2>/dev/null | cut -d= -f2)
  NETMASK=$(ipcalc -m $NETCIDR 2>/dev/null | cut -d= -f2)
  if [ "$NETADDR" == "" ] || [ $NETMASK == "" ]; then
    echo "Unable to determine network address and mask for ${INTERFACE}"
  fi
fi

echo "Installing packages"
apk add monit

echo "Configuring monit"
sed -i~ \
  -e 's/^# set pidfile/set pidfile/' \
  -e 's/^# set idfile/set idfile/' \
  -e 's/^# set statefile/set statefile/' \
  -e '/use address localhost/d' \
  -e "s/allow admin:monit.*$/allow ${NETADDR}\/${NETMASK}/" \
  -e 's/^#  include/include/' \
  /etc/monitrc

mkdir /etc/monit.d

cat <<EOF > /etc/monit.d/ssh.conf
check process sshd with pidfile /var/run/sshd.pid
start program  "/sbin/service sshd start"
stop program  "/sbin/service sshd stop"
if failed port 22 protocol ssh then restart
if 2 restarts within 3 cycles then timeout
EOF

cat <<EOF > /etc/monit.d/rootfs.conf
check device root with path /
if space usage > 80% then alert
EOF

echo "Starting monit"
rc-update add monit
monit -t && service monit start

echo "See https://mmonit.com/wiki/ for configuration examples."
echo "https://mmonit.com/wiki/Monit/EnableSSLInMonit for SSL."
