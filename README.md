# NOCBox installer

One-line installer for **NOCBox** — a turnkey ISP-monitoring appliance. Public,
no secrets: it pulls the **private** NOCBox image with a vendor-issued read-only
token, and a **license key** gates use.

## Install (fresh Ubuntu 22.04 / 24.04 box)

Interactive (prompts for hostname / admin / license):
```
curl -fsSL https://raw.githubusercontent.com/TeamJorian/nocbox-install/main/install.sh -o nocbox-install.sh
NOCBOX_PULL_TOKEN=<your-pull-token> bash nocbox-install.sh
```

Fully unattended (no prompts):
```
NOCBOX_PULL_TOKEN=<token> NOCBOX_LICENSE=<license-key> \
  NOCMON_ADMIN_EMAIL=you@example.com NOCMON_ADMIN_PASSWORD=<password> \
  bash nocbox-install.sh
```

Defaults: version `latest`, pull user `teamjorian-deploy`. Pin a version with
`NOCMON_IMAGE_TAG=v0.2.3`. No Docker yet? It installs Docker, then asks you to
log out/in and re-run once.

Installs Docker, pulls the deploy bundle + app image, brings up the stack, and
installs the host-agent — **no source code on the box**.
