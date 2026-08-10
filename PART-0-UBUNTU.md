# Part 0 — Ubuntu Server 22.04 install (bago ang NOCBox)

Para sa mga **first time mag-install ng server OS**. Walang assumption dito na
marunong ka na — step by step lahat.

Ang [QUICKSTART.md](QUICKSTART.md) namin ay nagsisimula sa **"may Ubuntu box ka
na."** Itong Part 0 ang bahagi bago 'yon: mula sa **blangkong mini-PC** hanggang
sa **may SSH ka na papasok** sa box. Pagkatapos nito, diretso ka na sa
[QUICKSTART step 2](QUICKSTART.md#2-install-two-commands) — dalawang command lang.

**Mga 45–60 minuto** ang buong proseso, karamihan hintayan lang.

> **Ubuntu Server 22.04 LTS lang ang supported.** Hindi 24.04, hindi 25.x, hindi
> Ubuntu Desktop. Seryoso 'to — may mga totoong install na nasira sa 24.04 (may
> nag-conflict na system group ID sa host-agent namin, at inilipat ng bagong
> iproute2 ang config folder nito). Kung 24.04 ang na-install mo, kailangang
> ulitin. Mas mabuting mahirapan ngayon kaysa maghabol mamaya.

---

## Ano ang kailangan mo

| Item | Detalye |
|---|---|
| Ang mini-PC / server | 4 cores, 8–16 GB RAM, 120 GB SSD. Okay na ang second-hand na business mini-PC (OptiPlex Micro, EliteDesk Mini, ThinkCentre Tiny). |
| USB flash drive | **8 GB o mas malaki.** Mabubura lahat ng laman — ilipat mo muna ang importante. |
| Isa pang computer | Windows PC/laptop, para gumawa ng bootable USB. |
| Monitor + keyboard | Pang-install lang. Pag tapos na at may SSH ka na, pwede mo nang tanggalin. |
| LAN cable | Saksak sa switch/router mo. **Wired**, huwag WiFi. |
| Ang LAN details mo | Anong IP ang ibibigay mo sa box, ano ang gateway (router IP), at anong DNS. Tingnan sa ibaba kung di mo alam. |

### Pumili ng static IP bago ka magsimula

Ito ang pinaka-madalas na sagabal sa installer, kaya ihanda mo na ngayon. Sagutin
mo lang 'to bago ka magsimula:

- **Anong IP ang ibibigay ko sa box?** — Halimbawa `192.168.1.50`. Dapat
  **nasa labas ng DHCP range** ng router mo, para walang ibang device na
  makakuha nito. (Karaniwan `.100`–`.200` ang DHCP pool, kaya ligtas ang `.50`.)
- **Ano ang gateway ko?** — IP ng router mo, karaniwan `192.168.1.1`.
- **Ano ang subnet ko?** — Kung `192.168.1.x` ang network mo, `192.168.1.0/24`
  ito. Pansinin: **`.0/24`**, hindi ang IP ng box.
- **DNS?** — `1.1.1.1,8.8.8.8` okay na.

> Paano malalaman? Sa isang Windows PC na nasa parehong network, buksan ang
> Command Prompt at i-type ang `ipconfig`. Makikita mo ang **IPv4 Address**
> (halimbawa `192.168.1.23`) at ang **Default Gateway** (`192.168.1.1`). Ibig
> sabihin `192.168.1.0/24` ang subnet mo, at gawin mong `192.168.1.50` ang box.

---

## 1. I-download ang Ubuntu Server 22.04 ISO

Punta sa **<https://releases.ubuntu.com/22.04/>**

Hanapin ang file na ganito ang pangalan:

```
ubuntu-22.04.x-live-server-amd64.iso
```

Kunin ang pinakabago sa mga `22.04.x` (halimbawa `22.04.5`) — point release lang
'yang `.x`, pare-pareho namang 22.04 LTS. Mga **2 GB** ang laki.

**I-double check bago mag-download:**

