# Create a Vivado project under build/vivado for GUI work. Args: part [board]
# The project references repository files in place; never commit build/.
source [file join [file dirname [info script]] common.tcl]
lassign $argv part board
set project_dir [file join $::repo_root build vivado]
create_project -force project $project_dir -part $part
foreach feature_dir [glob -nocomplain -type d [file join $::repo_root hw rtl *]] {
    set lists [read_file_list [file join $feature_dir files.f]]
    foreach source [dict get $lists sources] { add_files -norecurse $source }
}
foreach xdc [glob -nocomplain [file join $::repo_root hw constraints ip *.xdc]] {
    add_files -fileset constrs_1 -norecurse $xdc
}
if {$board ne ""} {
    set board_dir [file join $::repo_root hw boards $board]
    foreach xdc [glob -nocomplain [file join $board_dir *.xdc]] {
        add_files -fileset constrs_1 -norecurse $xdc
    }
    foreach bd_tcl [glob -nocomplain [file join $board_dir bd *.tcl]] { source $bd_tcl }
    foreach source [dict get [read_file_list [file join $board_dir files.f]] sources] { add_files -norecurse $source }
    set_property top [toml_value prefix]_${board}_top [current_fileset]
}
update_compile_order -fileset sources_1
puts "Project created at $project_dir (GUI changes must be written back to Tcl/XDC)."
