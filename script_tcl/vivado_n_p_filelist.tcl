#处理源文件列表

#获取当前文件夹路径
set cur_dir [pwd]
puts $cur_dir

set proj_path   [lindex $argv 0]
set device_part [lindex $argv 1]
set proj_name   [lindex $argv 2]
set top_name    [lindex $argv 3]
set search_path [lindex $argv 4]

puts "$proj_path"
set proj_path [file normalize $proj_path ]
#创建输出文件夹
puts "$proj_path"
file mkdir $proj_path

set tcl_file "$proj_path/_prj__.tcl"
set w_file_name "$proj_path/_prj__.f"
set filelist_file  $w_file_name 

#打开文件并准备写入

set w_file_fid [open "$w_file_name" w]

#用来处理.f文件并且实现递归处理

set i 0
proc process_file {file_name w_file_fid args} {
    if {[regexp {\.f$} $file_name]} {
       set  fid [open "$file_name" r]
       set file_valid 1 ;#标识文件有效
       #切换工作路径
       # set debug [file dirname &file_name]
       # set debug [file extension $file_name] ;#获取文件的扩展名
       set debug [file normalize $file_name] ;#获取文件的绝对路径
       # set debug [file rootname $file_name] ;#去除扩展名的文件名带有路经
       # set debug [file tail $debug] ;#获取文件名带有扩展名

       set debug [file split $debug] ;#拆分路径和文件名
       #puts "ce shi $debug"
       set list_len [llength $debug]
       #puts $list_len
       set debug [lreplace $debug $list_len-1 $list_len-1]
       #puts "ce shi $debug"
       set temp_path " "
       foreach j $debug {
           set temp_path [file join $temp_path $j]  ;#拼接路径
           #puts $temp_path
       }
       cd $temp_path
       #puts "filepath is     $temp_path "
       #puts "filepath is     [pwd] "
    } else {
        set file_valid 0
        puts "error !!! .f  the file dose not exist !!!!"
    }

    if {$file_valid == 1} {
        #处理.f文件 
        set i 0
        while {![eof $fid]} {
            gets $fid myline
            if {[regexp {^\#} $myline mat]} {
                puts "invalid !!!!!!!!!!!!"
                puts $myline
            } elseif {[regexp {(\.)+(v|vhd|vh|xci|xdc|tcl|bd)\s*$} $myline mat] } {
                puts "$myline is item number $i  match is $mat "
                #puts "match ok "
                puts $w_file_fid [file normalize $myline]
            } elseif {[regexp {(\.)+(f)\s*$} $myline mat] } {
                puts "$myline is filelist !!!!"
                set myline [file normalize $myline]
                #puts $myline
                process_file $myline $w_file_fid
                cd $temp_path   ;#返回上一次处理的文件夹
            } else {
                puts "$myline is match failed!!!!"
            }
            incr i
        }
    }
    #处理结束关闭文件
    if {$file_valid == 1} {
        close $fid 
    }
    return 1
}
proc generate_tcl2vivado {tcl_file filelist_file proj_name proj_path device_part top_name args} {
    if {[regexp {\.f$} $filelist_file]} {
       set filelist_fid [open "$filelist_file" r]
       set filelist_valid 1 ;#标识文件有效
       set tclfile_fid [open "$tcl_file" w] ;#打开tcl文件写入指令进入文件
       set tclfile_valid 1 ;#标识文件有效
       puts "file is open "
    } else {
        puts "$filelist_file file open error!!!"
        #break 
    }
    
    #no project mode ：
    #puts $tclfile_fid  "create_project $proj_name $proj_path -part $device_part -force"

    puts $tclfile_fid  "# STEP#1: define the output directory\n"
   
    set outputDir $proj_path
    file mkdir $outputDir

    puts $tclfile_fid  "# STEP#2: setup design sources and constraints\n"
    while {![eof $filelist_fid]} {
        gets $filelist_fid myline
        puts $myline
        if {[regexp {^\#} $myline mat]} {
            puts "$myline invalid !!!!!!!!!!!!"
        } elseif {[regexp {(.*tb_)+(.*)+(\.)+(v)\s*$} $myline mat] } {    ;#tb_xxx.v 仿真文件
           #puts $myline
            puts $tclfile_fid "add_files -fileset sim_1 -norecurse $myline"
        } elseif {[regexp {(\.)+(xdc)\s*$} $myline mat] } {         
            #puts "$myline is ok"
            puts $tclfile_fid "read_xdc $myline"
        } elseif {[regexp {(\.)+(v)\s*$} $myline mat] } {
            #puts "$myline is ok"
            puts $tclfile_fid "read_verilog $myline"
        } elseif {[regexp {(\.)+(sv)\s*$} $myline mat] } {
            puts $tclfile_fid "read_verilog -sv $myline"
        } elseif {[regexp {(\.)+(vhd|vhdl)\s*$} $myline mat] } {
            puts $tclfile_fid "read_vhdl $myline"
        } elseif {[regexp {(\.)+(xci)\s*$} $myline mat] } {
            puts $tclfile_fid "read_ip $myline"
        } elseif {[regexp {(\.)+(bd)\s*$} $myline mat] } {
            puts $tclfile_fid "read_bd  $myline"
        } elseif {[regexp {^\s*\s*$} $myline mat] } {
            puts "空白行！！！！"
        } else {
            puts "未识别的的文件格式！！！！"
            puts $myline
        }
    }

    #puts $tclfile_fid "exit \n\n"

    puts $tclfile_fid "# STEP#3: run synthesis, write design checkpoint, report timing,"
    puts $tclfile_fid "# and utilization estimates\n"

    puts $tclfile_fid "synth_design -top $top_name -part $device_part"
    puts $tclfile_fid "write_checkpoint -force  $outputDir/post_synth"
    puts $tclfile_fid "report_timing_summary -file $outputDir/post_synth_timing_summary.rpt"
    puts $tclfile_fid "report_utilization -file $outputDir/post_synth_util.rpt\n"
    
    puts $tclfile_fid "#run custom script to report critical timing paths"
    #puts $tclfile_fid "reportCriticalPaths $outputDir/post_synth_critpath_report.csv\n"

    puts $tclfile_fid "# STEP#4: run logic optimization, placement and physical logic optimization,"
    puts $tclfile_fid "# write design checkpoint,report utilization and timing estimates\n"

    puts $tclfile_fid "opt_design"
    #puts $tclfile_fid "reportCriticalPaths $outputDir/post_opt_critpath_report.csv"
    puts $tclfile_fid "place_design"
    puts $tclfile_fid "report_clock_utilization -file $outputDir/clock_util.rpt\n"

    puts $tclfile_fid "#Optionally run optimization if there are timing violations after placement"
    puts $tclfile_fid "if \{\[get_property SLACK \[get_timing_paths -max_paths 1 -nworst 1 -setup \]\] < 0\} \{"
    puts $tclfile_fid "puts \"Found setup timing violations => runing physical optimization\""
    puts $tclfile_fid "phy_opt_design"
    puts $tclfile_fid "\}"
    puts $tclfile_fid "write_checkpoint -force  $outputDir/post_place"
    puts $tclfile_fid "report_utilization -file $outputDir/post_place_util.rpt"
    puts $tclfile_fid "report_timing_summary -file $outputDir/post_place_timing_summary.rpt\n"

    puts $tclfile_fid "# STEP#5: run the router, write the post-route design checkpoint,report the routing"
    puts $tclfile_fid "# status, report timing, power, and DRC, and finally save the Verilog netlist\n"

    puts $tclfile_fid "route_design"
    puts $tclfile_fid "write_checkpoint -force  $outputDir/post_route"
    puts $tclfile_fid "report_route_status -file  $outputDir/post_route_status.rpt"
    puts $tclfile_fid "report_power -file  $outputDir/post_route_power.rpt"
    puts $tclfile_fid "report_drc -file  $outputDir/post_imp_drc.rpt"
    puts $tclfile_fid "write_verilog -force $outputDir/${top_name}_imp_netlist.v -mode timesim -sdf_anno true\n"

    puts $tclfile_fid "# STEP#6: generate a bitstream\n"

    puts $tclfile_fid "write_bitstream -force $outputDir/${top_name}.bit"

    puts $tclfile_fid "exit"

    if {$filelist_valid == 1} {
        close $filelist_fid
        #puts "file close "
    }

    if {$tclfile_valid == 1} {
        close $tclfile_fid
        #puts "file close "
    }
}





#处理filelist.f文件
process_file $search_path $w_file_fid   
cd $cur_dir
#生成创建工程的脚本文件
#关闭文件
close $w_file_fid  
puts "$filelist_file"
puts "$top_name"
generate_tcl2vivado $tcl_file $filelist_file $proj_name $proj_path $device_part $top_name
puts "执行 done "
exit