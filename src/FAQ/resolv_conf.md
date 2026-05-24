# How to avoid NetworkManager overwriting /etc/resolv.conf?

## 1. Make /etc/resolv.conf immutable

Use `chattr` to make the file read-only, even for the root user. This stops any process from overwriting it. 

```bash
sudo chattr +i /etc/resolv.conf
```

## 3. Disable NetworkManager DNS Management

Create this file on `/etc/NetworkManager/conf.d/dns.conf`

```
[main]
dns=none
```
This will prevent NetworkManager from changing resolv.conf anytime you change connection