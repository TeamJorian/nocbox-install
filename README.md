# NOCBox installer

One-line installer for **NOCBox** — a turnkey ISP-monitoring appliance.
This script is public; it contains no secrets. It pulls the **private** NOCBox
image with a vendor-issued read-only token, so you need three things from your
NOCBox vendor: a **pull token**, the **version tag**, and a **license key**.

## Install (fresh Ubuntu 22.04/24.04 box)

```
curl -fsSL https://raw.githubusercontent.com/TeamJorian/nocbox-install/main/install.sh -o nocbox-install.sh
NOCMON_IMAGE_TAG=v0.2.3 NOCBOX_PULL_USER=<bot-user> NOCBOX_PULL_TOKEN=<token> bash nocbox-install.sh
```

(Download-then-run, not piped, so the installer can prompt for hostname / admin
/ license. You can also run `bash nocbox-install.sh` with no env and answer
every prompt.)

It installs Docker, pulls the deploy bundle + app image, brings up the stack,
and installs the host-agent — no source code on the box.
