# Router Hardening (input chain)

The `forward` chain controls traffic that passes **through** a router. The `input` chain controls traffic addressed **to the router itself** (management, routing protocols, ping). Without input rules, every host that can reach a router can also talk to its services, so the input chain was locked down on R-HQ, R-BR1 and R-BR2 with a default-drop policy. R-ISP is the simulated internet and is not hardened.

Out-of-band access: the GNS3 console is a serial console, not a network service, so it is unaffected by these rules and stays available for recovery.

## Policy

| Allowed to reach the router | From |
|---|---|
| WireGuard (UDP 13231 / 13232) | R-HQ: ISP side. Branches: only from HQ's WAN address (203.0.113.2) |
| OSPF | Tunnel interfaces only |
| DHCP (UDP 67) | LAN interfaces only |
| SSH (22) and Winbox (8291) | Management VLAN (10.10.10.0/24) only; reaches the branches through the tunnels |
| Ping | ISP side, tunnels (restricted source), Management VLAN, and each client VLAN only to its own gateway |
| Everything else | Dropped |

## R-HQ input rules (in order)

| # | Comment | Action | Match |
|---|---|---|---|
| 1 | established | accept | established, related |
| 2 | invalid | drop | invalid |
| 3 | wireguard | accept | UDP 13231,13232 from `to-ISP` |
| 4 | ospf | accept | OSPF from TUNNEL list |
| 5 | dhcp | accept | UDP 67 from LAN list |
| 6 | icmp-isp | accept | ICMP from `to-ISP` |
| 7 | icmp-tunnel | accept | ICMP from TUNNEL list, source 10.255.0.0/16 |
| 8 | icmp-mgmt | accept | ICMP from vlan10-mgmt |
| 9 | icmp-staff-gw | accept | ICMP from vlan20-staff to 10.10.20.1 |
| 10 | icmp-server-gw | accept | ICMP from vlan30-server to 10.10.30.1 |
| 11 | icmp-guest-gw | accept | ICMP from vlan40-guest to 10.10.40.1 |
| 12 | mgmt-ssh-winbox | accept | TCP 22,8291 from vlan10-mgmt |
| 13 | drop-all-input | drop | everything else |

## R-BR1 and R-BR2 input rules (in order)

| # | Comment | Action | Match |
|---|---|---|---|
| 1 | established | accept | established, related |
| 2 | invalid | drop | invalid |
| 3 | wireguard | accept | UDP 13231 (BR1) or 13232 (BR2) from 203.0.113.2 via `to-ISP` |
| 4 | ospf | accept | OSPF from `wg-hq` |
| 5 | dhcp | accept | UDP 67 from `to-LAN` |
| 6 | icmp-isp | accept | ICMP from `to-ISP` |
| 7 | icmp-tunnel | accept | ICMP from `wg-hq`, source in address list `mgmt-nets` |
| 8 | icmp-lan-gw | accept | ICMP from `to-LAN` to the LAN gateway (10.20.0.1 or 10.30.0.1) |
| 9 | mgmt-from-hq | accept | TCP 22,8291 from `wg-hq`, source 10.10.10.0/24 |
| 10 | drop-all-input | drop | everything else |

Address list `mgmt-nets` contains 10.255.0.0/16 (tunnel addresses) and 10.10.10.0/24 (HQ Management VLAN). Without the source restriction on rule 7, a Staff client could ping the branch router through the tunnel; the restriction closes that gap.

## Service lockdown (all three routers)

| Service | State |
|---|---|
| ftp, telnet, www, www-ssl, api, api-ssl | Disabled |
| ssh, winbox | Enabled, restricted to 10.10.10.0/24 |
| MAC server, MAC-Winbox, neighbor discovery, bandwidth-test server | Disabled |

After the neighbor-discovery change, `/ip neighbor print` is empty on purpose.

## Verification

See the hardening section in [`test-results.md`](test-results.md). Routing and tunnels were re-checked after the rules were applied: R-HQ kept two OSPF neighbors in Full state, both branches kept one, and WireGuard handshakes continued to refresh.

## Planned follow-up

- Allow SNMP (UDP 161) **only** from the Zabbix server address once monitoring is added in Phase 3.
- Harden R-ISP only if the simulated internet needs to behave like a managed device.
