# IPXE Custom Server Tutorial

## 1. Create Bridge

Create 1 bridge interface: **vmbr66**

```
auto vmbr66
iface vmbr66 inet manual
	bridge-ports none
	bridge-stp off
	bridge-fd 0
	bridge-vlan-aware yes
	bridge-vids 2-4094
#Bridge for Router66

```

## 2. Create the Router

Create 1 LXC container:

**CT ID:** 106 (Can be whatever)  
**hostname:** router66  
**template:** debian-13  
**RAM:** 512MB  
**Swap:** 512MB  
**Cores:** 1  
**Root Disk:** 8GB
**DNS Server:** 8.8.8.8  

Below is the network configuration:

| ID | Name | Bridge | IP Address | Gateway | Note |
|----|------|--------|------------|---------|-------
| net0 | eth0 | vmbr1 | 10.0.3.106/24 | 10.0.3.1 | WAN |
| net1 | eth1 | vmbr66 | 192.168.3.1/24 | 10.0.3.1 | LAN |

### 2.1 Install the Software 

Install the software:

```bash
apt update 
apt dist-upgrade -y
apt install -y iptables dnsmasq
```

### 2.2 Enable routing and NAT

Source: <https://wiki.archlinux.org/title/Internet_sharing>

Enable IP Forwarding

```bash
cat > /etc/sysctl.d/30-ipforward.conf << "EOF"
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
EOF
```

If you're using systemd-networkd, create this file (You might need to do it if you're using the debian template):

```bash
cat > /etc/systemd/network/20-lan.network << "EOF"
[Network]
IPv4Forwarding=yes
EOF
```
Configure the firewall (iptables):

```bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

# Enable input connections for DCHP (udp 67) and DNS (tcp/udp 53)
iptables -I INPUT -p udp --dport 67 -i eth1 -j ACCEPT
iptables -I INPUT -p udp --dport 53 -s 192.168.3.0/24 -j ACCEPT
iptables -I INPUT -p tcp --dport 53 -s 192.168.3.0/24 -j ACCEPT
```

To save the iptables configuration, install the `iptables-persistent` package:

```bash
apt install iptables-persistent
```
answer YES when asked to save the rules. To manually save rules type:


```bash
# IPv6
iptables-save -f /etc/iptables/rules.v4
# IPv6
ptables-save -f /etc/iptables/rules.v6
```

### 2.3 DCHP Server


For reference [read the ArchWiki documentation](https://wiki.archlinux.org/title/Dnsmasq) and the man page [dnsmasq(8)](https://man.archlinux.org/man/dnsmasq.8).

Configure the DHCP Server with dnsmasq ;

```bash
cat > /etc/dnsmasq.d/dhcp-server.conf << "EOF"
# Only Listen to LAN NIC
interface=eth1

# Default route
dhcp-option=option:router,192.168.3.1

# Set DNS servers to announce
server=8.8.8.8

# Local Hostname Resolution
domain=home.arpa
expand-hosts

# Dynamic range of IP available
dhcp-range=192.168.3.100,192.168.3.150

# Assign static IP to some clients: bind MAC address to IP
# dhcp-host=aa:bb:cc:dd:ee:ff,192.168.1.2
EOF
```

Restart the dnsmasq service

```bash
systemctl restart dnsmasq.service
```


## 3. Configure iPXE Server

Install HTTPS Server

```bash
apt install nginx
```



## ??. Create the Test VMs

Create **3 VM**:
1. 32-bit BIOS: netboot-bios-32 (cpu: kvm32)
2. 64-bit BIOS: netboot-bios-64
3. 64-bit UEFI: netboot-uefi-32

Each virtual machine has 2GB of RAM, it's connected to **vmbr66** and it's configured to boot only from the network.


## Other resources
https://oneuptime.com/blog/post/2026-01-15-setup-dnsmasq-local-dns-ubuntu/view