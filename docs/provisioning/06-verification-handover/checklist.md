# Final Verification & Handover Checklist

Complete every item in this checklist before handing the provisioned or rebuilt node over to application, DBA, or operations teams.

---

## 📋 Comprehensive Handover Checklist

- [ ] Check KS log errors
- [ ] CIS benchmark executed and logs checked
- [ ] OS update complete (`dnf update`)
- [ ] `/usr/local` permissions verified
- [ ] `/` permissions verified
- [ ] `/home/oracle` permissions verified (if DB/RAC)
- [ ] Hosts file checked (`/etc/hosts`)
- [ ] IP configuration updated and verified
- [ ] rsyslog updated and restarted
- [ ] Root user shadow set (`root:$6$...`)
- [ ] Remote root login disabled in `/etc/ssh/sshd_config`
- [ ] logbak / sa permissions updated (`chmod 644 /var/log/sa/*`)
- [ ] Post-install checking script run
- [ ] Route table checked (`ip route`)
- [ ] Inventory documentation updated
- [ ] LAN changed after IP change
- [ ] Kernel version checked after reboot (`uname -r`)
- [ ] IP check (`ip a`, `hostname -I`)
- [ ] Spacewalk / ULN re-registered after IP change
- [ ] Chrony NTP check
- [ ] fstab check (`cat /etc/fstab`, `mount -a`)
- [ ] Check preinstall RPM installed (`rpm -qa | grep -i preinstall`)
- [ ] NFS mounts active (`/rman`, `/dumps_new`)
- [ ] Remove `dba`, `oinstall` from `/etc/group`
- [ ] Sync repo profile (`rhn-profile-sync`)
- [ ] Update `/etc/passwd`: `oracle:x:110:101::/home/oracle:/bin/bash`
- [ ] Update `/etc/shadow`: `oracle:!!:18353:0:99999:7:::`
- [ ] Verify sudo permissions (`sudo -l -U <username>`)
- [ ] Package install: Vector, nginx, Datadog if needed

---

## 📝 Standard Ticket Trace Command

Run and paste the exact output of this command into the handover ticket:

```bash
cat /etc/oracle-release; lsblk; grep 'MemTotal' /proc/meminfo; nproc; ip -f inet addr show | grep -Po 'inet \K[\d.]+' | grep -v 127
```

For RAC nodes, also append the RAC trace:

```bash
hostname; hostname -I
uname -r
rpm -qa | egrep 'policycoreutils-python|asm|19c'
su - oracle -c umask
df -hT /d00
```
