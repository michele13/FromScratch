# LFS Non-Root Environment Setup Script

## Question 1

How do I setup the environment for building LFS without root?
https://linuxfromscratch.org/lfs/view/stable/chapter04/settingenvironment.html
https://linuxfromscratch.org/lfs/view/stable/chapter04/addinguser.html

Create a script that sets up a clean environment as explained in that page without adding an lfs user and without overwriting my ~/.profile or ~/.bashrc

## Answer 1 (Gemini) - Bash Script

To set up a clean, isolated Linux From Scratch (LFS) build environment without creating a dedicated `lfs` system user and without overwriting or polluting your personal `~/.profile` or `~/.bashrc`, you can encapsulate the entire environment into a custom, isolated workspace.

The approach below achieves this by saving the LFS-specific configurations into a dedicated folder (`$HOME/lfs_workspace/`) and launching a completely sterile shell (`env -i`) that reads only those files.

### Interactive/Automated Setup Script

Save the following code block as a script (e.g., `setup_lfs_env.sh`), make it executable (`chmod +x setup_lfs_env.sh`), and run it.

```bash
#!/bin/bash

# Define the local workspace and LFS mount directory
# Change /mnt/lfs to a path you own if you do not have root access on the host
export LFS="/mnt/lfs" 
WORKSPACE="$HOME/lfs_workspace"

echo "=== Creating isolated LFS environment in $WORKSPACE ==="
mkdir -p "$WORKSPACE"

# 1. Create the isolated .bash_profile equivalent
# This drops into a fresh bash shell stripping all your host environment variables
cat > "$WORKSPACE/lfs_profile" << EOF
exec env -i HOME=$HOME TERM=$TERM PS1='lfs-nonroot:\w\$ ' /bin/bash --rcfile $WORKSPACE/lfs_bashrc
EOF

# 2. Create the isolated .bashrc equivalent (Direct from LFS Chapter 4.4)
cat > "$WORKSPACE/lfs_bashrc" << EOF
# Turn off bash hashing to ensure newly built tools are picked up instantly
set +h
umask 022
LFS=$LFS
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin

if [ ! -L /bin ]; then 
    PATH=/bin:\$PATH
fi

# Prioritize LFS tools over host system binaries
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site

export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j\$(nproc)

echo "========================================================="
echo " Isolated LFS Environment Loaded Successfully."
echo " Hashing is disabled (set +h)."
echo " Target Architecture: \$LFS_TGT"
echo " Parallel Jobs: \$MAKEFLAGS"
echo "========================================================="
EOF

# 3. Create a shortcut script to easily re-enter the environment later
cat > "$WORKSPACE/enter_env.sh" << EOF
#!/bin/bash
/bin/bash --init-file $WORKSPACE/lfs_profile
EOF
chmod +x "$WORKSPACE/enter_env.sh"

echo "Setup complete!"
echo "To enter your clean LFS environment safely at any time, run:"
echo "    source $WORKSPACE/enter_env.sh"
echo ""

```

### How to use it:

1. **Run the initial setup script:**
```bash
./setup_lfs_env.sh

```


2. **Enter your isolated environment:**
```bash
source ~/lfs_workspace/enter_env.sh

```



### Why this satisfies Chapter 4 requirements safely:

* **Zero Pollution:** Your personal `~/.bashrc` and `~/.profile` are completely untouched.
* **`env -i` Isolation:** By using `exec env -i`, all hazardous host environment flags (like custom `LD_LIBRARY_PATH`, `C_INCLUDE_PATH`, or aliases) are stripped from the environment shell, matching the strict LFS security requirements.
*  `--rcfile` & `--init-file` routing: It forces bash to read your localized `lfs_bashrc` file rather than defaulting back to your host configurations.

*Note: Since you are building without root, ensure that your `$LFS` directory target (e.g., `/mnt/lfs` or a customized subdirectory like `$HOME/lfs_root`) is fully writable by your standard user account.*

## Q2 - And what if we use busybox ash instead of bash?

and what if we use busybox ash instead of bash?

