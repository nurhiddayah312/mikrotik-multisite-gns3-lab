# Test Results

All tests were run from the VPCS clients in the GNS3 lab after configuring R-HQ (VLANs, DHCP, NAT, firewall) and the two branch routers (DHCP, NAT).

## DHCP

| Client | VLAN | Address received | Gateway |
|---|---|---|---|
| PC-Mgmt | 10 | 10.10.10.200/24 | 10.10.10.1 |
| PC-Staff | 20 | 10.10.20.200/24 | 10.10.20.1 |
| PC-Server | 30 | 10.10.30.200/24 | 10.10.30.1 |
| PC-Guest | 40 | 10.10.40.200/24 | 10.10.40.1 |
| PC-BR1 | - | 10.20.0.200/24 | 10.20.0.1 |
| PC-BR2 | - | 10.30.0.200/24 | 10.30.0.1 |

Each client received an address from its own network's pool, and the DHCP server shown in `show ip` is the local gateway router (R-HQ for the VLANs, R-BR1 and R-BR2 for the branches).

## HQ connectivity and policy

| # | From | To | Expected | Observed |
|---|---|---|---|---|
| 1 | PC-Staff | 10.10.20.1 (gateway) | Reply | Reply, about 5-13 ms |
| 2 | PC-Staff | 203.0.113.1 (R-ISP) | Reply via NAT | Reply, TTL 63 |
| 3 | PC-Guest | 203.0.113.1 (R-ISP) | Reply via NAT | Reply, TTL 63 |
| 4 | PC-Guest | 10.10.20.200 (Staff) | Blocked | 5 of 5 timeouts |
| 5 | PC-Staff | 10.10.30.200 (Server) | Reply | Reply, TTL 63 |
| 6 | PC-Server | 10.10.20.200 (Staff) | Blocked | 5 of 5 timeouts |
| 7 | PC-Mgmt | 10.10.20.200 (Staff) | Reply | Reply, TTL 63 |
| 8 | PC-Staff | 10.10.10.200 (Mgmt) | Blocked | 5 of 5 timeouts |

TTL 63 on inter-VLAN and internet replies shows the packet crossed one router hop.

## Branch connectivity

| # | From | To | Expected | Observed |
|---|---|---|---|---|
| 9 | PC-BR1 | 10.20.0.1 (gateway) | Reply | Reply, TTL 64 |
| 10 | PC-BR1 | 203.0.113.5 (R-ISP, BR1 link) | Reply | Reply, TTL 63 |
| 11 | PC-BR1 | 203.0.113.1 (R-ISP, HQ link) | Reply via NAT | Reply, TTL 63 |
| 12 | PC-BR1 | 10.10.20.200 (HQ Staff) | No path (Phase 1) | Destination network unreachable |
| 13 | PC-BR2 | 10.30.0.1 (gateway) | Reply | Reply, TTL 64 |
| 14 | PC-BR2 | 203.0.113.9 (R-ISP, BR2 link) | Reply | Reply, TTL 63 |
| 15 | PC-BR2 | 203.0.113.1 (R-ISP, HQ link) | Reply via NAT | Reply, TTL 63 |
| 16 | PC-BR2 | 10.20.0.200 (BR1 client) | No path (Phase 1) | Destination network unreachable |

### Why tests 12 and 16 fail (expected)

The packets leave the branch (NAT applies) and reach R-ISP, which has no route to any private 10.x network and answers with ICMP "network unreachable". This confirms the cause is the missing path between sites, not a firewall rule, and it is the motivation for Phase 2 (site-to-site VPN and dynamic routing).

## Screenshots

See the `images/` folder, files `05` to `17`.
