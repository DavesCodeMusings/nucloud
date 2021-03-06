KEYBOARD_LAYOUT=us   # First prompt when running setup-keymaps
KEYBOARD_VARIANT=us  # Second prompt when running setup-keymaps
HOSTNAME=alpine
DOMAIN=home
DNS=$(ip route show | awk '/^default/ { print $3 }')  # Assume the router (default gateway) also provides DNS.
ROOT_SIZE=8192
SWAP_SIZE=8192

# Disable forcing EFI partition to 512M. See https://gitlab.alpinelinux.org/alpine/alpine-conf/-/issues/10512
sed -i /BOOT_SIZE=512/d /sbin/setup-disk

echo "Creating answerfile for /sbin/setup-alpine"
cat << EOF > answerfile.txt
KEYMAPOPTS="${KEYBOARD_LAYOUT} ${KEYBOARD_VARIANT}"
HOSTNAMEOPTS="-n ${HOSTNAME}.${DOMAIN}"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname ${HOSTNAME}.${DOMAIN}
"
DNSOPTS="-d ${DOMAIN} ${DNS}"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1 -c"  # Use the first mirror and enable community repository
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys /dev/sda"
EOF

echo "Running /sbin/setup-alpine"
export ROOT_SIZE
export SWAP_SIZE
setup-alpine -f answerfile.txt

echo "Remove installation media and restart."