## Answer 2 - Busybox Script

Using `busybox ash` instead of `bash` to set up your isolated LFS environment introduces a few challenges, but it is entirely possible.

The primary differences are that `ash` is a much lighter POSIX-compliant shell. It **does not support Bash-specific flags** like `--rcfile` or `--init-file`, and it does not natively feature the `set +h` command (as `ash` handles path tracking differently or tracks it via a simpler internal mechanism).

To achieve the same clean isolation with `busybox ash` without touching your system files, you must rely on the **`ENV` environment variable**, which POSIX shells use to load interactive startup files.

### The BusyBox Ash Setup Script

Save this script as `setup_lfs_ash.sh`, make it executable (`chmod +x setup_lfs_ash.sh`), and run it.

```bash
#!/bin/sh

# Define the local workspace and LFS mount directory
export LFS="/mnt/lfs" 
WORKSPACE="$HOME/lfs_workspace_ash"

echo "=== Creating isolated LFS environment for BusyBox Ash in $WORKSPACE ==="
mkdir -p "$WORKSPACE"

# 1. Create the isolated profile equivalent for ash.
# This file will be executed when we launch our clean 'env -i' shell.
# It sets up the 'ENV' variable which tells ash where to look for its interactive settings.
cat > "$WORKSPACE/lfs_profile" << EOF
export HOME=$HOME
export TERM=$TERM
export PS1='lfs-ash:\w\$ '
export ENV="$WORKSPACE/lfs_ashrc"
EOF

# 2. Create the isolated ashrc configuration (Adapted from LFS Chapter 4.4)
cat > "$WORKSPACE/lfs_ashrc" << EOF
umask 022
LFS=$LFS
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin

if [ ! -L /bin ]; then 
    PATH=/bin:\$PATH
fi

# Prioritize LFS tools over host system binaries
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site

export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j\$(nproc 2>/dev/null || echo 2)

echo "========================================================="
echo " Isolated LFS Environment Loaded Successfully (Ash Shell)."
echo " Target Architecture: \$LFS_TGT"
echo " Parallel Jobs: \$MAKEFLAGS"
echo "========================================================="
EOF

# 3. Create the shortcut entry script
# This strips the environment and forces busybox ash to read our profile
cat > "$WORKSPACE/enter_env.sh" << EOF
#!/bin/sh
exec env -i busybox ash --login "$WORKSPACE/lfs_profile"
EOF
chmod +x "$WORKSPACE/enter_env.sh"

echo "Setup complete!"
echo "To enter your clean LFS Ash environment safely, run:"
echo "    . $WORKSPACE/enter_env.sh"
echo ""

```

### Critical Differences to Keep in Mind:

1. **Path Hashing (`set +h`):** BusyBox `ash` does not have a `set +h` command. While `ash` does remember command paths internally to speed up execution, you can clear its path cache manually at any time if it accidentally runs a host tool instead of your newly compiled tool by typing:
```sh
hash -r

```


2. **Sourcing the Entry Script:** Because `ash` is strictly POSIX, you should use the dot operator (`.`) to source scripts into your current context instead of the bash-specific `source` command:
```sh
. ~/lfs_workspace_ash/enter_env.sh

```


3. **LFS Compatibility:** While `ash` works well for organizing variables and running initial environments, keep in mind that the Linux From Scratch book uses certain complex `bash`-specific syntaxes in later compilation instructions. When executing raw package installation commands from the book inside an `ash` shell, keep a close eye out for unexpected string manipulations or syntax errors.

## Question 3 - Bash PS1 not cleared

the script for bash works as it should, but why PS1 is still ${debian_chroot:+($debian_chroot)}\u@\h:\w\$ ?

## Answer 3 - The Culprit: `/etc/bash.bashrc`

That happens because of a subtle trap in how `bash` reads its startup files!

Even though you are using `env -i` to strip your environment, the host's system-wide configuration files are still slipping into your clean shell through the back door.

Here is exactly what is happening under the hood:

### The Culprit: `/etc/bash.bashrc`

