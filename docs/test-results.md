# Test Results

All tests were run from the VPCS clients in the GNS3 lab after configuring R-HQ (VLANs, DHCP, NAT, firewall).

## DHCP

| Client | VLAN | Address received | Gateway |
|---|---|---|---|
| PC-Mgmt | 10 | 10.10.10.200/24 | 10.10.10.1 |
| PC-Staff | 20 | 10.10.20.200/24 | 10.10.20.1 |
| PC-Server | 30 | 10.10.30.200/24 | 10.10.30.1 |
| PC-Guest | 40 | 10.10.40.200/24 | 10.10.40.1 |

Each client received an address from its own VLAN pool, and the DHCP server shown in `show ip` is the VLAN gateway on R-HQ.

## Connectivity and policy

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

## Screenshots

See the `images/` folder, files `05` to `11`.
