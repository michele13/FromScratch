# Install Podman on Antix

## Enable cgroups2

Edit /etc/runit/config/cgroups.conf

```
CGROUP_MODE=unified
```
 
## Make / a shared mount

Create the file `/etc/runit/boot-run/S61-mount-rshared.stage1.sh and make it executable

```
#!/bin/sh
mount --make-rshared /
```
reboot and check propagation with 

```bash
findmnt -o PROPAGATION /
```

## Create /etc/subuuid and /etc/subgid

As your normal user with sudo preveleges

```bash
echo "root:100000:65536" | sudo tee /etc/subuid
echo "$USER:100000:65536" | sudo tee -a /etc/subuid

echo "root:100000:65536" | sudo tee /etc/subgid
echo "$USER:100000:65536" | sudo tee -a /etc/subgid
```

## Install uidmap and paast

uidmap passt are also required to run Podman

```bash
sudo apt install uidmap passt
```

## Install Podman

```bash
sudo apt install podman
```

Test the program with

```bash
podman run --rm busyboox echo "Hello World"

podman run --rm hello-world
```

## Add Dockerhub registry for podman

```bash
# 1. Back up the current broken file just in case
sudo mv /etc/containers/registries.conf /etc/containers/registries.conf.bak

# 2. Create a brand new file with just the correct modern registry setting
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee /etc/containers/registries.conf
```