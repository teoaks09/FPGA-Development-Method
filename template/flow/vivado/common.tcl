# Shared helpers for batch Vivado scripts. Source from other scripts.
set ::repo_root [file normalize [file join [file dirname [info script]] .. ..]]

# Read a files.f list: one repository-relative path per line, '#' comments,
# '+incdir+<dir>' adds an include directory. Returns a dict {sources {...} incdirs {...}}.
proc read_file_list {list_path} {
    set sources {}
    set incdirs {}
    if {![file exists $list_path]} { return [dict create sources {} incdirs {}] }
    set handle [open $list_path r]
    foreach line [split [read $handle] "\n"] {
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq "#"} { continue }
        if {[string match "+incdir+*" $line]} {
            lappend incdirs [file join $::repo_root [string range $line 8 end]]
        } else {
            lappend sources [file join $::repo_root $line]
        }
    }
    close $handle
    return [dict create sources $sources incdirs $incdirs]
}

# Load design sources of a feature (common package first) into the in-memory project.
proc load_feature_sources {feature} {
    set incdirs {}
    foreach list_path [list [file join $::repo_root hw rtl common files.f] \
                            [file join $::repo_root hw rtl $feature files.f]] {
        set lists [read_file_list $list_path]
        set incdirs [concat $incdirs [dict get $lists incdirs]]
        foreach source [dict get $lists sources] {
            switch -glob -- $source {
                *.sv  { read_verilog -sv $source }
                *.v   { read_verilog $source }
                *.vhd { read_vhdl $source }
                *.xdc { read_xdc $source }
                *.tcl { source $source }
                default { puts "WARNING: unknown source type $source" }
            }
        }
    }
    return $incdirs
}

proc result_line {gate status details} {
    puts "${gate}_RESULT: $status $details"
}

# Read a simple string value from project.toml (key = "value"), e.g. [toml_value prefix].
proc toml_value {key} {
    set handle [open [file join $::repo_root project.toml] r]
    set text [read $handle]
    close $handle
    if {![regexp "\n$key = \"(\[^\"\]*)\"" $text -> value]} { error "project.toml: $key not found" }
    return $value
}
