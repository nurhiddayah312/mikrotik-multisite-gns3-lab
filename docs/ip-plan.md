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

Every site router has a static default route toward R-ISP (internet, Phase 1). Private networks between sites are learned with OSPF over the WireGuard tunnels (Phase 2). R-ISP never learns any private route.

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

## Site-to-site tunnels (WireGuard, Phase 2)

Branches initiate the tunnels toward HQ (203.0.113.2). R-ISP only forwards ordinary UDP packets between the WAN addresses.

| Tunnel | HQ interface | HQ address | Branch interface | Branch address | UDP port | Status |
|---|---|---|---|---|---|---|
| HQ <-> BR1 | wg-br1 | 10.255.1.1/30 | wg-hq | 10.255.1.2/30 | 13231 | Configured, verified |
| HQ <-> BR2 | wg-br2 | 10.255.2.1/30 | wg-hq | 10.255.2.2/30 | 13232 | Configured, verified |

Branch peers use `persistent-keepalive=25s`. Each tunnel has its own key pair; private keys never leave the routers and are not stored in this repository.

## Dynamic routing (OSPF, Phase 2)

Single area (backbone 0.0.0.0), OSPFv2, point-to-point on the tunnel interfaces. LAN interfaces are advertised as passive, so no OSPF neighbors are sought on client networks.

| Router | Router ID | Tunnel interfaces | Advertised LANs |
|---|---|---|---|
| R-HQ | 10.255.255.1 | wg-br1, wg-br2 | 10.10.10.0/24, 10.10.20.0/24, 10.10.30.0/24 |
| R-BR1 | 10.255.255.2 | wg-hq | 10.20.0.0/24 |
| R-BR2 | 10.255.255.3 | wg-hq | 10.30.0.0/24 |

The Guest VLAN (10.10.40.0/24) is intentionally **not** advertised, so branches have no route to it. Branch-to-branch traffic passes through HQ (hub-and-spoke).

Routers also learn the tunnel subnets of the other branches through OSPF (for example R-BR2 shows 10.255.1.0/30), which is expected.
