DNSIP=$1
DIR=$(echo $1 | cut -d '.' -f-3)                     
REV=$(echo $1 | tac -s. | tail -1 | cut -d '.' -f-3)
ZONA=$2

sudo apt-get update
sudo apt-get install -y bind9 bind9utils bind9-doc

cat <<EOF > /etc/bind/named.conf.options

acl "allowed" {
    $DIR.0/24;
};

options {
    directory "/var/cache/bind";
    dnssec-validation auto;

    listen-on-v6 { any; };
    forwarders { 1.1.1.1; 1.0.0.1; };
};

EOF

cat <<EOF > /etc/bind/named.conf.local

zone $ZONA {
    type master;
    file "/var/lib/bind/$ZONA";
};

zone "$REV.in-addr.arpa" {
    type master;
    file "/var/lib/bind/$DIR.rev";
};

EOF

cat <<EOF > /var/lib/bind/$ZONA

\$TTL 3600
$ZONA.  IN  SOA ns.$ZONA.   chris.$ZONA. (
    3
    7200
    3600
    604800
    86400
)

$ZONA.          IN  NS  ns.$ZONA.

ns.$ZONA.       IN  A       $DNSIP
apache1.$ZONA.  IN  A       $DIR.10
apache2.$ZONA.  IN  A       $DIR.11
nginx.$ZONA.    IN  A       $DIR.12

sv1             IN  CNAME   apache1
sv2             IN  CNAME   apache2
n1.$ZONA.       IN  CNAME   ns
proxy           IN  CNAME   nginx
balancer        IN  CNAME   nginx
EOF

cat <<EOF > /var/lib/bind/$DIR.rev

\$TTL 3600
$REV.in-addr.arpa. IN  SOA ns.$ZONA.    chris.$ZONA. (
    3
    7200
    3600
    604800
    86400
)

$REV.in-addr.arpa. IN  NS  ns.$ZONA.

; hosts inversos
2 IN PTR dns
10 IN PTR apache1
11 IN PTR apache2
12 IN PTR nginx

EOF

cp /etc/resolv.conf{,.bak}
cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
domain $ZONA
EOF

named-checkconf
named-checkconf /etc/bind/named.conf.options
named-checkzone $ZONA /var/lib/bind/$ZONA
named-checkzone $REV.in-addr.arpa /var/lib/bind/$DIR.rev

sudo systemctl restart bind9