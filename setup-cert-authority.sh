COUNTRY=
STATE_PROVINCE=
CITY=
ROOT_CA=HomeCA
DNS_DOMAIN=$(hostname -d)
HOST=$(hostname -s)
IP=$(hostname -i)

echo "${IP} ${HOST}.${DNS_DOMAIN}"

echo "Verifying settings"
[ -n "$COUNTRY" ] || exit 1
[ -n "$STATE_PROVINCE" ] || exit 1
[ -n "$CITY" ] || exit 1
[ -n "$ROOT_CA" ] || exit 1
[ -n "$DNS_DOMAIN" ] || exit 1
[ -n "$HOST" ] || exit 1
[ -n "$IP" ] || exit 1

CERTS_DIR=/etc/ssl/certs
KEYS_DIR=/etc/ssl/private
TEMP_DIR=$(mktemp -d)

echo "Verifying directories"
[ -d "$CERTS_DIR" ] || exit 2
[ -d "$KEYS_DIR" ] || exit 2
[ -d "$TEMP_DIR" ] || exit 2

echo "Creating root CA config"
cat <<EOF >${TEMP_DIR}/${ROOT_CA}.conf
[req]
default_bits = 4096
default_md = sha256
distinguished_name = req_dn
req_extensions = req_ext
prompt = no

[req_dn]
C = ${COUNTRY}
ST = ${STATE_PROVINCE}
L = ${CITY}
O = ${ROOT_CA}
CN = ${ROOT_CA}

[req_ext]
basicConstraints = critical, CA:true
keyUsage = keyCertSign, cRLSign
EOF

echo "Creating root CA"
openssl genrsa \
  -out ${KEYS_DIR}/${ROOT_CA}.key \
  4096

openssl req \
  -config ${TEMP_DIR}/${ROOT_CA}.conf \
  -key ${KEYS_DIR}/${ROOT_CA}.key \
  -new \
  -out ${TEMP_DIR}/${ROOT_CA}.csr

openssl x509 \
  -trustout \
  -signkey ${KEYS_DIR}/${ROOT_CA}.key \
  -req \
  -in ${TEMP_DIR}/${ROOT_CA}.csr \
  -out ${CERTS_DIR}/${ROOT_CA}.crt \
  -days 3650

echo "Creating intermediate CA config"
cat <<EOF >${TEMP_DIR}/home.conf
[req]
default_bits = 2048
default_md = sha256
distinguished_name = req_dn
req_extensions = req_ext
prompt = no

[req_dn]
C = ${COUNTRY}
ST = ${STATE_PROVINCE}
L = ${CITY}
O = ${DNS_DOMAIN}
CN = ${DNS_DOMAIN}

[req_ext]
basicConstraints = critical, CA:true
keyUsage = keyCertSign, cRLSign
EOF

echo "Creating intermediate CA"
openssl genrsa \
  -out ${KEYS_DIR}/${DNS_DOMAIN}.key \
  2048

openssl req \
  -config ${TEMP_DIR}/${DNS_DOMAIN}.conf \
  -key ${KEYS_DIR}/${DNS_DOMAIN}.key \
  -new \
  -out ${TEMP_DIR}/${DNS_DOMAIN}.csr

openssl x509 \
  -trustout \
  -req \
  -CA ${CERTS_DIR}/${ROOT_CA}.crt \
  -CAkey ${KEYS_DIR}/${ROOT_CA}.key \
  -in ${TEMP_DIR}/${DNS_DOMAIN}.csr \
  -out ${CERTS_DIR}/${DNS_DOMAIN}.crt \
  -days 3650

echo "Creating host certificate config"
cat <<EOF >${TEMP_DIR}/${HOST}.conf
[req]
default_bits = 2048
default_md = sha256
distinguished_name = req_dn
req_extensions = req_ext
prompt = no

[req_dn]
C = ${COUNTRY}
ST = ${STATE_PROVINCE}
L = ${CITY}
O = ${DNS_DOMAIN}
CN = ${HOST}.${DNS_DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOST}.${DNS_DOMAIN}
DNS.2 = *.${HOST}.${DNS_DOMAIN}
IP.1 = ${IP}
EOF

echo "Creating host certificate"
openssl req \
  -new \
  -nodes \
  -keyout ${KEYS_DIR}/${HOST}.key \
  -out ${TEMP_DIR}/${HOST}.csr \
  -config ${TEMP_DIR}/${HOST}.conf

# Sign the request using the intermediate certificate authority.
openssl x509 -req \
  -in ${TEMP_DIR}/${HOST}.csr \
  -CA ${CERTS_DIR}/${DNS_DOMAIN}.crt \
  -CAkey ${KEYS_DIR}/${DNS_DOMAIN}.key \
  -CAcreateserial \
  -out ${CERTS_DIR}/${HOST}.crt \
  -days 365 \
  -sha256 \
  -extensions req_ext \
  -extfile ${TEMP_DIR}/${HOST}.conf

echo "Cleaning up temporary files"
rm ${TEMP_DIR}/${ROOT_CA}.csr
rm ${TEMP_DIR}/${ROOT_CA}.conf
rm ${TEMP_DIR}/${DNS_DOMAIN}.csr
rm ${TEMP_DIR}/${DNS_DOMAIN}.conf
rm ${TEMP_DIR}/${HOST}.conf
rm ${TEMP_DIR}/${HOST}.csr
rmdir ${TEMP_DIR}
