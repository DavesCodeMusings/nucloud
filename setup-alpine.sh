KEYBOARD_LAYOUT=us
KEYBOARD_VARIANT=us
HOSTNAME=alpine
DOMAIN=home
DNS=192.168.0.1
ROOT_SIZE=8192
SWAP_SIZE=8192

# Disable forcing EFI partition to 512M.
sed -i /BOOT_SIZE=512/d /sbin/setup-disk

# Answer file is customized using variables set above.
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

export ROOT_SIZE
export SWAP_SIZE
setup-alpine -f answerfile.txt

echo "Remove installation media and restart."
