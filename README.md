# TherapOpsDocs

Welcome to **TherapOpsDocs** — the enterprise documentation and operational playbook for provisioning, hardening, and configuring Linux hosts (Oracle Linux 8) and mission-critical workloads (Application Servers, Standalone Databases, and Oracle RAC clusters).

---

## 🚀 Quick Start for Local Viewing

This repository is built using [MkDocs Material](https://squidfunk.github.io/mkdocs-material/). You can read the raw Markdown files directly in Git or spin up the interactive portal locally:

```bash
# 1. Create a virtual environment & install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2. Start the local documentation server
mkdocs serve
```

Then open `http://127.0.0.1:8000` in your browser.

---

## 🌐 Automatic GitHub Pages Deployment & Fail-Safe

This repository includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) using the official GitHub Pages deployment engine:

* **Strict Build Validation**: Runs `mkdocs build --strict`. If any broken link, malformed markdown, or syntax error is introduced, the build job immediately exits with an error.
* **Automatic Rollback / Fail-Safe**: Because the `deploy` job depends on `needs: build`, **no deployment artifact is published on failure**. The live site automatically stays on the last working deployment with **zero downtime or broken pages**.

### One-Time Setup in GitHub Repository:
1. Push this repository to GitHub.
2. In your GitHub repository, go to **Settings** → **Pages**.
3. Under **Build and deployment** → **Source**, select **GitHub Actions**.
4. Every push to `main` or `master` will automatically test, build, and publish the documentation.

---

## 🗺️ Provisioning Lifecycle Structure

The repository is modularized into 6 sequential phases:

```text
TherapOpsDocs/
├── mkdocs.yml                         # MkDocs configuration & navigation
├── requirements.txt                   # Python dependencies
├── docs/
│   ├── index.md                       # Home page & architecture diagram
│   ├── 01-pre-provisioning/
│   │   ├── index.md                   # Phase overview
│   │   ├── backup-runbook.md          # State capture & backup.sh execution
│   │   └── pxe-dhcp-setup.md          # Kickstart git workflow & DHCP leases
│   ├── 02-provisioning/
│   │   └── kickstart-execution.md     # Network boot & kickstart.log validation
│   ├── 03-post-install-base/
│   │   ├── index.md                   # Base OS overview
│   │   ├── cis-hardening.md           # CIS benchmark execution & audit
│   │   ├── repos-kernel.md            # UEK repo management & kernel pinning
│   │   ├── idm-sssd.md                # FreeIPA enrollment & Nagios SSSD plugin
│   │   └── security-syslog.md         # Crypto policies, rootsh, auditd & rsyslog
│   ├── 04-network-migration/
│   │   ├── index.md                   # Networking overview
│   │   ├── app-server.md              # Dual-NIC configuration for App hosts
│   │   ├── db-server.md               # DB & RAC multi-NIC setup (MTU 9000)
│   │   └── nic-naming-rules.md        # Persistent interface naming (systemd.link)
│   ├── 05-workload-specific/
│   │   ├── oracle-prereqs.md          # User hygiene, limits & preinstall RPMs
│   │   └── rac-storage-multipath.md   # NetApp iSCSI, Device-Mapper & ASMLib
│   └── 06-verification-handover/
│       ├── checklist.md               # Pre-handover signoff checklist
│       └── decommissioning.md         # Retiring old hosts from IDM and DNS
```

---

## 🔒 Security & Contribution Guidelines

1. **No Plaintext Passwords or Hashes**: Never commit unmasked password hashes or temporary OTP passwords. Use placeholders like `<OTP_PASSWORD>`.
2. **Atomic Markdown Guides**: Keep each runbook under 1–2 pages focusing on clear, verifiable commands.
3. **Verified Commands Only**: Do not include debugging trial-and-error logs in production documentation.