- ✅ May **`live-server`** sa filename. Kung `desktop` ang nakasulat, mali —
  GUI 'yon, hindi appliance OS.
- ✅ **`22.04`**, hindi `24.04`. Madaling mapagkamalan sa ubuntu.com kasi 24.04
  ang default na inaalok. Diretso ka na lang sa link sa taas.
- ✅ **`amd64`** (Intel/AMD). Hindi `arm64`.

---

## 2. Gawing bootable USB gamit ang Rufus

Sa Windows PC mo, i-download ang **Rufus** sa **<https://rufus.ie>** (kunin ang
"Standard" `.exe` — portable, walang install).

Isaksak ang USB, buksan ang Rufus, tapos:

| Field | Ilagay |
|---|---|
| **Device** | Ang USB mo. **Tignang mabuti** — mabubura lahat ng nandito. |
| **Boot selection** | Click **SELECT** → hanapin ang na-download mong `.iso` |
| **Partition scheme** | **GPT** |
| **Target system** | **UEFI (non CSM)** |
| **File system** | Iwan ang default (FAT32) |
| Volume label | Kahit ano |

Click **START**.

- Kung may lalabas na **"ISOHybrid image detected"** → piliin ang
  **"Write in ISO Image mode (Recommended)"** → OK.
- May warning na mabubura ang USB → OK.

Hintayin ang **READY** (mga 3–5 minuto). Tanggalin ang USB.

> **Luma ang mini-PC (mga 2014 pababa)?** Baka BIOS/Legacy lang ang boot niya,
> hindi UEFI. Kung ganoon, gawing **MBR** ang Partition scheme at
> **BIOS (or UEFI-CSM)** ang Target system. Kung di mo sigurado, subukan muna
> ang GPT/UEFI — halos lahat ng 6th-gen Intel pataas ay UEFI na.

---

## 3. I-boot ang mini-PC mula sa USB

1. Saksak ang USB, monitor, keyboard, at LAN cable sa mini-PC.
2. I-on, tapos **pindutin agad-agad** ang boot-menu key. Iba-iba per brand:

| Brand | Boot menu key |
|---|---|
| Dell (OptiPlex) | **F12** |
| HP (EliteDesk / ProDesk) | **F9** |
| Lenovo (ThinkCentre) | **F12** (minsan Enter muna, saka F12) |
| ASUS / Acer / generic | **F8**, **F11**, o **Esc** |

   Pindutin nang paulit-ulit sa oras na i-on mo. Kung nakalampas at nag-boot sa
   lumang OS, i-restart at ulitin.

3. Sa boot menu, piliin ang USB — karaniwang may **"UEFI:"** sa unahan ng
   pangalan ng USB brand mo (halimbawa `UEFI: SanDisk Cruzer`).
4. Piliin ang **"Try or Install Ubuntu Server"** kapag lumabas ang itim na menu.
   Titigil-tigil ang mga text sa screen — normal 'yon.

> **Hindi lumalabas ang USB sa boot menu?** Pasok sa BIOS setup (**Del** o
> **F2** habang nag-boboot) at hanapin ang **Secure Boot** → **Disabled**.
> Tingnan din kung naka-enable ang **USB Boot**. Save & exit, ulitin.

---

## 4. Ang installer, screen by screen

Keyboard lang ang gamit dito — **arrow keys** para gumalaw, **Enter** para
piliin, **Tab** para lumipat sa mga button sa ibaba. Walang mouse.

> **Walang screenshots ang guide na 'to** — inilarawan namin nang detalyado ang
> bawat screen sa halip na maglagay ng litratong hindi namin kuha. Kung
> makakapag-screenshot ka habang nag-i-install, ipadala mo sa amin at ilalagay
> namin dito, credited.

### 4.1 Language
Piliin ang **English**. Enter.

### 4.2 Installer update available
Kung may lalabas na **"Installer update available"** → piliin ang
**"Continue without updating"**. Mas mabilis, at wala namang mawawala.

