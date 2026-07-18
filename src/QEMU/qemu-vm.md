# Generic QEMU Machine x86_64 UEFI

- Intel HD Audio (`-audio pa,model=hda`)
- Intel Network Driver (`-netdev user,id=example0 -device e1000,netdev=example0`)
- UEFI (`-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd -drive if=pflash,format=raw,file=/copy/of/OVMF_VARS.4m.fd`)


```
qemu -accel kvm -m 4G -audio pa,model=hda -netdev user,id=example0 -device e1000,netdev=example0 -drive if=pflash,format=raw,readonly=on,file=/opt/qemu/share/qemu/edk2-x86_64-code.fd
```