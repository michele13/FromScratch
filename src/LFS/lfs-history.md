# Linux From Scratch History

In this webpage we will (insert verb) the versions of LFS backwards, mark and describe why they are relevant for me.


| Version | Why is it important? |Required By| Other Notes |
|:--------|----------------------|-----------|-------------|
| 13      | Drop SysV init       |-          |Next Version|
|**12.4** |Last version that supports SysV init|-|Current Version|
|10.0|Use new cross method to build temp system|-|-|
|**9.1**| Last version to patch gcc so that it links executables to `/tools/lib/ld-linux.so.*`| - |-|
|8.0|first version of LFS I printed|-|-|
|7.10|first version of LFS I built|-|-|
|7.5| first **systemd** release
|**7.3**|ships with GCC 4.7.2|-|c++ compiler required after GCC 4.7.4|
|6.4|GCC 4.1.2|Required by LFS 7.3|
|6.0|Linux 2.6.x, use `/tools` directory, static linking|Required by LFS 6.4|
|5.0|/static -> /stage1 -> /tools|-|GCC-2.95.3, GCC 3.2.3, Linux 2.4.22|
|4.0| Use `/static` directory, the `lfs` user makes its appearence|-|-|
|3.0|LFS and BLFS split|-|BLFS releases go from 1.0 to 5.0-pre1, etc|
|2.0-pre1|strange release, one single html file|-|27 pages|
|1.0|The first release, X11, uses static linking|-|GCC 2.95 and 2.7.2|