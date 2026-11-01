# Board implementation: synthesis, implementation, timing check, bitstream. Args: board part
source [file join [file dirname [info script]] common.tcl]
lassign $argv board part
set board_dir [file join $::repo_root hw boards $board]
set out [file join $::repo_root build impl $board]
file mkdir $out
create_project -in_memory -part $part
foreach feature_dir [glob -nocomplain -type d [file join $::repo_root hw rtl *]] {
    set lists [read_file_list [file join $feature_dir files.f]]
    foreach source [dict get $lists sources] { read_verilog -sv $source }
}
foreach ip_tcl [glob -nocomplain [file join $::repo_root hw xilinx_ip *.tcl]] { source $ip_tcl }
foreach bd_tcl [glob -nocomplain [file join $board_dir bd *.tcl]] { source $bd_tcl }
foreach source [dict get [read_file_list [file join $board_dir files.f]] sources] { read_verilog -sv $source }
foreach xdc [concat [glob -nocomplain [file join $::repo_root hw constraints ip *.xdc]] \
                    [glob -nocomplain [file join $board_dir *.xdc]]] { read_xdc $xdc }
synth_design -top [toml_value prefix]_${board}_top -part $part
opt_design
place_design
route_design
report_timing_summary -file [file join $out timing_summary.rpt]
report_utilization    -file [file join $out utilization.rpt]
set setup_path [get_timing_paths -max_paths 1 -nworst 1 -setup]
set hold_path  [get_timing_paths -max_paths 1 -nworst 1 -hold]
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
if {$wns < 0 || $whs < 0} {
    result_line IMPL FAIL "board=$board WNS=$wns WHS=$whs"
    exit 1
}
write_bitstream -force [file join $out $board.bit]
result_line IMPL PASS "board=$board WNS=$wns WHS=$whs"
