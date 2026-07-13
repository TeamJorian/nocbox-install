# NOCBox Quick Start

A one-page guide to get **NOCBox** running on your own box and see your first
latency graph — about 15 minutes. This is for **free testers**: you install it
yourself and (optionally) start a free trial right in the UI. No source code, no
YAML hand-editing.

> **A note on support.** NOCBox Lite is **free**, and it's built by a very small
> team — honestly, mostly one busy human. So support is **best-effort**: we
> genuinely try to help, but can't promise fast replies. The good news — the box
> is designed to run itself, this guide covers the common path, and the **Send
> feedback** button inside NOCMON (step 9) reaches us *with* the diagnostics we
> need to actually help. Need guaranteed response times and hands-on setup?
> That's what the paid editions are for.

---

## 1. What you need

- A clean **Ubuntu Server 22.04 or 24.04 LTS** box — a VM is fine (Proxmox,
  XCP-ng, VMware, or bare metal). 4 CPU / 16 GB RAM / ~250 GB disk is comfortable.
- A login on that box with **`sudo`**.
- **Outbound internet** (to pull the Docker image).
- A **static IP** for the box (so monitoring doesn't drift on a DHCP renewal).
- The **pull token** we gave you (a `read:packages` token). Keep it handy — you
  paste it during install, and it is never shown on screen.

Docker does **not** need to be pre-installed — the installer adds it if missing.

> A single-NIC / flat-LAN box works fine. You do **not** need VLANs to test —
> NOCBox supports "No VLAN" probes that monitor straight from the box.

---

## 2. Install (two commands)

SSH into the box as your normal `sudo` user (not root) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/TeamJorian/nocbox-install/main/install.sh -o nocbox-install.sh
bash nocbox-install.sh
```

That's it. The installer **pulls the prebuilt image** (no building from source),
writes secrets, and starts the stack.

**If it had to install Docker:** the first run installs Docker, then asks you to
**log out, log back in, and re-run** (`bash nocbox-install.sh`) so your user
picks up the `docker` group. The second run does the real install.

Run the script as your **normal user**, not with `sudo` in front — it calls
`sudo` itself only for the parts that need root.

### What it asks you

1. **License pull token** → paste the token at the prompt. Input is hidden
   (nothing is echoed or saved to your shell history).
2. **Hostname / IP** NOCMON is served at → press Enter to accept the detected IP,
   or type a DNS name if you have one pointed at the box.
3. **Admin email** → your NOCMON login email.
4. **Admin password** → leave blank to auto-generate. Either way it is **printed
   at the end and saved in `/opt/nocbox/.env`** — note it down.

---

## 3. First login

1. Browse to **`https://<your-host-or-IP>/`**.
2. On a LAN IP the certificate is **self-signed**, so the browser warns once —
   accept it and continue. (On a public DNS name with ports 80/443 open, NOCBox
   gets a real Let's Encrypt cert and there's no warning.)
3. Log in with the **admin email + password** the installer printed (also in
   `/opt/nocbox/.env`).

---

## 4. Accept the EULA

On your first login you'll see the **license agreement**. Read it, tick the box,
and click accept — a one-time clickwrap.

---

## 5. Start your free 30-day Pro trial (optional)

Out of the box NOCBox is **already working** as the free **Lite** floor:
monitoring, dashboards, Telegram alerts, and adding your first Site → ISP →
probe (up to 1 site / 5 probes) all work right now — **no license, no
activation, not read-only**.

To lift those caps for 30 days (multi-site, unlimited probes, and the rest of
Pro), start a free trial:

1. Open the **License** page (`/license`).
2. On the **"Get your free license"** tab, your email is pre-filled from your
   admin account (editable); optionally add your WISP name / location.
3. Click **Start free trial**. The box mints + self-activates a **30-day Pro
   trial bound to this box** and lifts the caps **immediately** — no payment, no
   key to paste, no restart.

When the trial ends (we email you at 7 / 2 / 0 days) the box **downgrades
gracefully back to the Lite floor** — over-cap sites/probes pause, nothing is
deleted, monitoring keeps running.

> **SMS alerts** are a paid feature and are **not** part of the trial. Email +
> **Telegram** alerting work on Lite and on the trial.
>
> **Got a purchase / claim code?** If we sent you a short code (like
> `NB-7Q4K-9F2D`), open the **"I have a purchase code"** tab and enter it — the
> box redeems it and activates a paid license bound to this box in one step.

---

## 6. See your first latency graph

You don't need VLANs to test. On a flat / single-uplink box:

1. **Add a Site**, then an **ISP** under it.
2. **Add a VLAN probe** and tick **"No VLAN — monitor from this box"**. You only
   need a name; there's no VLAN tag or source IP to enter.
3. **Assign targets** to the probe — what it pings (e.g. `8.8.8.8`, `1.1.1.1`,
   `facebook.com`).
4. Click **Apply Config**. NOCMON generates and reloads Prometheus + Blackbox.
5. Open **Grafana** at `https://<host>/grafana` (username `admin`, password = the
   same admin password). Give it a minute or two of scraping, then your probe's
   **latency and packet-loss** start showing.

That's a full loop: install → (optional) start trial → monitor.

---

## 7. Multi-ISP? Pin each probe to a specific ISP (VLAN probes)

The question every multi-ISP operator asks us: **"if all my uplinks sit behind
one router, how does NOCBox know its ping went out a *specific* ISP?"**

By itself it can't — a "No VLAN" probe's pings follow your router's default
route like any other LAN traffic, so with three ISPs you're really graphing
*whichever uplink happens to be default right now*. Per-ISP monitoring works
by giving each probe its **own source IP on its own VLAN**, and telling your
router to force each VLAN out one specific uplink. Three parts:

**On the router** — say NOCBox is plugged into `eth5` of a MikroTik RB5009:

1. **Trunk the NOCBox port.** Add one tagged VLAN per ISP on `eth5` — e.g.
   VLAN `101` = ISP A, VLAN `102` = ISP B. One cable carries as many VLANs
   (and gateways) as you have uplinks.
2. **Give the router a gateway IP on each VLAN.** Follow NOCBox's addressing
   convention and NOCMON will fill every field in for you later: VLAN `101` →
   router takes `10.150.101.1/24`, VLAN `102` → `10.150.102.1/24`, and so on.
3. **Policy-route each VLAN to its ISP** (PBR): traffic sourced from
   `10.150.101.0/24` must egress ISP A, from `10.150.102.0/24` must egress
   ISP B — and your NAT rule must cover these new subnets. This is the step
   that makes the graphs honest: the *router* pins the path, so a probe's
   ping physically cannot sneak out the wrong uplink.

<details>
<summary><b>MikroTik example</b> (RouterOS v7 — VLAN 101 → ISP A)</summary>

```
/interface vlan add interface=ether5 vlan-id=101 name=vlan101-nocbox
/ip address add address=10.150.101.1/24 interface=vlan101-nocbox
/routing table add name=to-ispA fib
/ip route add dst-address=0.0.0.0/0 gateway=<ISP-A-gateway> routing-table=to-ispA
/routing rule add src-address=10.150.101.0/24 action=lookup-only-in-table table=to-ispA
```

Repeat with VLAN `102` → `to-ispB`, etc. Notes: this assumes `ether5` is a
standalone port (on a bridged port, use bridge VLANs instead);
`lookup-only-in-table` is deliberate — when ISP A dies, its probe should show
**DOWN**, not silently fail over to ISP B; and check your srcnat/masquerade
also matches `10.150.x.0/24`, or the pings leave un-NATted and die quietly.
</details>

**Running NOCBox as a VM?** Trunk the tags through to the guest — on Proxmox
tick **VLAN aware** on the bridge and leave the VM NIC's **VLAN Tag blank**,
so tagged frames reach the VM. (Same idea on ESXi: VLAN 4095 / trunk port
group.)

**In NOCMON:**

4. Add one **VLAN probe** per ISP: pick the Site + ISP, enter the **VLAN ID**
   and the **parent interface** (the NIC the trunk lands on — the form lists
   the NICs it detected). Source IP, gateway, prefix, and routing table
   **auto-derive from the VLAN ID** (`10.150.<vlan>.40`, gateway `.1`, /24).
   Used different addressing on the router? Open **Advanced networking** —
   the probe's static source IP / gateway / prefix live there.
5. Click **Apply Host Config**. NOCBox writes the VLAN interfaces and per-ISP
   source routing on the box and applies them with a **60-second
   auto-rollback** window (via the host-agent the installer already set up) —
   confirm in the UI to keep the change. From here on, each probe's pings are
   **bound to its VLAN's source IP**, ride that VLAN to the router, and get
   policy-routed out their own ISP. Every time.

Assign targets to each probe and **Apply Config** as in step 6 — Grafana now
graphs every ISP's latency and loss side by side, apples to apples.

> **No VLANs in your network?** There's a flat-LAN shortcut: a "No VLAN" probe
> can still **bind a static source IP** (set it right in the probe form —
> NOCBox can even create the IP on the NIC for you). Reserve one IP per ISP,
> then policy-route by *source address* on the router the same way. VLANs are
> the cleaner setup, but this works with zero switching changes.

---

## 8. (Optional) Reach it from outside your network

No static public IP? Behind CGNAT? You can still reach the dashboard from
anywhere without forwarding ports, using a Cloudflare Tunnel — **ask us** and
we'll send the short walkthrough.

---

## 9. Send us feedback

Hit a bug, or have an idea? Don't go hunting for our DM — there's a **Send
feedback** button right in NOCMON:

- the **top-right of the header** (next to "Sign out"), and
- the **bottom of the left sidebar**.

It's on **every page**, on **every edition**, even before you've activated a
license. Click it and:

1. Type what happened or what you'd like.
2. Leave **"Include diagnostics"** ticked — it attaches a short, **non-sensitive**
   box summary (NOCBox version + edition, your install ID, hostname/OS, which
   services are up/down, and how many probes/targets you have). You can read the
   exact text before it is sent. **No secrets** — no passwords, no tokens, no
   license key.
3. Click **Send via Messenger** (we copy your message to the clipboard so you can
   paste it into the chat that opens), or **Email instead** for a pre-filled
   email.

That diagnostics summary is exactly what we'd otherwise have to ask you for, so
including it gets your issue sorted faster.
