# Out-of-context synthesis + place & route + timing for one feature.
# Args: feature part clock_mhz top clock_port mode(synth|impl)
source [file join [file dirname [info script]] common.tcl]
lassign $argv feature part clock_mhz top clock_port mode
if {$mode eq ""} { set mode impl }
set out [file join $::repo_root build ooc $feature]
file mkdir $out
create_project -in_memory -part $part

set feature_xdc [file join $::repo_root hw constraints ooc $feature.xdc]
if {[file exists $feature_xdc]} {
    read_xdc -mode out_of_context $feature_xdc
} else {
    # Default: one clock on $clock_port at the spec frequency.
    set period [format %.3f [expr {1000.0 / $clock_mhz}]]
    set generated [file join $out ooc_clock.xdc]
    set handle [open $generated w]
    puts $handle "create_clock -name $clock_port -period $period \[get_ports $clock_port\]"
    close $handle
    read_xdc -mode out_of_context $generated
}
set incdirs [load_feature_sources $feature]
set options [list -top $top -part $part -mode out_of_context]
if {[llength $incdirs]} { lappend options -include_dirs $incdirs }
synth_design {*}$options
if {$mode eq "impl"} {
    opt_design
    place_design
    route_design
}
report_timing_summary -file [file join $out timing_summary.rpt]
report_utilization    -file [file join $out utilization.rpt]
check_timing -verbose -file [file join $out check_timing.rpt]

set setup_path [get_timing_paths -max_paths 1 -nworst 1 -setup]
set hold_path  [get_timing_paths -max_paths 1 -nworst 1 -hold]
set wns [expr {[llength $setup_path] ? [get_property SLACK $setup_path] : "NA"}]
set whs [expr {[llength $hold_path]  ? [get_property SLACK $hold_path]  : "NA"}]
if {$wns eq "NA"} {
    result_line OOC FAIL "feature=$feature no timed paths (clock port '$clock_port' missing?)"
    exit 1
}
set status [expr {($wns >= 0 && ($whs eq "NA" || $whs >= 0)) ? "PASS" : "FAIL"}]
result_line OOC $status "feature=$feature mode=$mode clock=${clock_mhz}MHz WNS=$wns WHS=$whs"
if {$status ne "PASS"} { exit 1 }
