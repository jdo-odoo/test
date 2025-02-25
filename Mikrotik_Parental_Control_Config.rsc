# Activation du Wi-Fi et création des SSID
/interface wireless
set [ find default-name=wlan1 ] ssid="WiFi-Adultes" mode=ap-bridge disabled=no
add name=wlan2 master-interface=wlan1 ssid="WiFi-Enfants" mode=ap-bridge disabled=no

# Configuration des VLANs
/interface vlan
add name=vlan20 vlan-id=20 interface=bridge
add name=vlan30 vlan-id=30 interface=bridge

# Association des VLANs aux réseaux Wi-Fi
/interface wireless
set wlan1 vlan-id=20 vlan-mode=use-tag
set wlan2 vlan-id=30 vlan-mode=use-tag

# Attribution des adresses IP aux VLANs
/ip address
add address=192.168.20.1/24 interface=vlan20
add address=192.168.30.1/24 interface=vlan30

# Configuration des serveurs DHCP
/ip pool
add name=pool20 ranges=192.168.20.10-192.168.20.200
add name=pool30 ranges=192.168.30.10-192.168.30.200

/ip dhcp-server
add name=dhcp-adultes interface=vlan20 address-pool=pool20
add name=dhcp-enfants interface=vlan30 address-pool=pool30

/ip dhcp-server network
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,1.1.1.1
add address=192.168.30.0/24 gateway=192.168.30.1 dns-server=8.8.8.8,1.1.1.1

# Blocage des sites Web pour WiFi-Enfants
/ip dns static
add name=facebook.com address=127.0.0.1
add name=youtube.com address=127.0.0.1
add name=tiktok.com address=127.0.0.1

/ip firewall address-list
add list=blocked_sites address=157.240.221.35 comment="Facebook"
add list=blocked_sites address=142.250.190.46 comment="YouTube"

/ip firewall filter
add chain=forward src-address=192.168.30.0/24 dst-address-list=blocked_sites action=drop

# Planification des horaires d'accès pour WiFi-Enfants
/system script
add name=block_enfants source="/ip firewall filter remove [find comment='WiFi-Enfants OK']"
add name=allow_enfants source="/ip firewall filter add chain=forward src-address=192.168.30.0/24 action=accept comment='WiFi-Enfants OK'"

/system scheduler
add name=fermeture_enfants start-time=21:00 interval=1d on-event=block_enfants
add name=ouverture_enfants start-time=07:00 interval=1d on-event=allow_enfants

# Limitation de bande passante pour WiFi-Enfants
/queue simple
add name="WiFi-Enfants Limit" target=192.168.30.0/24 max-limit=2M/2M
