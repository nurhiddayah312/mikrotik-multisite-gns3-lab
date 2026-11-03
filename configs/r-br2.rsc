
# 2026-11-03 02:57:15 by RouterOS 7.23.8
# system id = ghTIwnKsfqD
#
/interface ethernet
set [ find default-name=ether4 ] disable-running-check=no name=ether1
set [ find default-name=ether3 ] disable-running-check=no name=ether4
set [ find default-name=ether1 ] disable-running-check=no name=to-ISP
set [ find default-name=ether2 ] disable-running-check=no name=to-LAN
/interface wireguard
add listen-port=13232 mtu=1420 name=wg-hq
/ip pool
add name=pool-br2 ranges=10.30.0.100-10.30.0.200
/ip dhcp-server
add address-pool=pool-br2 interface=to-LAN name=dhcp-br2
/routing ospf instance
add name=ospf-main router-id=10.255.255.3
/routing ospf area
add instance=ospf-main name=backbone
/ip neighbor discovery-settings
set discover-interface-list=none
/interface wireguard peers
add allowed-address=0.0.0.0/0 endpoint-address=203.0.113.2 endpoint-port=13232 interface=wg-hq name=peer-hq \
    persistent-keepalive=25s public-key="o++SzkMsJU9yixv1NwracIa4WYVh1n2wpVHx7iT+nxw="
/ip address
add address=203.0.113.10/30 interface=to-ISP network=203.0.113.8
add address=10.30.0.1/24 interface=to-LAN network=10.30.0.0
add address=10.255.2.2/30 interface=wg-hq network=10.255.2.0
/ip dhcp-client
# Interface not active
add interface=ether1 name=client1
/ip dhcp-server network
add address=10.30.0.0/24 gateway=10.30.0.1
/ip firewall address-list
add address=10.255.0.0/16 list=mgmt-nets
add address=10.10.10.0/24 list=mgmt-nets
/ip firewall filter
add action=accept chain=input comment=wireguard dst-port=13232 in-interface=to-ISP protocol=udp src-address=\
    203.0.113.2
add action=accept chain=input comment=icmp-lan-gw dst-address=10.30.0.1 in-interface=to-LAN protocol=icmp
add action=accept chain=input comment=established connection-state=established,related
add action=drop chain=input comment=invalid connection-state=invalid
add action=accept chain=input comment=ospf in-interface=wg-hq protocol=ospf
add action=accept chain=input comment=dhcp dst-port=67 in-interface=to-LAN protocol=udp
add action=accept chain=input comment=icmp-isp in-interface=to-ISP protocol=icmp
add action=accept chain=input comment=icmp-tunnel in-interface=wg-hq protocol=icmp src-address-list=mgmt-nets
add action=accept chain=input comment=mgmt-from-hq dst-port=22,8291 in-interface=wg-hq protocol=tcp src-address=\
    10.10.10.0/24
add action=drop chain=input comment=drop-all-input
/ip firewall nat
add action=masquerade chain=srcnat out-interface=to-ISP
/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.9
/ip service
set ftp disabled=yes
set ssh address=10.10.10.0/24
set telnet disabled=yes
set www disabled=yes
set reverse-proxy disabled=yes
set winbox address=10.10.10.0/24
set api disabled=yes
set api-ssl disabled=yes
/routing ospf interface-template
add area=backbone interfaces=wg-hq type=ptp
add area=backbone networks=10.30.0.0/24 passive
/system identity
set name=R-BR2
/tool bandwidth-server
set enabled=no
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=none
