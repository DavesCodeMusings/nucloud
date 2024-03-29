HOSTNAME=alpine
DNS_DOMAIN=home
KEYBOARD_LAYOUT=us   # First prompt when running setup-keymaps
KEYBOARD_VARIANT=us  # Second prompt when running setup-keymaps
DNS1=$(ip route show | awk '/^default/ { print $3 }')  # Assume the router (default gateway) also provides DNS.
BOOT_SIZE=100
ROOT_SIZE=8192
SWAP_SIZE=8192

echo "Creating answerfile for /sbin/setup-alpine"
cat << EOF > answerfile.txt
KEYMAPOPTS="${KEYBOARD_LAYOUT} ${KEYBOARD_VARIANT}"
HOSTNAMEOPTS="-n ${HOSTNAME}.${DNS_DOMAIN}"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname ${HOSTNAME}.${DNS_DOMAIN}
"
DNSOPTS="-d ${DNS_DOMAIN} ${DNS1}"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1 -c"  # Use the first mirror and enable community repository
USEROPTS="none"  # Skip automatic creation
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys /dev/sda"
EOF

echo "Running /sbin/setup-alpine"
export BOOT_SIZE
export ROOT_SIZE
export SWAP_SIZE
setup-alpine -f answerfile.txt

echo "Don't forget to remove installation media."
