# Install Opencloud on rootless Podman

## Create necessary directories

```bash
sudo install -d -o $USER -g $USER /data
sudo install -d -o $USER -g $USER /data/owncloud
cd /data/owncloud
```

## Rootless Docker and UID Mapping

When Docker runs in rootless mode, bind-mounted directories do not always use the same ownership mapping you see in a regular Docker setup.


The OpenCloud container still runs as UID and GID 1000 inside the container, but rootless Docker maps that identity into the subordinate UID and GID range configured for your host user. As a result, a host directory owned by 1000:1000 may not be writable inside the container.

### Adjust ownership

```bash
sudo chown -R 101000:101000 /data/owncloud
sudo chmod -R 0700 /data/owncloud
```

## Pull OpenCloud Image

```bash
docker pull opencloudeu/opencloud-rolling:latest
```

## Initialize OpenCloud (First-time Setup)


```bash
docker run --rm -it \
    -v /data/opencloud/opencloud-config:/etc/opencloud \
    -v /data/opencloud/opencloud-data:/var/lib/opencloud \
    -e IDM_ADMIN_PASSWORD=admin \
    opencloudeu/opencloud:latest init
    
```