### 4.3 Keyboard configuration
**English (US)** sa dalawang field. Tab pababa sa **Done**, Enter.

### 4.4 Choose type of install
Dalawa ang pipiliin:

- ✅ **Ubuntu Server** ← **ito ang piliin mo**
- ❌ Ubuntu Server (minimized)

Huwag ang *minimized* — tinatanggal niya ang mga basic na tools (kasama ang mga
kailangan sa pag-troubleshoot mamaya). **Done.**

### 4.5 Network connections — ⚠️ DITO NATITIGIL ANG KARAMIHAN

Ito ang screen na pinaka-madalas ipagtanong sa amin. Basahin mo 'to nang dahan-dahan.

Makikita mo ang listahan ng network interface, may pangalang tulad ng `enp1s0`,
`eno1`, o `ens18`. Kung nakasaksak ang LAN cable, may DHCP address na siguro
siya — pero **kailangan natin ng static**, kaya papalitan natin.

1. I-highlight ang interface mo (yung may IP address o may `connected`), Enter.
2. Sa lalabas na maliit na menu, piliin ang **"Edit IPv4"**.
3. **IPv4 Method:** palitan mula `Automatic (DHCP)` → **`Manual`**. Enter.
4. Lalabas ang apat na field. Ganito ang tama:

| Field | Ilagay | Halimbawa |
|---|---|---|
| **Subnet** | Ang **network**, CIDR format | `192.168.1.0/24` |
| **Address** | Ang IP ng **box** | `192.168.1.50` |
| **Gateway** | Ang IP ng **router** mo | `192.168.1.1` |
| **Name servers** | DNS, paghiwalayin ng comma | `1.1.1.1,8.8.8.8` |
| **Search domains** | Iwang **blangko** | |

5. **Save**, tapos **Done**.

**Ang tatlong madalas na mali dito:**

- ❌ **Inilagay ang IP ng box sa Subnet.** `192.168.1.50/24` ang nailalagay
  imbes na `192.168.1.0/24`. Ang *Subnet* ay ang network — laging
  **`.0`** ang dulo sa isang `/24`. Ang IP ng box ay sa **Address**.
- ❌ **Kulang ang `/24`.** Hindi tatanggapin ang `192.168.1.0` lang. Kailangan
  ng prefix.
- ❌ **Nasa loob ng DHCP pool ang napiling IP.** Gagana muna, tapos isang araw
  may ibang device na kukuha ng parehong IP at magkakagulo. Pumili sa labas
  ng pool.

> Kung mali ang nailagay: balik lang sa interface, **Edit IPv4** ulit, ayusin.
> Kahit ilang beses pwede bago mag-**Done**.

### 4.6 Proxy configuration
Iwang **blangko** (maliban kung talagang may HTTP proxy ang shop mo). **Done.**

### 4.7 Ubuntu archive mirror
Iwan ang default. Hayaan mong matapos ang **"Checking mirror"** — kung may
error, ibig sabihin walang internet ang box: i-check ang LAN cable at ang
gateway/DNS sa step 4.5. **Done.**

### 4.8 Guided storage configuration
Piliin ang **"Use an entire disk"**. Iwan ang default na naka-tick na
**"Set up this disk as an LVM group"** — okay lang siya.

Kung dalawa ang drive (halimbawa SSD + HDD), **piliin ang SSD**.

**Done.**

### 4.9 Storage configuration (summary)
Repaso lang ng gagawin. **Done** → lalabas ang pulang
**"Confirm destructive action"** → **Continue**.

⚠️ Dito mabubura ang disk. Siguraduhing wala nang kailangan sa makinang 'yan.

### 4.10 Profile setup

| Field | Ilagay |
|---|---|
| Your name | Pangalan mo |
| **Your servers name** | `nocbox` (ito ang hostname) |
| **Pick a username** | Isang normal na username — halimbawa `noc`. **HUWAG `root`.** |
| Choose a password | Malakas na password. **Isulat mo** — kakailanganin mo 'to sa SSH. |

