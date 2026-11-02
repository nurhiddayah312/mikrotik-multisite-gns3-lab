# VLAN Plan

## VLANs at HQ

| VLAN ID | Name | Network | Purpose |
|---|---|---|---|
| 10 | Management | 10.10.10.0/24 | Network administration and monitoring |
| 20 | Staff | 10.10.20.0/24 | Employee workstations |
| 30 | Server | 10.10.30.0/24 | Internal servers |
| 40 | Guest | 10.10.40.0/24 | Visitors, internet access only |

## Switch port assignment (SwitchVLAN, GNS3 Ethernet switch)

| Switch port | Type | VLAN | Connected to |
|---|---|---|---|
| 1 | dot1q (trunk) | all | R-HQ (to-SWITCH) |
| 2 | access | 10 | PC-Mgmt |
| 3 | access | 20 | PC-Staff |
| 4 | access | 30 | PC-Server |
| 5 | access | 40 | PC-Guest |

Ports 0, 6 and 7 are unused and left on VLAN 1.

## Inter-VLAN routing

R-HQ is the gateway for every VLAN (router-on-a-stick). One VLAN interface per VLAN is created on `to-SWITCH`, and each VLAN interface carries the gateway address (`10.10.X.1/24`). Traffic between VLANs is routed by R-HQ and controlled by firewall rules.

## Firewall policy

| From \ To | Management | Staff | Server | Guest | Internet |
|---|---|---|---|---|---|
| Management | - | Allow | Allow | Allow | Allow |
| Staff | Deny | - | Allow | Deny | Allow |
| Server | Deny | Replies only | - | Deny | Allow |
| Guest | Deny | Deny | Deny | - | Allow |

"Replies only" means answers to connections started by the other side are allowed, but the server cannot start new connections toward Staff. Internal traffic that is not explicitly allowed is dropped.

### Implemented rules on R-HQ (forward chain, in order)

| # | Action | Match | Purpose |
|---|---|---|---|
| 1 | accept | established, related | Allow replies |
| 2 | drop | invalid | Drop broken packets |
| 3 | accept | in vlan10-mgmt, out LAN list | Management reaches all VLANs |
| 4 | accept | in vlan20-staff, out vlan30-server | Staff reaches Server |
| 5 | drop | in LAN list, out LAN list | Block every other inter-VLAN flow |

Traffic toward `to-ISP` is not matched by rule 5, so internet access is unaffected.

## Site-to-site policy (traffic arriving through the tunnels)

| From | To | Decision |
|---|---|---|
| Branch | HQ Server (VLAN 30) | Allow |
| Branch | HQ Management, Staff, Guest | Deny |
| HQ Management, Staff | Branch | Allow |
| HQ Guest | Branch | Deny |
| Branch | Branch (through HQ) | Allow, by design (hub-and-spoke) |

Tunnel interfaces are members of an interface list named `TUNNEL`, so adding a new branch only requires adding its tunnel to that list.

### Additional rules on R-HQ (forward chain)

| # | Action | Match | Purpose |
|---|---|---|---|
| 6 | accept | in TUNNEL list, out vlan30-server | Branches reach the Server VLAN |
| 7 | drop | in TUNNEL list, out LAN list | Branches cannot reach other HQ VLANs |
| 8 | drop | in vlan40-guest, out TUNNEL list | Guest cannot reach branches |

(The rules were added after the five rules above and are listed as entries 5-7 by `/ip firewall filter print`, which numbers from 0.)

## Verification

| Test | Expected | Result |
|---|---|---|
| All four PCs get a DHCP lease from their own VLAN | Lease received | Pass |
| PC-Staff pings its gateway (10.10.20.1) | Reply | Pass |
| PC-Staff pings the simulated internet (203.0.113.1) | Reply | Pass |
| PC-Guest pings the simulated internet (203.0.113.1) | Reply | Pass |
| PC-Guest pings PC-Staff (10.10.20.200) | Blocked | Pass |
| PC-Staff pings PC-Server (10.10.30.200) | Reply | Pass |
| PC-Server pings PC-Staff (10.10.20.200) | Blocked | Pass |
| PC-Mgmt pings PC-Staff (10.10.20.200) | Reply | Pass |
| PC-Staff pings PC-Mgmt (10.10.10.200) | Blocked | Pass |

### Site-to-site policy tests

| Test | Expected | Result |
|---|---|---|
| PC-BR1 pings PC-Server (10.10.30.200) | Reply | Pass |
| PC-BR1 pings PC-Staff (10.10.20.200) | Blocked | Pass |
| PC-BR1 pings PC-Mgmt (10.10.10.200) | Blocked | Pass |
| PC-Mgmt pings PC-BR1 (10.20.0.200) | Reply | Pass |
| PC-Staff pings PC-BR1 (10.20.0.200) | Reply | Pass |
| PC-Guest pings PC-BR1 (10.20.0.200) | Blocked | Pass |
| PC-BR2 pings PC-Server (10.10.30.200) | Reply | Pass |
| PC-BR2 pings PC-Staff (10.10.20.200) | Blocked | Pass |
| PC-Mgmt pings PC-BR2 (10.30.0.200) | Reply | Pass |
| PC-Guest pings PC-BR2 (10.30.0.200) | Blocked | Pass |
| PC-BR1 pings PC-BR2 (10.30.0.200) | Reply (via HQ) | Pass |

Combinations not listed above follow from the same rules but were not tested individually.

## Known limitations

- Only the `forward` chain is filtered. The `input` chain (access to R-HQ itself, for example from the Guest VLAN or from the branches) is not hardened yet and is planned as a separate step.
- Rules are tested with ICMP only. TCP/UDP service tests are planned once a server host is added.
