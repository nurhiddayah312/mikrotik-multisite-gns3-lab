# IP Plan

## WAN links (point-to-point, /30)

The 203.0.113.0/24 range is reserved for documentation (RFC 5737), so it is safe to use as a simulated "internet" without clashing with real addresses.

| Link | Network | R-ISP side | Router side | Status |
|---|---|---|---|---|
| R-ISP <-> R-HQ | 203.0.113.0/30 | 203.0.113.1 | 203.0.113.2 | Configured, verified |
| R-ISP <-> R-BR1 | 203.0.113.4/30 | 203.0.113.5 | 203.0.113.6 | Configured, verified |
| R-ISP <-> R-BR2 | 203.0.113.8/30 | 203.0.113.9 | 203.0.113.10 | Configured, verified |

## LAN networks (gateway is always .1)

| Site | VLAN | Name | Network | Gateway | DHCP pool | Status |
|---|---|---|---|---|---|---|
| HQ | 10 | Management | 10.10.10.0/24 | 10.10.10.1 | 10.10.10.100-200 | Configured, verified |
| HQ | 20 | Staff | 10.10.20.0/24 | 10.10.20.1 | 10.10.20.100-200 | Configured, verified |
| HQ | 30 | Server | 10.10.30.0/24 | 10.10.30.1 | 10.10.30.100-200 | Configured, verified |
| HQ | 40 | Guest | 10.10.40.0/24 | 10.10.40.1 | 10.10.40.100-200 | Configured, verified |
| BR1 | - | LAN | 10.20.0.0/24 | 10.20.0.1 | 10.20.0.100-200 | Configured, verified |
| BR2 | - | LAN | 10.30.0.0/24 | 10.30.0.1 | 10.30.0.100-200 | Configured, verified |

DHCP lease time is the RouterOS default (30 minutes).

## Interface naming

RouterOS interface names (`etherX`) do **not** always match the adapter order shown in GNS3 (`EthernetX`). The mapping below was verified with `/interface print` (running flag) and `/ip neighbor print`. Interfaces are renamed by function to avoid confusion.

| Router | RouterOS name | Renamed to | GNS3 adapter | Connects to |
|---|---|---|---|---|
| R-ISP | ether2 | to-HQ | Ethernet1 | R-HQ |
| R-ISP | ether3 | to-BR1 | Ethernet2 | R-BR1 |
| R-ISP | ether4 | to-BR2 | Ethernet3 | R-BR2 |
| R-HQ | ether2 | to-ISP | Ethernet1 | R-ISP |
| R-HQ | ether3 | to-SWITCH | Ethernet2 | SwitchVLAN (trunk) |
| R-BR1 | ether1 | to-ISP | Ethernet1 | R-ISP |
| R-BR1 | ether2 | to-LAN | Ethernet2 | PC-BR1 |

| R-BR2 | ether2 | to-ISP | Ethernet1 | R-ISP |
| R-BR2 | ether3 | to-LAN | Ethernet2 | PC-BR2 |

## Routing

Phase 1 uses a static default route on every site router pointing to R-ISP. Dynamic routing (OSPF/BGP) is planned for Phase 2.

| Router | Default route via | Status |
|---|---|---|
| R-HQ | 203.0.113.1 | Configured, verified |
| R-BR1 | 203.0.113.5 | Configured, verified |
| R-BR2 | 203.0.113.9 | Configured, verified |

## NAT

| Router | Rule | Status |
|---|---|---|
| R-HQ | srcnat masquerade, out-interface `to-ISP` | Configured, verified |
| R-BR1 | srcnat masquerade, out-interface `to-ISP` | Configured, verified |
| R-BR2 | srcnat masquerade, out-interface `to-ISP` | Configured, verified |

R-ISP has no route to the private 10.x networks, so NAT on each site router is required for LAN hosts to reach the simulated internet. Direct communication between sites is intentionally not available in Phase 1; it is the goal of Phase 2 (OSPF and site-to-site VPN).
