[admin@R-ISP] > /export hide-sensitive
# 2026-11-02 10:24:27 by RouterOS 7.23.8
# system id = ersWVAEHWSB
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no name=to-BR1
set [ find default-name=ether4 ] disable-running-check=no name=to-BR2
set [ find default-name=ether2 ] disable-running-check=no name=to-HQ
/ip address
add address=203.0.113.1/30 interface=to-HQ network=203.0.113.0
add address=203.0.113.5/30 interface=to-BR1 network=203.0.113.4
add address=203.0.113.9/30 interface=to-BR2 network=203.0.113.8
/ip dhcp-client
# Interface not active
add interface=ether1 name=client1
/system identity
set name=R-ISP