> **Bakit hindi `root`?** Hindi ka nga papayagan ng installer, pero mahalaga
> ring malaman kung bakit: ang NOCBox installer ay **tumatangging tumakbo bilang
> root**. Tumatawag siya ng `sudo` sa mga bahaging kailangan lang. Kaya normal
> na user na may `sudo` ang tama — awtomatiko namang nakukuha ng unang user na
> gagawin mo dito ang `sudo`.

**Done.**

### 4.11 Upgrade to Ubuntu Pro
**"Skip for now"** → **Continue**. Hindi kailangan ng NOCBox.

### 4.12 SSH Setup — ⚠️ HUWAG MAKAKALIMUTAN

- ✅ **Tick ang "Install OpenSSH server"** (Space bar para mag-tick)
- Import SSH identity: **No**

**Kung hindi mo 'to na-tick, wala kang makakapasok sa box nang remote** —
kailangan mong bumalik sa monitor at keyboard. Ma-aayos naman (nasa ibaba ang
paraan), pero mas madali nang i-tick ngayon.

**Done.**

### 4.13 Featured Server Snaps
**Wala kang i-tick dito. Lahat.** Tab pababa sa **Done**, Enter.

⚠️ Kasama sa listahang 'to ang **`docker`** snap. **Huwag mong i-install 'yon.**
Ang NOCBox installer na ang maglalagay ng tamang Docker; ang snap na bersyon ay
naka-confine at nagkakagulo sa stack namin.

### 4.14 Installing system
Mga **10–20 minuto**, depende sa bilis ng internet. Makikita mo ang tumatakbong
log — normal 'yon.

Pag lumabas ang **"Reboot Now"** → Enter. Hihingi siya ng
`Please remove the installation medium` → **hugutin ang USB**, tapos Enter.

Boot na siya sa bagong Ubuntu. Kapag lumabas ang
`nocbox login:` — tapos na ang install. 🎉

---

## 5. Tingnan ang IP ng box

Sa mismong box (monitor + keyboard), mag-login gamit ang username at password
mo, tapos:

```bash
ip -4 addr show
```

Hanapin ang linyang `inet` sa interface mo — dapat ang static IP na inilagay mo
(halimbawa `inet 192.168.1.50/24`).

