# hw/xilinx_ip

One Tcl script per Xilinx IP instance (create_ip + set_property CONFIG.*), generated into
build/ at build time. `.xci` files are never committed. Check every option against the product
guide (cite PG number + section in the script header) and verify ports/clocks in Vivado (M0 spike).
List a script in a feature's files.f to have it sourced by the flows.
