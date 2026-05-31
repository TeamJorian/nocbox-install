# NOCBox installer

One-line installer for **NOCBox** — a turnkey ISP-monitoring appliance. This
script is public and holds no secrets: it pulls the **private** NOCBox image
with a vendor-issued read-only token, and a **license key** gates use.

## Install (fresh Ubuntu 22.04 / 24.04 box)

```
curl -fsSL https://raw.githubusercontent.com/TeamJorian/nocbox-install/main/install.sh -o nocbox-install.sh
NOCBOX_PULL_TOKEN=<your-pull-token> bash nocbox-install.sh
```

That's it — version defaults to `latest` and the pull user defaults to the
deploy bot, so the **token is the only thing you pass**. The installer then
prompts for hostname / admin / **license**.

- Pin a version: add `NOCMON_IMAGE_TAG=v0.2.3`.
- No Docker yet? It installs Docker, then asks you to log out/in and re-run once.

It installs Docker, pulls the deploy bundle + app image, brings up the stack,
and installs the host-agent — **no source code on the box**.
