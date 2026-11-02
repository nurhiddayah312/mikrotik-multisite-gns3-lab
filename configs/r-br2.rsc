[admin@R-BR2] > /export hide-sensitive
# 2026-11-02 09:08:12 by RouterOS 7.23.8
# system id = ghTIwnKsfqD
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no name=to-ISP
set [ find default-name=ether3 ] disable-running-check=no name=to-LAN
/ip pool
add name=pool-br2 ranges=10.30.0.100-10.30.0.200
/ip address
add address=203.0.113.10/30 interface=to-ISP network=203.0.113.8
add address=10.30.0.1/24 interface=to-LAN network=10.30.0.0
/ip dhcp-client
# Interface not active
add interface=ether1 name=client1
/ip dhcp-server
add address-pool=pool-br2 interface=to-LAN name=dhcp-br2
/ip dhcp-server network
add address=10.30.0.0/24 gateway=10.30.0.1
/ip firewall nat
add action=masquerade chain=srcnat out-interface=to-ISP
/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.9
/system identity
set name=R-BR2
