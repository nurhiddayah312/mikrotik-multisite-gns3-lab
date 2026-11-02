[admin@R-HQ] > /export hide-sensitive
# 2026-11-02 10:25:15 by RouterOS 7.23.8
# system id = cqyeOiIGK5M
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no name=to-ISP
set [ find default-name=ether3 ] disable-running-check=no name=to-SWITCH
/interface wireguard
add listen-port=13231 mtu=1420 name=wg-br1
add listen-port=13232 mtu=1420 name=wg-br2
/interface vlan
add interface=to-SWITCH name=vlan10-mgmt vlan-id=10
add interface=to-SWITCH name=vlan20-staff vlan-id=20
add interface=to-SWITCH name=vlan30-server vlan-id=30
add interface=to-SWITCH name=vlan40-guest vlan-id=40
/interface list
add name=LAN
add name=TUNNEL
/ip pool
add name=pool-mgmt ranges=10.10.10.100-10.10.10.200
add name=pool-staff ranges=10.10.20.100-10.10.20.200
add name=pool-server ranges=10.10.30.100-10.10.30.200
add name=pool-guest ranges=10.10.40.100-10.10.40.200
/ip dhcp-server
add address-pool=pool-mgmt interface=vlan10-mgmt name=dhcp-mgmt
add address-pool=pool-staff interface=vlan20-staff name=dhcp-staff
add address-pool=pool-server interface=vlan30-server name=dhcp-server
add address-pool=pool-guest interface=vlan40-guest name=dhcp-guest
/routing ospf instance
add name=ospf-main router-id=10.255.255.1
/routing ospf area
add instance=ospf-main name=backbone
/interface list member
add interface=vlan10-mgmt list=LAN
add interface=vlan20-staff list=LAN
add interface=vlan30-server list=LAN
add interface=vlan40-guest list=LAN
add interface=wg-br1 list=TUNNEL
add interface=wg-br2 list=TUNNEL
/interface wireguard peers
add allowed-address=0.0.0.0/0 interface=wg-br1 name=peer-br1 public-key=\
    "s6h8KRDJZiBO6RwPSTjrYpdWPc/fhwnh5iEQgjwiMlw="
add allowed-address=0.0.0.0/0 interface=wg-br2 name=peer-br2 public-key=\
    "O6kwMO5gqAJR5BlGhoM5MEfdqpqtrSsAd/yy367h03k="
/ip address
add address=203.0.113.2/30 interface=to-ISP network=203.0.113.0
add address=10.10.10.1/24 interface=vlan10-mgmt network=10.10.10.0
add address=10.10.20.1/24 interface=vlan20-staff network=10.10.20.0
add address=10.10.30.1/24 interface=vlan30-server network=10.10.30.0
add address=10.10.40.1/24 interface=vlan40-guest network=10.10.40.0
add address=10.255.1.1/30 interface=wg-br1 network=10.255.1.0
add address=10.255.2.1/30 interface=wg-br2 network=10.255.2.0
/ip dhcp-client
# Interface not active
add interface=ether1 name=client1
/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
add address=10.10.20.0/24 gateway=10.10.20.1
add address=10.10.30.0/24 gateway=10.10.30.1
add address=10.10.40.0/24 gateway=10.10.40.1
/ip firewall filter
add action=accept chain=forward comment="allow established" connection-state=\
    established,related
add action=drop chain=forward comment="drop invalid" connection-state=invalid
add action=accept chain=forward comment="Mgmt to all VLANs" in-interface=vlan10-mgmt \
    out-interface-list=LAN
add action=accept chain=forward comment="Staff to Server" in-interface=vlan20-staff \
    out-interface=vlan30-server
add action=drop chain=forward comment="block all other inter-VLAN" in-interface-list=LAN \
    out-interface-list=LAN
add action=accept chain=forward comment="Branch to Server" in-interface-list=TUNNEL \
    out-interface=vlan30-server
add action=drop chain=forward comment="Branch to other HQ VLANs" in-interface-list=TUNNEL \
    out-interface-list=LAN
add action=drop chain=forward comment="Guest to branches" in-interface=vlan40-guest \
    out-interface-list=TUNNEL
/ip firewall nat
add action=masquerade chain=srcnat out-interface=to-ISP
/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.1
/routing ospf interface-template
add area=backbone interfaces=wg-br1 type=ptp
add area=backbone networks=10.10.10.0/24 passive
add area=backbone networks=10.10.20.0/24 passive
add area=backbone networks=10.10.30.0/24 passive
add area=backbone interfaces=wg-br2 type=ptp
/system identity
set name=R-HQ
[admin@R-HQ] >
