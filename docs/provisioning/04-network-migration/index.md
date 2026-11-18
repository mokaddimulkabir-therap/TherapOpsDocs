# 4. Network Migration Phase

During initial Kickstart installation, hosts obtain a temporary IP from the PXE subnet (`192.168.48.x`).

In this phase:
1. Production interfaces are configured with static IPs via `nmcli`.
2. High-performance storage/private interconnect links are configured with **Jumbo Frames (MTU 9000)**.
3. Temporary provisioning connections are deleted.
4. Persistent interface naming (`systemd.link`) is applied if hardware interface names drift.

---

### Network Profiles by Role

* [App Server Network](app-server.md) — Standard dual-NIC configuration (Web/API + Service networks).
* [DB Server Network](db-server.md) — Multi-NIC setup with MTU 9000 storage interconnect.
* [Persistent NIC Naming](nic-naming-rules.md) — Resolving `ens33` vs `ens192` interface mismatches via systemd.
