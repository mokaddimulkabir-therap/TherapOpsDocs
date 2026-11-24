# OCI Volume & LVM Management

OCI compute instances frequently require expanding root volumes or mounting block storage for applications, Jenkins workers, and Syslog-NG.

---

## 1. Expanding OCI Root Boot Volume

When increasing the boot volume size in the OCI Console:

```bash
# Scan disk changes
echo 1 > /sys/block/sda/device/rescan 2>/dev/null || true

# Partition additional space (e.g. sda4)
fdisk /dev/sda
partprobe /dev/sda

# Initialize Physical Volume and extend root volume group
pvcreate /dev/sda4
vgextend ocivolume /dev/sda4
lvextend -l +100%FREE /dev/ocivolume/root

# Grow XFS filesystem online
xfs_growfs /dev/ocivolume/root
df -h /
```

---

## 2. Common Workload Block Volume Setups

=== "Jenkins Worker Volume (`/usr/local/jenkins`)"
    ```bash
    fdisk /dev/sdb
    partprobe /dev/sdb
    pvcreate /dev/sdb1 
    vgcreate vg_jenkins /dev/sdb1
    lvcreate -n lv_jenkins -l 100%FREE vg_jenkins
    mkfs.xfs /dev/vg_jenkins/lv_jenkins

    mkdir -p /usr/local/jenkins
    # Add to /etc/fstab using UUID from blkid:
    # UUID=<UUID>  /usr/local/jenkins  xfs  defaults  0 0
    mount /dev/vg_jenkins/lv_jenkins /usr/local/jenkins
    ```

=== "App Volume (`/apps`)"
    ```bash
    fdisk /dev/sda
    partprobe /dev/sda
    pvcreate /dev/sda4
    vgcreate vg_app /dev/sda4
    lvcreate -n lv_apps -L 5G vg_app
    mkfs.xfs /dev/vg_app/lv_apps

    mkdir -p /apps
    # Retrieve filesystem UUID
    blkid /dev/vg_app/lv_apps

    # Append to /etc/fstab using UUID:
    # UUID=<UUID_FROM_BLKID>  /apps  xfs  defaults  0 0
    mount -a
    ```

=== "Logs Volume (`/logs`)"
    ```bash
    fdisk /dev/sdb
    partprobe /dev/sdb
    pvcreate /dev/sdb1
    vgcreate vg_logs /dev/sdb1
    lvcreate -n lv_logs -l 100%FREE vg_logs
    mkfs.xfs /dev/vg_logs/lv_logs

    mkdir -p /logs
    # Retrieve filesystem UUID
    blkid /dev/vg_logs/lv_logs

    # Append to /etc/fstab using UUID:
    # UUID=<UUID_FROM_BLKID>  /logs  xfs  defaults  0 0
    mount -a
    ```

=== "SFTP Server Volume (`/sftp`)"
    ```bash
    fdisk /dev/sda
    partprobe /dev/sda
    pvcreate /dev/sda1
    vgcreate vg_sftp /dev/sda1
    lvcreate -n lv_sftp -l 100%FREE vg_sftp
    mkfs.xfs /dev/vg_sftp/lv_sftp

    mkdir -p /sftp
    # Retrieve filesystem UUID
    blkid /dev/vg_sftp/lv_sftp

    # Append to /etc/fstab using UUID:
    # UUID=<UUID_FROM_BLKID>  /sftp  xfs  defaults  0 0
    mount -a
    ```

=== "Syslog-NG Dedicated Volume (`/syslogng`)"
    ```bash
    fdisk /dev/sdb
    partprobe /dev/sdb
    pvcreate /dev/sdb1
    vgcreate vg_syslogng /dev/sdb1
    lvcreate -n lv_syslogng -l 100%FREE vg_syslogng
    mkfs.xfs /dev/vg_syslogng/lv_syslogng

    mkdir -p /syslogng
    # Retrieve filesystem UUID
    blkid /dev/vg_syslogng/lv_syslogng

    # Append to /etc/fstab using UUID:
    # UUID=<UUID_FROM_BLKID>  /syslogng  xfs  defaults  0 0
    mount -a
    ```

---

## 3. Optional Directory Access Control (ACL)

If specific operational users need read/execute access to logging directories:

```bash
setfacl -m u:<USER>:rx /logs
```
