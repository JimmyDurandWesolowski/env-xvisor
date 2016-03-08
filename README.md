# env-xvisor

Build environment for Xvisor.
Developed by OpenWide and Institut de Recherche Technologique SystemX.

## Usage

The build environment must be configured first by running `./configure` with
the appropriate arguments. Run `./configure --help` to have details about
the available configuration options.
Note that a board name **must** be specified with `-b` or board-specific
arguments.

Several components will be cloned within the `env-xvisor/build/`. Be careful
when running `make distclean` or removing the `build/` directory: if you
made changes to a component, these changes will be definitly lost!

These components are:
- an ARM toolchain (linaro), used to cross-compile other components;
- busybox, used to generate a minimal rootfs;
- u-boot, used to generate a bootable xvisor image;
- openocd, an on-chip debugger that can be very usefull when using a JTAG
  probe;
- linux: the kernel to be used to create an xvisor guest.


| Target | Function |
| ------ | -------- |
| prepare | Collects components (i.e. git clone + checkout) |
| xvisor | Compile and generates Xvisor image |
| disk   | Generates all necessary files (e.g. DTB, images, rootfs) in `build/disk/` |
| xvisor-menuconfig | Runs Xvisor configuration utility |
| linux-menuconfig | Runs Linux configuration utility |
| sd | Writes the contents of `build/disk/` in the partition specified by `$(SDDEV)1` |


__Example: Nitrogen6X__

```bash
./configure --xvisor devs/xxx/yyy -n  # Nitrogen6X with xvisor branch "devs/xxx/yyy"
make # Generate all components
make disk
make SDDEV=/dev/sdc sd # Flash on /dev/sdc1. The trailing 1 is automatically added.
```


## Using sd target

You need to have `pmount` and `pumount` installed, and be in the group `plugdev`.


## Using OpenOCD

```bash
make run
make telnet
```


## Authors

See the `AUTHORS` file.
