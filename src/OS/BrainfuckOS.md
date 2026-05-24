# Brainfucked OS

An OS for retarded people. It's so simple and stupid that it should be impossible to break.

## Features

- Simple UI. You can't move icons, you can't delete them. They are sorted alphabetically.
- The system is stored on a ROM, you can't destroy it.
- Apps will be updated automatically. They are in a separate partition that will not be deleted if the user resets its data.
- Reset can delete *user data* and/or *apps*.
- No root, no Superuser, no Admin.
- App Store?
- Automatic backup of bookmarks and password
- Simple Chrome Browser reset
- Password Recovery for the user.
- After Three wrong passwords the user will be asked to use "guest mode"
- User can create new users when they want
- Guest is an account without password. You can't save passwords in guest mode

## No root

Admin privileges are not present by default. The dumb user cannot be trusted with such power.
An advanced user can still do a lot of things without root permissions.
The root user will only be used `at boot` for reset AND to an account.


## Disk partitions structure

- **EFI:** Bootloader (Read-Only)
- **SYSTEM:** The Core OS (Read-Only)
- **PROGRAMS:** Programs will be installed here
- **USERS:** The data of the users
