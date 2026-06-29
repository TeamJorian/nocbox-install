# NOCBox installer

One-line installer for **NOCBox** — a turnkey ISP/WISP monitoring appliance.
Public and secret-free: it pulls the **private** NOCBox image with a
vendor-issued read-only token. Once it's up, **NOCBox runs free** as the Lite
tier — no license needed; paid editions (Pro / Enterprise) unlock more.

**New here? Start with the [Quick Start guide](QUICKSTART.md)** — install →
first login → your first latency graph, in about 15 minutes.

## Install (fresh Ubuntu 22.04 / 24.04 box)

Interactive (prompts for hostname / admin login):
```
curl -fsSL https://raw.githubusercontent.com/TeamJorian/nocbox-install/main/install.sh -o nocbox-install.sh
NOCBOX_PULL_TOKEN=<your-pull-token> bash nocbox-install.sh
```

Fully unattended (no prompts):
```
NOCBOX_PULL_TOKEN=<token> \
  NOCMON_ADMIN_EMAIL=you@example.com NOCMON_ADMIN_PASSWORD=<password> \
  bash nocbox-install.sh
# (optional) add NOCBOX_LICENSE=<key> to activate a paid edition non-interactively
```

Defaults: version `latest`, pull user `teamjorian-deploy`. Pin a version with
`NOCMON_IMAGE_TAG=v0.2.3`. No Docker yet? It installs Docker, then asks you to
log out/in and re-run once. Activating a paid license is optional and done in
the NOCMON UI after first login — see the [Quick Start](QUICKSTART.md).

Installs Docker, pulls the deploy bundle + app image, brings up the stack, and
installs the host-agent — **no source code on the box**.

## A note on support

NOCBox Lite is **free**, and it's built by a very small team — honestly, mostly
one busy human. Support is **best-effort**: we genuinely try to help, but can't
promise fast replies. The box is built to mostly run itself, the
[Quick Start](QUICKSTART.md) covers the common path, and there's a **Send
feedback** button inside NOCMON that reaches us with the diagnostics we need.
Need guaranteed response times and hands-on setup? That's what the paid editions
are for.
