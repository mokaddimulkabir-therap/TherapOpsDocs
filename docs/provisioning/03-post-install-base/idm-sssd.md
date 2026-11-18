# FreeIPA / IDM Enrollment & SSSD Monitoring

All hosts must authenticate against the centralized FreeIPA / IDM realm (`THERAPBD.NET`) and configure SSSD backend health monitoring.

---

## 1. IDM Client Enrollment

Before enrolling, ensure the host can resolve `idm.therapbd.net` and `idm01-bd.therapbd.net`.

### Enrollment Command

```bash
ipa-client-install \
  --ip-address=<HOST_PROD_IP> \
  --server=idm.therapbd.net \
  --server=idm01-bd.therapbd.net \
  --domain=therapbd.net \
  --realm=THERAPBD.NET \
  --hostname=<HOSTNAME>.therapbd.net \
  --password="<ENROLLMENT_OTP_PASSWORD>" \
  --mkhomedir \
  --no-ntp
```

!!! note "Interactive Prompts During Enrollment"
    * If prompted: `Proceed with fixed values and no DNS discovery? [no]:` -> Type **`yes`**
    * If prompted: `Do you want to download the CA cert from ... (this is INSECURE) [no]:` -> Type **`yes`**

### Restart & Flush SSSD Cache
```bash
systemctl stop sssd
rm -rf /var/lib/sss/db/*
systemctl start sssd
```

---

## 2. SSSD Nagios Health Monitoring Plugin

Deploy the Nagios monitoring wrapper to verify SSSD backend connectivity via SNMP.

### Step 1: Download & Extract Plugin
```bash
# Create directory
mkdir -p /usr/local/nagios/plugins

# Download bundle from central server
curl -s http://192.168.48.239/nagios-plugin.zip -o /tmp/nagios-plugin.zip
unzip -q /tmp/nagios-plugin.zip -d /usr/local/nagios/

# Set ownership and executable permissions
chown -R root:root /usr/local/nagios/
chmod 750 /usr/local/nagios/plugins/check_sssd_backend_status*
```

### Step 2: Extend SNMP Daemon Configuration
Append the monitoring wrapper script to `/etc/snmp/snmpd.conf`:

```text
## Extending SSSD backend status monitoring plugin with wrapper script
extend sssd_backend_status /usr/local/nagios/plugins/check_sssd_backend_status_wrapper.sh
```

### Step 3: Restart SNMP Service
```bash
systemctl restart snmpd
systemctl status snmpd --no-pager
```
