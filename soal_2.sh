# Durin

ip a
ip route
sysctl net.ipv4.ip_forward

di /etc/default/isc-dhcp-relay
# sourced by /etc/init.d/isc-dhcp-relay
# installed at /etc/default/isc-dhcp-relay by the maintainer scripts

#
# This is a POSIX shell fragment
#

# What servers should the DHCP relay forward requests to?
SERVERS="10.68.4.2"

# On what interfaces should the DHCP relay (dhrelay) serve DHCP requests?
INTERFACES="eth2 eth3 eth4"

# Additional options that are passed to the DHCP relay daemon?
OPTIONS=""

/etc/init.d/isc-dhcp-relay restart

ps aux | grep dhcp


# Aldarion

ip a show eth0
ip r show | grep default

echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server
echo 'INTERFACESv6=""' >> /etc/default/isc-dhcp-server

# config dhcpd.conf


authoritative;
default-lease-time 600;
max-lease-time 3600;

#---Keluarga Manusia (Subnet 1)
subnet 10.68.1.0 netmask 255.255.255.0 {
        range 10.68.1.6 10.68.1.34;
        range 10.68.1.68 10.68.1.94;
        option routers 10.68.1.1;
        option broadcast-address 10.68.1.255;
        option domain-name-servers 10.68.4.2, 192.168.122.1;
        option domain-name "k09.local";
}

#---keluarga peri (subnet2)
subnet 10.68.2.0 netmask 255.255.255.0 {
        range 10.68.2.35 10.68.2.67;
        range 10.68.2.96 10.68.2.121;
        option routers 10.68.2.1;
        option broadcast-address 10.68.2.255;
        option domain-name-servers 10.68.4.2, 192.168.122.1;
        option domain-name "k09.local";
}

# --- Subnet Khamul (Subnet 3) ---
subnet 10.68.3.0 netmask 255.255.255.0 {
    option routers 10.68.3.1;
    option broadcast-address 10.68.3.255;
    option domain-name-servers 10.68.4.2, 192.168.122.1;
    option domain-name "k09.local";
}

# --- Fixed Address untuk Khamul ---
host khamul {
    hardware ethernet 02:42:8d:7f:57:00;
    fixed-address 10.68.3.95;
    option routers 10.68.3.1;
    option domain-name-servers 10.68.4.2, 192.168.122.1;
}

# --- Subnet antara Aldarion (DHCP Server) dan Durin (Relay) ---
subnet 10.68.4.0 netmask 255.255.255.0 {
}

touch /var/lib/dhcp/dhcpd.leases
/etc/init.d/isc-dhcp-server restart 

ps aux | grep dhcpd


#

apt-get update
apt-get install isc-dhcp-server -y

