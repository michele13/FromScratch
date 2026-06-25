# How to get a shell with clean environment?

## Interactive shell

This command will start an interactive (non login) shell and look for the file `.local/env` in the current directory


Go to your directory of choice and create an empty file.

This is the **Bash version**

```bash
cat > enter-bash-env.sh << "EOF"
env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' bash --rcfile .local/env
EOF
```
This is the **Unix shell version**

```sh
cat > enter-env.sh << "EOF"
env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' ENV=".local/env" sh
EOF
```

Make the scripts executable


```bash
chmod +x enter-env.sh
chmod +x enter-bash-env.sh
```

### Credits

This document is inspired by [Linux From Scratch - 4.4 Setting Up Environment](https://linuxfromscratch.org/lfs/view/stable/chapter04/settingenvironment.html)

## Shell script

If you want your shell script to have a clean environment, it should be like this.

```bash {.numberLines}
#!/bin/sh

# Clear environment variables by restarting script w/bare minimum passed through
[ -z "$NOCLEAR" ] && \
  env -i NOCLEAR=1 HOME="$HOME" PATH="$PATH" "$0" "$@"

unset NOCLEAR

# Start writing your commands below

: commands-here

exit 0
```
### Credits

Inspired by [mkroot.sh - landley/toybox on Github](https://github.com/landley/toybox/blob/master/mkroot/mkroot.sh)