Kung DHCP address ang lumabas at hindi ang inilagay mo, hindi natuloy ang static
IP config. Ayusin gamit ang [netplan section](#kung-mali-ang-ip) sa ibaba.

Subukan din kung may internet:

```bash
ping -c 3 1.1.1.1
```

Kung may sagot, mabuti. Kung wala, i-check ang gateway sa step 4.5.

---

## 6. Pasok gamit ang SSH

Dito na pwedeng tanggalin ang monitor at keyboard. Sa Windows PC mo, dalawa ang
pagpipilian:

### Option A — Windows Terminal / PowerShell (walang idodownload)

Buksan ang **PowerShell** o **Windows Terminal**:

```bash
ssh noc@192.168.1.50
```

(Palitan ang `noc` ng username mo at ang IP ng sa'yo.)

Sa unang pasok, magtatanong ito ng
`Are you sure you want to continue connecting?` → i-type ang **`yes`** → Enter.
Tapos ilagay ang password. **Normal na walang lumalabas habang nagta-type ka ng
password** — hindi sira ang keyboard, hindi lang talaga nagpapakita. Enter.

### Option B — PuTTY

I-download sa **<https://www.putty.org>**, tapos:

| Field | Ilagay |
|---|---|
| Host Name (or IP address) | `192.168.1.50` |
| Port | `22` |
| Connection type | SSH |

**Open** → **Accept** sa security alert (unang beses lang) → i-type ang username
at password.

Pag nakita mo ang prompt na ganito, nasa loob ka na ng box:

```
noc@nocbox:~$
```

---

## 7. Tapos ka na sa Part 0 — tuloy sa QUICKSTART

Nandito ka na: may **Ubuntu Server 22.04** ka, **static IP**, at **SSH access**.
Ito mismo ang inaakala ng QUICKSTART na meron ka na.

👉 **Diretso sa [QUICKSTART step 2 — Install (two commands)](QUICKSTART.md#2-install-two-commands).**

Ihanda mo lang ang **pull token** na binigay namin (`read:packages` token) —
i-papaste mo 'yon sa install.

---

## Kung may namali — mga karaniwang problema

### Na-install ko ang 24.04 (o Desktop)

Kailangang ulitin. Sorry — **22.04 Server lang** ang supported, at hindi lang
'to arte: may mga totoong install na nasira sa 24.04. Balik sa
[step 1](#1-i-download-ang-ubuntu-server-2204-iso) at tiyaking may
**`22.04`** at **`live-server`** sa filename.

### Nakalimutan kong i-tick ang OpenSSH

Balik sa monitor at keyboard ng box, mag-login, tapos:

```bash
sudo apt-get update && sudo apt-get -y install openssh-server
```

Tapos i-check:

```bash
systemctl status ssh
```

Dapat `active (running)`. Pwede ka nang mag-SSH.

### Kung mali ang IP

Nasa netplan ang network config. Buksan ang file na ginawa ng installer:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Ganito ang dapat itsura (palitan ng sa'yo ang interface name at mga IP):

```yaml
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

I-save (**Ctrl+O**, Enter, **Ctrl+X**), tapos:

```bash
sudo netplan apply
```

Tingnan ulit gamit ang `ip -4 addr show`.

> **Mag-ingat sa spacing.** YAML ito — **espasyo lang, walang Tab**, at
> mahalaga ang indentation. Kung magrereklamo ang `netplan apply`, madalas
> spacing ang dahilan.

> **Huwag munang gumalaw dito pag naka-install na ang NOCBox.** Gumagawa ang
> NOCBox ng sarili niyang netplan file (`99-nocmon.yaml`) para sa mga VLAN
> probe. Iwan mo 'yon — sa NOCMON UI ka mag-adjust, hindi sa kamay.

### Nasa DHCP pa rin kahit static ang inilagay ko

Malamang may naiwang ibang netplan file na naglalagay ng `dhcp4: true`. Tingnan
lahat:

```bash
ls -l /etc/netplan/
```

Dapat isa lang ang naroon bago mag-install ng NOCBox — ang
`00-installer-config.yaml`. Kung may iba pa (halimbawa isang `50-cloud-init.yaml`),
sabihan mo kami bago mo galawin — mas madaling i-check kaysa i-undo.

### Hindi nag-bo-boot sa USB

1. BIOS setup (**Del** o **F2**) → **Secure Boot: Disabled**
2. Tingnan kung naka-**enable** ang USB boot
3. Subukan ang ibang USB port — mas maaasahan ang **USB 2.0** (itim) kaysa
   USB 3.0 (asul) sa lumang BIOS
4. Kung talagang luma ang makina, gawin ulit ang USB sa Rufus gamit ang
   **MBR** + **BIOS (or UEFI-CSM)**

### Nakalimutan ko ang password

Wala kaming password recovery para sa Ubuntu mismo — mas mabilis pang ulitin ang
install (step 3 pataas) kaysa sa single-user-mode reset, lalo't wala pa namang
laman ang box.

---

## Kailangan mo ng tulong?

Kung na-stuck ka kahit saan dito, **i-message mo kami** — sabihin mo kung anong
step at kung ano ang nakikita mo sa screen. Kung may kuha kang litrato ng
screen, mas mabuti.

Maliit na team lang kami kaya **best-effort** ang support (tignan ang note sa
[README](README.md#a-note-on-support)) — pero itong Part 0 na 'to ay galing mismo
sa mga tanong ng mga naunang tester, kaya malamang nasagot na dito ang tanong mo.

---

*NOCBox by Team Jorian, powered by NOCMON.*
