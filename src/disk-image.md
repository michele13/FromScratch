# How to create a disk image manually without root

## Prerequisites

you will need the following programs:

- `/bin/dd` from coreutils
- `/sbin/fdisk` from util-linux
- `/sbin/mkfs.ext4` (not busybox) from e2fsprogs

## Introduction

We will create a `disk.img` file of 1.1MB with an MBR partition table, partitions and files. All without using root.

1. Create a working folder with with the following subfolders: rootfs and mount (for testing later)

```bash
mkdir -pv rootfs mount
```

2. Create a file inside rootfs

```bash
cd rootfs
echo "this is a file" > README.txt
```

## Create the pieces of the disk

1. Create one file of 512 bytes that will contain our **mbr and partition table** later.

```bash
cd ..
dd if=/dev/zero of=mbr.bin bs=512 count=1
```
2. Create a file of 1MB called part1.bin that will be our first partition

```bash
# 2048 * 512 = 1MB
dd if=/dev/zero of=part1.bin count=2048 bs=512
```

## Prepare the first partition and assemble the disk

5. Partition `part1.bin` and copy the content of the  `rootfs` folder.

```bash
/sbin/mkfs.ext4 -O "^has_journal,^64bit" -d rootfs part1.bin
```

Here we created a filesystem with some features disabled: 

**64bit** 
  : Enables  the  file  system  to be larger than 2^32 blocks (>2TB)

**has_journal**
  : Disables Journal

6. Assemble the final disk

```bash
cat mbr.bin part1.bin > disk.img
```

## Create a working partition table on the disk

At this point we have a disk with a blank mbr and a partition that we can't mount becase we don't have a reference inside the partition table.

Let's fix that, start fdisk:

```bash
/sbin/fdisk disk.img
```

And follow the output:

```
Welcome to fdisk (util-linux 2.38.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS (MBR) disklabel with disk identifier 0xa1b3321f.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (1-4, default 1): 
First sector (1-2048, default 1): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (1-2048, default 2048): 

Created a new partition 1 of type 'Linux' and of size 1 MiB.
Partition #1 contains a ext4 signature.

Do you want to remove the signature? [Y]es/[N]o: n

Command (m for help): w

The partition table has been altered.
Syncing disks.
```

Following these instructions we created a disk with this partition table

|Sector Start| Sector End | Descritpion |
|---|---|---|
| 0 | 0 | `mbr.bin` |
| 1 | 2048 | `part1.bin` |
