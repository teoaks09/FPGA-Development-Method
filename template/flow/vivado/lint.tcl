# Vivado RTL lint (synth_design -lint). Args: feature part top
source [file join [file dirname [info script]] common.tcl]
lassign $argv feature part top
create_project -in_memory -part $part
set incdirs [load_feature_sources $feature]
set options [list -top $top -part $part -lint]
if {[llength $incdirs]} { lappend options -include_dirs $incdirs }
if {[catch {synth_design {*}$options} message]} {
    puts $message
    result_line LINT_VIVADO FAIL "feature=$feature (synth_design -lint failed)"
    exit 1
}
set errors [get_msg_config -count -severity ERROR]
set criticals [get_msg_config -count -severity {CRITICAL WARNING}]
if {$errors > 0} {
    result_line LINT_VIVADO FAIL "feature=$feature errors=$errors critical=$criticals"
    exit 1
}
result_line LINT_VIVADO PASS "feature=$feature critical=$criticals"