When you launch Bash, it doesn't just read your localized workspace files. By design, Bash *always* looks for the host system's global files first.

The sequence plays out like this:

1. You run `env -i /bin/bash --rcfile ...`
2. Bash starts up, notices it's an interactive shell, and **implicitly reads the host's `/etc/bash.bashrc**` before it even glances at your workspace file.
3. `/etc/bash.bashrc` contains the standard Debian/Ubuntu prompt logic, which overwrites `PS1` with that exact `${debian_chroot...}` string.
4. Finally, Bash reads your `$WORKSPACE/lfs_bashrc`.

"But wait," you might ask, "if my file is read *last*, shouldn't my `PS1` win?"

It normally would, **but** your `lfs_profile` is setting `PS1`, not your `lfs_bashrc`. Let's look at the execution timeline:

```
[Your Command] -> Runs lfs_profile (Sets PS1) 
                     ↓
                 Launches bash --rcfile lfs_bashrc
                     ↓
                 Reads host's /etc/bash.bashrc (Overwrites PS1! ❌)
                     ↓
                 Reads lfs_bashrc (Doesn't have PS1, so the host's prompt stays)

```

---

### The Fix

To fix this, you just need to move the `PS1` definition to the absolute end of the line—inside the `lfs_bashrc` file. That way, it executes *after* the host system has finished injecting its defaults.

Modify your `$WORKSPACE/lfs_bashrc` to include the `PS1` definition at the bottom:

```bash
# ... (rest of your existing lfs_bashrc variables)

export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j$(nproc)

# Force the prompt here so it overrides /etc/bash.bashrc
export PS1='lfs-nonroot:\w\$ '

echo "========================================================="
echo " Isolated LFS Environment Loaded Successfully."
# ...

```

Once you move it there, your next session will clean up that prompt instantly!

## Question 4 - Prevent reading of /etc/bash.bashrc

is there a way to prevent bash from reading /etc/bash.bashrc ?

## Answer 4 - Solution

Yes, you can absolutely block Bash from reading the host system's `/etc/bash.bashrc`.

The secret lies in a specific compile-time setting of Bash. When Bash starts interactively, it checks for `/etc/bash.bashrc` *unless* it is invoked with the `--norc` flag. However, if you pass `--norc`, it also skips your custom `lfs_bashrc` file.

To bypass `/etc/bash.bashrc` completely while still loading your specific LFS configuration, you have two native ways to do it.

---

### Method 1: The `--norc` + `POSIX` Mode Trick (Most Secure)

If Bash is started in **POSIX mode**, its behavior changes strictly to follow the POSIX standard. In this mode, Bash completely ignores `/etc/bash.bashrc` and instead looks exclusively at whatever file path is stored in the `ENV` variable.

You can modify your `$WORKSPACE/lfs_profile` to use this combination:

```bash
exec env -i HOME=$HOME TERM=$TERM ENV="$WORKSPACE/lfs_bashrc" /bin/bash --posix --norc

```

> **Why this works:** `--norc` stops Bash from reading any standard interactive files (including the host's `/etc/bash.bashrc`), while `--posix` tells it to read the file pointed to by `ENV`. This gives you 100% isolation from the host system's configuration.

---

### Method 2: The Non-Standard Name Bypass

If you want to keep Bash running in its default native mode (without the strict POSIX restrictions), you can trick it using a quirk in how it identifies interactive vs. non-interactive shells.

When you pass a script file directly to Bash as an argument, it treats it as a non-interactive script executor and **skips `/etc/bash.bashrc` entirely**. You can leverage this by using the `--init-file` option but stripping out `--rcfile`.

Change your execution line in `lfs_profile` to:

```bash
exec env -i HOME=$HOME TERM=$TERM /bin/bash --norc --init-file "$WORKSPACE/lfs_bashrc" -i

```

> **Why this works:** The `--norc` explicitly shuts down the automatic sourcing of `/etc/bash.bashrc`. The `--init-file` forces it to read your custom configuration anyway, and the trailing `-i` forces the shell to stay open interactively once your custom script finishes running.