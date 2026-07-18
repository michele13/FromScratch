# QEMU command-line: behavior of ‘-serial stdio’ vs. ‘-serial mon:stdio’

Original Source: <https://kashyapc.wordpress.com/2016/02/11/qemu-command-line-behavior-of-serial-stdio-vs-serial-monstdio/>

I forget to remember: to avoid QEMU being terminated on SIGINT (Ctrl+c), instead of just `stdio`, supply the special parameter `mon:stdio` to `-serial` option (which redirects the virtual serial port to a host character device). The subtle difference between them:

- `-serial stdio`: Redirects the virtual serial port onto stdio; upon Ctrl+c, QEMU immediately terminates.
- `-serial mon:stdio`: In this mode, the virtual serial port and QEMU monitor are multiplexed onto stdio. And Ctrl+c is handled, i.e. QEMU won’t be terminated, and the signal will be passed to the guest.

In summary, a working example command-line:

```bash
 qemu-system-x86_64               \
   -display none                   \
   -nodefconfig                    \
   -nodefaults                     \
   -m 2048                         \
   -device virtio-scsi-pci,id=scsi \
   -device virtio-serial-pci       \
   -serial mon:stdio  \
   -drive file=./fedora23.qcow2,format=qcow2,if=virtio
```

To toggle between QEMU monitor prompt and the serial console, use Ctrl+a, followed by typing ‘c’. To terminate QEMU, while at monitor prompt, `(qemu)`, type ‘quit’.