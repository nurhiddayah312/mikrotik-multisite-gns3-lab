[admin@R-BR1] > /export hide-sensitive
# 2026-11-02 10:26:03 by RouterOS 7.23.8
# system id = dA0NScX8avH
#
/interface ethernet
set [ find default-name=ether3 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
set [ find default-name=ether1 ] disable-running-check=no name=to-ISP
set [ find default-name=ether2 ] disable-running-check=no name=to-LAN
/interface wireguard
add listen-port=13231 mtu=1420 name=wg-hq
/ip pool
add name=pool-br1 ranges=10.20.0.100-10.20.0.200
/ip dhcp-server
add address-pool=pool-br1 interface=to-LAN name=dhcp-br1
/routing ospf instance
add name=ospf-main router-id=10.255.255.2
/routing ospf area
add instance=ospf-main name=backbone
/interface wireguard peers
add allowed-address=0.0.0.0/0 endpoint-address=203.0.113.2 endpoint-port=13231 interface=wg-hq name=\
    peer-hq persistent-keepalive=25s public-key="NSe20u7ENRQp6JNPUKujRjYwWiZnHTrk5ZYbdWdeFj4="
/ip address
add address=203.0.113.6/30 interface=to-ISP network=203.0.113.4
add address=10.20.0.1/24 interface=to-LAN network=10.20.0.0
add address=10.255.1.2/30 interface=wg-hq network=10.255.1.0
/ip dhcp-client
add interface=to-ISP name=client1
/ip dhcp-server network
add address=10.20.0.0/24 gateway=10.20.0.1
/ip firewall nat
add action=masquerade chain=srcnat out-interface=to-ISP
/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.5
/routing ospf interface-template
add area=backbone interfaces=wg-hq type=ptp
add area=backbone networks=10.20.0.0/24 passive
/system identity
set name=R-BR1
[admin@R-BR1] >
