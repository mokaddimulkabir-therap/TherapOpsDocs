# Initial Checks & Baseline Packages

When an Oracle Linux 8 compute instance launches in OCI, inspect initialization logs and install corporate baseline packages.

---

## 1. Cloud-Init Execution Validation

Log in using the `opc` user and key:

```bash
ssh -i opc_key opc@<HOST_IP>
```

Inspect cloud-init log for errors or failed system tasks:

```bash
cat cloud-init.out | grep -iE "failed|warning|error"
```

Verify DNF repos and current running kernel:

```bash
dnf repolist
uname -r
```

---

## 2. Baseline Package Verification & Installation

Check if any standard utility packages are missing:

```bash
rpm -q bash-completion bzip2 chrony gcc lsof mlocate mtr net-snmp nmap-ncat psmisc rhn-check rhn-setup rsync strace sysstat tcpdump unzip bind-utils vim-enhanced wget mailx net-tools tmux dnf-utils postfix | grep -E " is not installed$"
```

!!! note "`dnf-utils` is Expected to be Missing"
    In newly launched OCI images, `dnf-utils` is typically not installed by default and will be reported as missing by the query above. Search and install it alongside any other missing packages:
    ```bash
    dnf search dnf-utils
    ```

Install any missing required utilities:

```bash
dnf install -y bash-completion bzip2 chrony gcc lsof mlocate mtr net-snmp nmap-ncat psmisc rsync strace sysstat tcpdump unzip bind-utils vim-enhanced wget mailx net-tools tmux dnf-utils postfix
```

---

## 3. Host Resolution

Verify and update `/etc/hosts` with static internal resolutions for regional and management nodes:

```bash
vim /etc/hosts
```
