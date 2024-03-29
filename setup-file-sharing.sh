FILE_SHARING_VOL_SIZE=10G
FILE_SHARING_VOL_GROUP=vg0

echo "Creating compose project directory"
mkdir -p /var/lib/docker/compose/file-sharing || exit 1
cd /var/lib/docker/compose/file-sharing || exit 2

echo "Creating logical volume /dev/${FILE_SHARING_VOL_GROUP}/srv"
lvcreate -n srv -L ${FILE_SHARING_VOL_SIZE} ${FILE_SHARING_VOL_GROUP}
mkfs.ext4 /dev/${FILE_SHARING_VOL_GROUP}/srv
echo "/dev/${FILE_SHARING_VOL_GROUP}/srv /srv ext4 rw 1 1" >>/etc/fstab
mount /srv

echo "Creating directories for user file storage"
install -m750 -o www-data -g root -d /srv/cloud
install -m755 -o root -g root -d /srv/media
install -m755 -o root -g root -d /srv/public
install -m777 -o root -g root -d /srv/shared

echo "Creating Nextcloud application user and group"
deluser xfs  # On Alpine, xfs has the UID Nextcloud expects www-data to have.
addgroup -S -g 33 www-data
adduser -S -H -g www-data -G www-data -h /var/www -u 33 www-data

echo "Creating compose file"
cat <<EOF >docker-compose.yml
services:
    nextcloud:
        image: nextcloud
        container_name: nextcloud
        hostname: nextcloud
        restart: unless-stopped
        ports:
            - 8910:80
        volumes:
            - nextcloud:/var/www/html
            - /srv/cloud:/var/www/html/data

    samba:
        image: davescodemusings/samba-anon:x86
        container_name: samba
        hostname: samba
        restart: unless-stopped
        ports:
            - '445:445'
        volumes:
            - /srv/public:/srv/public
            - /srv/media:/srv/media
            - /srv/shared:/srv/shared

volumes:
    nextcloud:
EOF

echo "Starting file sharing services"
docker-compose up -d
