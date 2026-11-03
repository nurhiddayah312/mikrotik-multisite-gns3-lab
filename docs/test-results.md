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

### Why tests 12 and 16 fail (expected, Phase 1 state)

These results were captured before the tunnels and OSPF were configured.

The packets leave the branch (NAT applies) and reach R-ISP, which has no route to any private 10.x network and answers with ICMP "network unreachable". This confirms the cause is the missing path between sites, not a firewall rule, and it is the motivation for Phase 2 (site-to-site VPN and dynamic routing).

## Screenshots

See the `images/` folder, files `05` to `17` for Phase 1.

## Phase 2: tunnels and routing

### WireGuard tunnels

| # | From | To | Observed |
|---|---|---|---|
| 17 | R-HQ | 10.255.1.2 (BR1 tunnel) | 5 of 5 replies, average about 29 ms |
| 18 | R-BR1 | 10.255.1.1 (HQ tunnel) | 5 of 5 replies, average about 25 ms |
| 19 | R-BR2 | 10.255.2.1 (HQ tunnel) | 3 of 3 replies, average about 22 ms |

Both HQ peers showed a recent `last-handshake` and growing rx/tx counters.

### OSPF

- R-HQ has two neighbors in state Full (router IDs 10.255.255.2 and 10.255.255.3).
- R-BR2 learned the HQ LANs (10.10.10.0/24, 10.10.20.0/24, 10.10.30.0/24), the BR1 LAN (10.20.0.0/24) and the BR1 tunnel subnet.
- The Guest VLAN (10.10.40.0/24) was not learned by any branch, as intended.

### Reachability before the site firewall rules

| # | From | To | Observed |
|---|---|---|---|
| 20 | PC-BR1 | 10.10.20.200 (HQ Staff) | Reply, TTL 62 (was "unreachable" in Phase 1) |

This showed that OSPF over the tunnel works and that a branch could reach every advertised HQ VLAN until the site policy was added.

### Site-to-site policy

| # | From | To | Expected | Observed |
|---|---|---|---|---|
| 21 | PC-BR1 | 10.10.30.200 (Server) | Reply | Reply, TTL 62 |
| 22 | PC-BR1 | 10.10.20.200 (Staff) | Blocked | 5 of 5 timeouts |
| 23 | PC-BR1 | 10.10.10.200 (Mgmt) | Blocked | 5 of 5 timeouts |
| 24 | PC-Mgmt | 10.20.0.200 (BR1) | Reply | Reply, TTL 62 |
| 25 | PC-Staff | 10.20.0.200 (BR1) | Reply | Reply, TTL 62 |
| 26 | PC-Guest | 10.20.0.200 (BR1) | Blocked | 5 of 5 timeouts |
| 27 | PC-BR2 | 10.10.30.200 (Server) | Reply | Reply, TTL 62 |
| 28 | PC-BR2 | 10.10.20.200 (Staff) | Blocked | 5 of 5 timeouts |
| 29 | PC-Mgmt | 10.30.0.200 (BR2) | Reply | Reply, TTL 62 |
| 30 | PC-Guest | 10.30.0.200 (BR2) | Blocked | 5 of 5 timeouts |
| 31 | PC-BR1 | 10.30.0.200 (BR2) | Reply via HQ | Reply, TTL 61 |

TTL 62 means two router hops (branch router and HQ). TTL 61 for branch-to-branch traffic means three hops (BR1, HQ, BR2), confirming the hub-and-spoke path.

### Screenshots

See the `images/` folder, files `18` to `26`. Hardening screenshots are files `27` to `31`.

## Router hardening (input chain)

Run after the input rules and service lockdown were applied on all three routers. Rule counts checked on the routers: R-HQ 21 filter rules in total (8 forward, 13 input), R-BR1 and R-BR2 10 input rules each, with `drop-all-input` present.

### R-HQ

| # | From | To | Expected | Result |
|---|---|---|---|---|
| 32 | PC-Guest | 10.10.40.1 (own gateway) | Reply | Pass |
| 33 | PC-Guest | 10.10.10.1 (router address in another VLAN) | Blocked | Pass |
| 34 | PC-Staff | 10.10.20.1 (own gateway) | Reply | Pass |
| 35 | PC-Staff | 10.10.30.1 (router address in another VLAN) | Blocked | Pass |
| 36 | PC-Mgmt | 10.10.10.1 | Reply | Pass |
| 37 | PC-BR1 | 10.10.10.1 (HQ router through the tunnel) | Blocked | Pass |
| 38 | PC-BR1 | 10.10.30.200 (Server, forwarded traffic) | Reply | Pass |
| 39 | PC-Staff | 203.0.113.1 (internet) | Reply | Pass |

### Branches

| # | From | To | Expected | Result |
|---|---|---|---|---|
| 40 | PC-BR1 | 10.20.0.1 (own gateway) | Reply | Pass |
| 41 | PC-BR1 | 203.0.113.6 (router WAN address) | Blocked | Pass |
| 42 | PC-BR1 | 10.10.30.200 (Server through HQ) | Reply | Pass |
| 43 | PC-Mgmt | 10.255.1.2 (BR1 tunnel address) | Reply | Pass |
| 44 | PC-Staff | 10.255.1.2 (BR1 tunnel address) | Blocked | Pass |
| 45 | PC-BR2 | 10.30.0.1 (own gateway) | Reply | Pass |
| 46 | PC-BR2 | 203.0.113.10 (router WAN address) | Blocked | Pass |
| 47 | PC-Mgmt | 10.255.2.2 (BR2 tunnel address) | Reply | Pass |
| 48 | PC-Staff | 10.255.2.2 (BR2 tunnel address) | Blocked | Pass |

Test 44 initially passed (reply) because the ICMP rule on R-BR1 had no source restriction. It was fixed by adding the `mgmt-nets` source address list, and the test then behaved as expected. The same restriction was applied on R-BR2 from the start.

### Side effects checked

- Traffic through the routers (internet, inter-site policy) kept working.
- R-HQ kept two OSPF neighbors in Full state, and each branch kept one.
- WireGuard handshakes continued to refresh on all peers.

Screenshots: files `27` to `31`.
