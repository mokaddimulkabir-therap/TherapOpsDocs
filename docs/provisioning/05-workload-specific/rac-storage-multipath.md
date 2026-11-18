# RAC Storage, iSCSI & NetApp Multipath

Oracle RAC nodes connect to NetApp Clustered ONTAP LUNs over dual-path iSCSI. Multipath handles path failover and load balancing.

---

## 1. iSCSI Initiator Configuration

### Step 1: Set Persistent Initiator Name
Update `/etc/iscsi/initiatorname.iscsi` with the node's specific initiator IQN (preserved from pre-provisioning backup):

```text
InitiatorName=iqn.1988-12.com.oracle:<HOSTNAME>-86d1731286f
```

### Step 2: Enable & Restart iSCSI Daemon
```bash
systemctl enable iscsid.service --now
systemctl restart iscsid.service
systemctl status iscsid.service --no-pager
```

### Step 3: Discover & Login to NetApp Storage Portals
Discover the target portals across both storage networks:

```bash
# Portal 1 (Path A)
iscsiadm --mode discoverydb --type sendtargets --portal 10.49.50.61:3260 --discover

# Portal 2 (Path B)
iscsiadm --mode discoverydb --type sendtargets --portal 10.49.50.62:3260 --discover

# Enable and start iscsi session service
systemctl enable iscsi.service --now
```

---

## 2. NetApp Device-Mapper Multipath Configuration

### Step 1: Multipath Configuration File
Ensure `/etc/multipath.conf` is in place with strict permissions:

```bash
chmod 600 /etc/multipath.conf
systemctl enable multipathd.service --now
systemctl restart multipathd.service
```

### Step 2: Verify Multipath Topology
Check that all expected LUN aliases are active with ALUA active/enabled paths:

```bash
multipath -ll
```

*Example LUN Aliases Expected:*
* `ocr31` (100G) — Cluster Registry (ASM)
* `gimr31` (250G) — Grid Management Repo (ASM)
* `ogg31` (500G) — GoldenGate Data (ASM)
* `reco31` (512G) — Fast Recovery Area (ASM)
* `data31` through `data36` (1.0TB each) — Database Diskgroups (ASM)
* `orabin32` (250G) — Local Oracle / Grid binaries filesystem

### Step 3: Validate NetApp Storage LUNs with `sanlun`
```bash
sanlun lun show -pv
```

---

## 3. Dedicated Binary Filesystem (`/d00`)

The `orabin` multipath device hosts local binaries under `/d00`.

!!! warning "Avoid Direct SCSI Writes"
    Always operate on the multipath device `/dev/mapper/orabin<ID>` rather than underlying raw SCSI paths (`/dev/sdb`, `/dev/sdd`) to prevent kernel path synchronization errors.

```bash
# Create XFS filesystem on the partition
mkfs.xfs /dev/mapper/orabin32p1 -f

# Create mount directory and set permissions
mkdir -p /d00
chown -R root:oinstall /d00
chmod 755 /d00
```

### Update `/etc/fstab` for Persistent Mount
Add the binary volume and corporate NFS backup shares to `/etc/fstab`:

```text
# Local Oracle binaries
/dev/mapper/orabin32p1                      /d00            xfs     defaults,_netdev        0 0

# Shared NFS backup and dump points
10.49.49.72:/bddbmaster01_rman_20210425     /rman           nfs     rw,bg,hard,nfsvers=3,timeo=600,rsize=65536,wsize=65536,nointr,suid 0 0
10.49.49.71:/db_dumps_20190825             /dumps_new      nfs     rw,bg,hard,nfsvers=3,timeo=600,rsize=65536,wsize=65536,nointr,suid 0 0
```

Apply mounts:
```bash
systemctl daemon-reload
mount -a
df -hT /d00 /rman /dumps_new
```
