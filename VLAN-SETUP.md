# Multi-ISP setup — per-ISP VLAN probes + policy routing

**This is the guide [QUICKSTART §7](QUICKSTART.md#7-multi-isp-pin-each-probe-to-a-specific-isp) points at.**

You don't need any of this to test NOCBox — a "No VLAN" probe works on a flat LAN
and gives you real latency and loss graphs. You need this when you have **more
than one uplink** and want to know *which* ISP is hurting.

Roughly **45 minutes** the first time, most of it on the router.

---

## The problem this solves

A plain probe's pings follow your router's **default route**, like any other
traffic on your LAN. So with three ISPs, a single probe isn't measuring three
ISPs — it's measuring *whichever uplink happens to be default right now*. Three
probes pinging the same target from the same box all leave through the same
uplink and produce three near-identical graphs.

To compare ISPs honestly, each probe needs a **source IP the router can
recognise**, and the router needs a rule that forces traffic from that source
out one specific uplink. Then every probe pings the *same* targets over a
*different* ISP — and the graphs are finally comparable.

Two parts, and **both are required**:

| Where | What | Who does it |
|---|---|---|
| **The router** | A VLAN per ISP + a policy-routing rule pinning each VLAN's subnet to one uplink | **You**, by hand (this guide) |
| **The NOCBox** | The VLAN sub-interfaces + source IPs + the box's own source-routing | **NOCMON**, generated and applied for you |

NOCBox never logs into your router. The router half is yours.

---

## The topology

One trunk cable carries every ISP's probe VLAN. The uplinks stay exactly where
they are; your default route is **not** touched.

```
        ISP A            ISP B            ISP C
          │                │                │
       ether1           ether2           ether3        ← your existing uplinks,
          │                │                │             untouched
          └────────────────┼────────────────┘
                           │
                  ┌────────┴─────────┐
                  │  MikroTik RB5009 │
                  │                  │
                  │  routing tables: │   isp101 → default via ISP A
                  │                  │   isp102 → default via ISP B
                  │                  │   isp103 → default via ISP C
                  │                  │
                  │  routing rules:  │   from 10.150.101.0/24 → isp101
                  │                  │   from 10.150.102.0/24 → isp102
                  │                  │   from 10.150.103.0/24 → isp103
                  └────────┬─────────┘
                           │
                        ether5          ← ONE trunk cable,
                    (tagged 101,102,103)   tagged with every probe VLAN
                           │
                  ┌────────┴─────────┐
                  │   NOCBox host    │
                  │                  │
                  │  eth0            │  10.0.0.10   management + default route
                  │  eth0.101 ───────┼─ 10.150.101.40   probe source, ISP A
                  │  eth0.102 ───────┼─ 10.150.102.40   probe source, ISP B
                  │  eth0.103 ───────┼─ 10.150.103.40   probe source, ISP C
                  │                  │
                  │  Blackbox binds each source IP and pings
                  │  8.8.8.8 / 1.1.1.1 / facebook.com from ALL THREE
                  └──────────────────┘
```

The payoff is the last line: **the same targets, pinged through every uplink**,
so a latency or loss difference between the series is a difference between
*ISPs* and not between targets.

> No SVG ships with this guide — the diagram above is plain text on purpose, so
> it renders everywhere and can't drift out of sync with the addressing below.
> A polished graphic for marketing use is a separate job.

---

## The addressing convention

NOCMON derives everything from the **VLAN ID** so you only ever type an ISP and
a number. For VLAN `<n>` (any 1–254):

| Thing | Value | Lives on |
|---|---|---|
| Probe source IP | `10.150.<n>.40` | **the NOCBox** |
| Gateway | `10.150.<n>.1` | **the router** |
| Prefix | `/24` | both |
| Interface name | `vlan<n>` | the NOCBox |
| Routing-table name | `isp<n>` | both (independently) |

So VLAN 101 → box `10.150.101.40`, router `10.150.101.1`, table `isp101`.

Two things worth knowing before you commit to numbers:

- **VLAN IDs above 254 don't auto-derive.** The VLAN ID is the third octet, so
  255+ overflows. Those still work — you just type the IPs yourself in the
  probe form's **Advanced networking** section.
- **The default is a `/24` per ISP, not a `/30`.** A `/30` is tidier and works
  fine, but you'll be entering the addressing by hand in **Advanced
  networking** rather than letting it derive. For a link that carries exactly
  one prober, either is fine — take the `/24` unless you have a reason.

You can use entirely different subnets. The convention just spares you the typing.

---

## Part A — the router (MikroTik RouterOS v7)

Below is the block for **one ISP**. Read it, change the four marked values, then
repeat per uplink.

```rsc
# ── VLAN 101 = ISP A ─────────────────────────────────────────────
# CHANGE: ether5      → the port your NOCBox is plugged into
# CHANGE: ether1      → the interface facing ISP A
# CHANGE: 100.64.1.1  → ISP A's next-hop gateway (what your main
#                       default route for ISP A already points at)

# 1. The probe VLAN, on the NOCBox-facing port.
/interface vlan
add name=vlan101-nocbox vlan-id=101 interface=ether5 \
    comment="nocbox: probe VLAN for ISP A"

# 2. The ROUTER's address on that VLAN — this is the probe's gateway.
#    Note .1, not .40. The .40 belongs to the NOCBox; putting it here
#    creates a duplicate-IP conflict with the box.
/ip address
add address=10.150.101.1/24 interface=vlan101-nocbox \
    comment="nocbox: gateway for probe VLAN 101"

# 3. A routing table just for this ISP.
/routing table
add name=isp101 fib comment="nocbox: per-ISP table for VLAN 101"

# 4. Inside that table, the default route points at ISP A's next hop.
#    This is the ISP's gateway, NOT 10.150.101.1.
/ip route
add dst-address=0.0.0.0/0 gateway=100.64.1.1 routing-table=isp101 \
    comment="nocbox: force VLAN 101 out ISP A"

# 5. The rule that sends this VLAN's traffic into that table.
#    Without this, steps 3-4 are inert — nothing looks in isp101.
/routing rule
add src-address=10.150.101.0/24 action=lookup-only-in-table table=isp101 \
    comment="nocbox: VLAN 101 -> ISP A"

# 6. NAT, so probes leave with a valid public source on ISP A.
#    out-interface is REQUIRED, not optional — see the note below.
/ip firewall nat
add chain=srcnat src-address=10.150.101.0/24 out-interface=ether1 \
    action=masquerade comment="nocbox: NAT VLAN 101 out ISP A"
```

Then repeat for VLAN 102 → ISP B (`10.150.102.0/24`, table `isp102`,
`out-interface=ether2`) and so on.

Finally, make sure the NOCBox port actually carries the tags. On a **standalone**
port, step 1 is enough. On a **bridged** port you must add the VIDs to the bridge
VLAN table instead:

```rsc
/interface bridge vlan
add bridge=bridge1 tagged=bridge1,ether5 vlan-ids=101,102,103
```

### Four things that decide whether this works

**`lookup-only-in-table`, not `lookup`.** With plain `lookup`, a probe whose ISP
is down silently falls back to the main table and exits a *different* ISP — the
graph goes green and lies to you. `lookup-only-in-table` drops instead, so a
dead ISP reads **DOWN**, which is the entire point of the exercise.

**Always set `out-interface` on the NAT rule.** A masquerade rule without it
keeps firing after a route change and NATs to the wrong uplink's address,
which breaks the probe quietly. (This is the same NAT-follows-route invariant
NOCBox's RouteGuard enforces internally.)

**`.1` on the router, `.40` on the box.** Easy to fumble, and the failure is
confusing: a duplicate address that works until ARP resolves the wrong way.

**Your default route is untouched.** Nothing above writes to the `main` table.
Customer traffic keeps doing exactly what it does today; only the three probe
subnets get pinned.

---

## Part B — the NOCBox (all in NOCMON)

1. **Sites → add a Site**, then an **ISP** under it — one ISP row per uplink.

2. **VLAN Probes → Add probe.** Per probe:
   - **Site** and **ISP**
   - **Name** — e.g. `ispA-probe`
   - Leave **"No VLAN — monitor from this box"** *unticked*
   - **VLAN ID** — `101`
   - **Parent interface** — the NIC the trunk lands on (`eth0`); the form lists
     the NICs it detected

   **Advanced networking** stays collapsed unless you need it. Open it to see or
   override the derived **VLAN interface**, **Source IP**, **Gateway IP**,
   **Prefix (CIDR)**, **Routing table name**, and the per-ISP **DNS server**
   (used by Diagnostics for lookups through that ISP).

3. **Apply Host Config.** NOCMON shows a diff, then applies it through the
   host-agent with a **60-second commit-confirmed** window: click **Confirm** in
   the UI or the box **auto-rolls back** to the previous config. That safety net
   is why a bad VLAN config can't strand you — same model as MikroTik's
   `/safe-mode`.

   > **What actually lands:** a single netplan file, `/etc/netplan/99-nocmon.yaml`,
   > declaring the VLAN interfaces, their addresses, the `ip rule` per probe
   > (priority 10000) and the per-ISP table routes. **Netplan owns all of it.**
   > The apply script only *verifies* the rules and routes came up; it never
   > adds them itself.
   >
   > This matters to you as an operator: it means a routine `sudo netplan apply`
   > or a reboot **re-creates** your probe routing instead of wiping it. Boxes
   > configured before this behaviour landed need **one** Apply Host Config to
   > take ownership — until then, a bare `netplan apply` silently kills VLAN
   > probe monitoring.
   >
   > Corollary: **don't hand-add `ip rule` / `ip route` entries for probes.** Two
   > owners fighting is how you get a config that works until the next reboot.

4. **Assign targets** to each probe — the same targets on every probe, that's
   what makes them comparable (`8.8.8.8`, `1.1.1.1`, `facebook.com`).

5. **Apply Config.** Generates and reloads Prometheus + Blackbox.

---

## Verify it actually works

**On the box** — the interfaces, rules and routes:

```bash
ip -4 addr show                    # one 10.150.<n>.40 per probe VLAN
ip rule show pref 10000            # one "from 10.150.<n>.40 lookup isp<n>" per probe
ip route show table isp101         # connected subnet + default via 10.150.101.1
```

**The real test — does each probe leave via its own ISP?** Ping a target that
tells you your public IP path, source-bound to each probe address in turn:

```bash
curl --interface 10.150.101.40 -s https://ifconfig.me ; echo
curl --interface 10.150.102.40 -s https://ifconfig.me ; echo
```

**Different public IPs = it's working.** Same IP on both means the rule isn't
matching and both are following the default route — recheck step 5 of Part A.

**In NOCMON:** open **Diagnostics**, pick a probe as the source, and run a ping
or MTR. The first hop should be that ISP's gateway. Then give Grafana a couple
of minutes and your per-ISP latency series will populate.

---

## The no-VLAN variant — flat LAN, no tagging

Can't tag (unmanaged switch, ISP ONT in the path, or you just don't want to)?
There's a workable middle ground: **one extra IP per ISP on the NOCBox's normal
NIC**, policy-routed by source address on the router.

In NOCMON, on the probe form:

1. Tick **"No VLAN — monitor from this box"**.
2. Fill **Source IP (optional)** — the address this probe pings from.
3. Fill **Interface (recommended)** — the NIC to put it on.

Setting **Interface** is what makes it *managed*: NOCBox adds the address as a
secondary on that NIC through the same host-config bundle, with the same
60-second auto-rollback, and removes it again when you delete the probe. Leave
Interface blank and NOCBox only binds the IP in Blackbox — you have to put it on
the NIC yourself, and **if it's missing every probe on it fails silently** with
`probe_success=0` and no error anywhere.

On the router, same as Part A but matching a host instead of a subnet:

```rsc
/routing rule
add src-address=172.30.251.20/32 action=lookup-only-in-table table=isp101 \
    comment="nocbox: flat-LAN probe -> ISP A"
```

**Two limits, both real:**

- **The parent NIC must be DHCP-addressed.** Netplan merges per-property with
  later-file-wins, so if your NIC has a static `addresses:` list in another
  netplan file, NOCBox's stanza would *replace* it and drop the box's management
  IP. The apply script **preflights this and refuses** rather than locking you
  out — you'll get a `preflight:` error naming the file. Add the address by hand
  in that case.
- **NOCBox doesn't check the LAN for conflicts.** Pick addresses nothing else uses.

Tagged VLANs are cleaner and give each ISP a real separate path. This variant
exists because a lot of WISP LANs can't tag — it's a legitimate setup, not a
downgrade.

---

## When it doesn't work

### The VLAN probe is dead but a no-VLAN probe is fine

Then the tags aren't getting through. **Every hop between the NOCBox NIC and the
router must pass the VLAN tagged.** Devices that quietly eat 802.1Q while
passing untagged traffic perfectly — so the rest of the LAN looks healthy:

- **ISP ONTs used in bridge mode as a switch** (Huawei EG8145V5 class) drop
  *all* tagged frames. This caused a real dead-VLAN incident on our test rig;
  bypassing the ONT fixed it instantly. Common in WISP setups.
- **"Smart" / Easy-Smart switches** (e.g. TP-Link TL-SG1016E once 802.1Q has
  ever been enabled) drop unknown VIDs.
- **Managed switches** need the VID tagged on **both** ports of the path, not
  just the NOCBox-facing one.

Localise it in about a minute:

```bash
# On the NOCBox — are tagged frames leaving, and does anything come back?
sudo tcpdump -nei eth0 vlan 101

# Lifetime RX of 0 means nothing tagged has EVER arrived — break is upstream.
ip -s link show vlan101
```

On the MikroTik, `/tool sniffer` on the far port with a MAC filter. Send an
untagged ARP first as a control (proves the sniffer setup works); the absence of
your tagged ARPs then convicts that segment.

### Don't use "can I ping the gateway?" as the path test

A gateway that won't answer ICMP is **not** proof the path is down —
multi-WAN routers with source-based PBR often don't ICMP-reply on their probe
addresses while forwarding perfectly. **ARP is the ground truth:** if
`ip neigh` shows the gateway `REACHABLE` on the vlan interface, layer 2 works.

### All probes show the same latency

They're all leaving via the same uplink — the routing rule isn't matching. Check
with the `curl --interface` test above, then verify the rule's `src-address`
matches the probe's actual subnet, and that it's `lookup-only-in-table`.

### Everything went down right after a `netplan apply`

If the box was configured before netplan took ownership of the policy routing,
a bare `netplan apply` wipes the rules. Do **one** Apply Host Config from NOCMON
— the regenerated YAML takes ownership and it stops happening.

---

## A note on the Enterprise MikroTik generator

If you're on **Enterprise**, NOCMON has a `/mikrotik` page that can read your
router's live state, **export** a `.rsc`, and **apply** changes to the router
directly.

**Configure your router from this guide. For now, don't use either the export
or Apply for the VLAN config above.** Two reasons:

- **It doesn't emit the parts that make PBR work.** The generated config covers
  `/interface vlan`, `/ip address`, `/routing table` and `/ip route` — but not
  the `/routing rule` in step 5 or the NAT rule in step 6. Those are the two
  lines that actually route. Without them you get tables nothing looks in.
- **The address it wants to put on the router is the NOCBox's own.** It emits
  the probe's source IP (`10.150.<n>.40`) rather than the router's gateway
  address (`.1`) — a duplicate IP on the same segment. And the per-ISP default
  route's next hop comes out as the router's own VLAN address instead of your
  ISP's.

**This applies to the Apply button too, not just the copy-paste export** — both
run the same generator, so a live apply would push the same conflicting address
onto your router.

This is a known issue and a fix is in progress. This whole section comes out
once it lands — if this section is still here, the export still needs the manual
corrections above.

---

## Related

- [QUICKSTART.md](QUICKSTART.md) — install, first login, first graph
- [PART-0-UBUNTU.md](PART-0-UBUNTU.md) — installing Ubuntu Server first

Stuck? Use the **Send feedback** button inside NOCMON (top-right, and the
sidebar footer) — it attaches a no-secrets diagnostics summary, which is
normally the first thing we'd have to ask you for.

---

*NOCBox by Team Jorian, powered by NOCMON.*
