set mem inaccessible-by-default on
set remote hardware-breakpoint-limit 6
target remote localhost:3333
symbol-file ./build/build_linux-imx_3.10.17/vmlinux
