# OpenCloud Podman Rootless Setup (Gemini AI)
Running **OpenCloud** via **Podman rootless** is an excellent choice for security, but because rootless Podman maps container users differently (via user namespaces), you need to pay specific attention to how volumes are handled.

By default, the OpenCloud container expects to run its initialization as `root` (UID 0) inside the container, which seamlessly maps directly to your non-root host user.

Here is a clean, step-by-step guide to getting a minimal OpenCloud setup running in your rootless environment.

---

## Step 1: Prepare the Host Storage

Create the local directories where OpenCloud will persist its data and configuration files. Since this is a rootless setup, create these within your user's home directory:

```bash
mkdir -p ~/opencloud/config ~/opencloud/data

```

To ensure there are no ownership conflicts inside the user namespace, use `podman unshare` to grant the container environment proper access permissions over these folders:

```bash
podman unshare chown -R 0:0 ~/opencloud/config ~/opencloud/data

```

*(Note: Within `podman unshare`, `0:0` safely maps back to your rootless user's context).*

---

## Step 2: Initialize and Run OpenCloud

You can deploy the container using a standard `podman run` command.

Run the following command to download the official image, initialize the setup, and bind the OpenCloud application to port `9200` on your host:

```bash
podman run -d \
  --name opencloud \
  -p 127.0.0.1:9200:9200 \
  -v ~/opencloud/config:/etc/opencloud:Z \
  -v ~/opencloud/data:/var/lib/opencloud:Z \
  -e PROXY_TLS=false \
  -e IDM_CREATE_DEMO_USERS=false \
  -e OC_URL=https://localhost:9200 \
  docker.io/opencloudeu/opencloud-rolling:3 \
  /bin/sh -c "opencloud init --insecure true || true; opencloud server"

```

### Key Flags Decoded:

* `--name opencloud`: Labels your container for easy management.
* `:Z`: This flag is **critical for SELinux systems** (like Fedora, RHEL, or CentOS). It tells Podman to automatically re-label the host folders so a rootless container can read/write to them.
* `PROXY_TLS=false`: Tells OpenCloud to allow unencrypted incoming traffic on port 9200, which is perfect if you plan on putting a reverse proxy (like Caddy, Nginx, or Apache) in front of it later.
* `opencloud init --insecure true`: Runs the mandatory first-time configuration script automatically if it hasn't been run yet.

---

## Step 3: Check the Logs and Admin Credentials

During the initialization phase, OpenCloud generates a random admin password. You need to pull this from the logs to log in for the first time:

```bash
podman logs opencloud | grep -i password

```

Look for a section outputted during the `init` phase displaying the username `admin` and its accompanying generated password.

---

## Step 4: Ensure Persistence (Optional but Recommended)

By default, rootless user services and containers shut down when you close your SSH session or log out. To ensure OpenCloud stays running in the background indefinitely, enable lingering for your user account:

```bash
loginctl enable-linger $USER

```

If you plan to access this outside of `localhost`, you will want to adjust the `OC_URL` environment variable to match your domain name and route it through a secure reverse proxy handling TLS certificates.