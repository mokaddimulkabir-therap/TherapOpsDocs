# Database Server Network Configuration

Standalone database hosts and RAC nodes require specialized network tuning:
1. **Management Network**: Default gateway and DNS resolvers (MTU 1500).
2. **Storage / Private Interconnects**: iSCSI SAN and Oracle Clusterware interconnects with **MTU 9000 (Jumbo Frames)**.

---

## 1. Standalone DB Server Configuration

Configure the management and private storage interfaces:

### Management Interface (`ens33` / `192.168.49.x`)
```bash
nmcli connection add type ethernet con-name ens33 ifname ens33 \
  ipv6.method ignore \
  ipv4.method manual \
  ipv4.never-default no \
  connection.autoconnect yes \
  ipv4.ignore-auto-dns yes \
  ipv4.addresses <DB_PUB_IP>/24 \
  ipv4.gateway <DB_PUB_GATEWAY> \
  ipv4.dns 192.168.49.54,192.168.54.54 \
  ipv4.dns-search therapbd.net \
  ipv4.dns-options "timeout:1 attempts:2" \
  802-3-ethernet.mtu 9000
```

### Private Storage Interface (`ens35` / `10.49.49.x`)
```bash
nmcli connection add type ethernet con-name ens35 ifname ens35 \
  ipv6.method ignore \
  ipv4.method manual \
  connection.autoconnect yes \
  ipv4.never-default yes \
  ipv4.addresses <DB_STORAGE_IP>/24 \
  802-3-ethernet.mtu 9000
```

---

## 2. Oracle RAC Multi-NIC Configuration Template

Oracle RAC nodes typically bind 6+ interfaces across public, private interconnect, and redundant storage paths:

```bash
# 1. Public Management (ens192)
nmcli connection add type ethernet con-name ens192 ifname ens192 \
  ipv6.method ignore ipv4.method manual ipv4.never-default no \
  connection.autoconnect yes ipv4.ignore-auto-dns yes \
  ipv4.addresses 192.168.59.132/24 ipv4.gateway 192.168.59.2 \
  ipv4.dns 192.168.51.54,192.168.54.54 ipv4.dns-search therapbd.net \
  ipv4.dns-options "timeout:1 attempts:2"

# 2. iSCSI Storage Path A (ens161) - MTU 9000
nmcli connection add type ethernet con-name ens161 ifname ens161 \
  ipv6.method ignore ipv4.method manual connection.autoconnect yes \
  ipv4.ignore-auto-dns yes ipv4.addresses 10.49.50.132/24 802-3-ethernet.mtu 9000

# 3. Cluster Interconnect Path 1 (ens35) - MTU 9000
nmcli connection add type ethernet con-name ens35 ifname ens35 \
  ipv6.method ignore ipv4.method manual connection.autoconnect yes \
  ipv4.ignore-auto-dns yes ipv4.addresses 10.9.51.132/24 802-3-ethernet.mtu 9000

# 4. Cluster Interconnect Path 2 (ens36) - MTU 9000
nmcli connection add type ethernet con-name ens36 ifname ens36 \
  ipv6.method ignore ipv4.method manual connection.autoconnect yes \
  ipv4.ignore-auto-dns yes ipv4.addresses 10.9.52.132/24 802-3-ethernet.mtu 9000

# 5. iSCSI Storage Path B (ens38) - MTU 9000
nmcli connection add type ethernet con-name ens38 ifname ens38 \
  ipv6.method ignore ipv4.method manual connection.autoconnect yes \
  ipv4.ignore-auto-dns yes ipv4.addresses 10.49.59.132/24 802-3-ethernet.mtu 9000

# 6. Backup / RMAN Network (ens39) - MTU 9000
nmcli connection add type ethernet con-name ens39 ifname ens39 \
  ipv6.method ignore ipv4.method manual connection.autoconnect yes \
  ipv4.ignore-auto-dns yes ipv4.addresses 10.49.49.197/24 802-3-ethernet.mtu 9000
```

---

## 3. Remove Stale / Provisioning Interfaces

```bash
# Delete temporary PXE profile
nmcli connection delete ops48 2>/dev/null || true

# Verify status of all devices
nmcli device status
ip route
```
