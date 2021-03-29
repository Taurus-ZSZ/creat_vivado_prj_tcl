#processing sim do file
# cd D:/FPGA_work/FPGA_Board/ZC706/PL/02_SRIO/src/CMD

#  2020/12/25 注意这个脚本存在bug 当仿真文件夹存在多个*_simulate.do时会匹配多个，导致文件打开错误
#
#

#获取当前工作路径
set current_path [pwd]
#puts $current_path

set dict ./dofile/
# set proj_sim_name [file tail [glob ../../work/*.sim]]
set proj_sim_name [file tail [glob ../../../*.sim]]
#puts $proj_sim_name
# set destdict "../../work/$proj_sim_name/sim_1/behav/"
set destdict "./"
#puts $destdict



set restart_cmd "restart -force"
set run_cmd "run 1000ns"

#file mkdir $dict
set compile_do_filename  [glob $destdict*_compile.do]
set simulate_do_filename  [glob $destdict*_simulate.do]
set top_wave_do_filename  [glob $destdict*_top_wave.do]

set shot_top_wave_do_filename [file tail $top_wave_do_filename]
#puts $shot_top_wave_do_filename

puts $compile_do_filename
puts $simulate_do_filename

# 只保留最新的文件
set len_list [llength $compile_do_filename]
puts $len_list

set file_time_temp 0
set cnt_temp 0
for {set cnt 0} {$cnt < $len_list} {incr cnt} {
    puts $cnt
    set file_time [file atime [lindex $compile_do_filename $cnt] ]
    if { $file_time < $file_time_temp} {
       # file delete [lindex $compile_do_filename $cnt]    
    } else {
        # if {$file_time_temp} {
           # file delete [lindex $compile_do_filename $cnt_temp]    
        # }
        set cnt_temp $cnt
        set file_name_temp [lindex $compile_do_filename $cnt_temp] 
        set file_time_temp $file_time
    }
}
set compile_do_filename $file_name_temp


set len_list [llength $simulate_do_filename]
set file_time_temp 0
set cnt_temp 0
for {set cnt 0} {$cnt < $len_list} {incr cnt} {
    puts $cnt
    set file_time [file atime [lindex $simulate_do_filename $cnt] ]
    if { $file_time < $file_time_temp} {
       # file delete [lindex $simulate_do_filename $cnt]    
    } else {
        # if {$file_time_temp} {
           # file delete [lindex $simulate_do_filename $cnt_temp]    
        # }
        set cnt_temp $cnt
        set file_name_temp [lindex $simulate_do_filename $cnt_temp] 
        set file_time_temp $file_time
    }
}


set new_sim_do_name tb_sim.do
set no_quit_compile_do_name tb_compile_no_quit.do

set simulate_do_filename $file_name_temp

set rsfid [open "$simulate_do_filename" r]
set fid [open "$compile_do_filename" r]
set wfid [open "$destdict$new_sim_do_name" w]




while {![eof $rsfid]} {
    gets $rsfid myline
    if {[regsub "$shot_top_wave_do_filename" $myline " " myline]} {
        while {![eof $fid]} {
            gets $fid myline
            puts $myline
            if {[regsub "quit -force" $myline " " myline]} {
                puts $wfid $myline
            } else {
                puts $wfid $myline
            }
        }
    } elseif {[regsub "processing_do.tcl" $myline " " myline]} {
        puts $wfid " "
    } else {
        puts $wfid $myline
    }
}

close $rsfid
close $fid
close $wfid

set fid [open "$compile_do_filename" r]
set wnqfid [open "$destdict$no_quit_compile_do_name" w]

 while {![eof $fid]} {
    gets $fid myline
    puts $myline
    if {[regsub "quit -force" $myline " " myline]} {
        puts $wnqfid $myline
    } else {
        puts $wnqfid $myline
    }
}

puts $wnqfid $restart_cmd
puts $wnqfid $run_cmd

close $fid
close $wnqfid
