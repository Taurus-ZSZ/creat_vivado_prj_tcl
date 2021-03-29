set lst [list "fir_wrapper.v  1" "fir_v1.v" "dds_msk_freq_mod.xcit" "./dds_msk_weight_mod/dds_msk_weight_modxci    " ]
puts $lst

set i 0
lappend lst "ZC706_pins.xdc"
puts $lst

foreach j $lst {
   
    if {[regexp {(\.)+(v|xci|xdc)\s*$} $j mat] } {
        puts "$j is item number $i match is $mat "
        puts "match ok "
    } else {
        puts "$j is match failed!!!!"
    }
    incr i

}

set file_name "./file_name.f"
set file_fid [open "$file_name" r]

while {![eof $file_fid]} {
    gets $file_fid myline
    puts $myline
}


lindex $argv 0
foreach i $argv {
    puts $i
}
puts $argc
