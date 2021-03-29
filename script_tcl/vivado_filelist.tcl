#处理源文件列表

#获取当前文件夹路径
set cur_dir [pwd]
puts $cur_dir

set proj_path   [lindex $argv 0]
set device_part [lindex $argv 1]
set proj_name   [lindex $argv 2]
set top_name    [lindex $argv 3]
set search_path [lindex $argv 4]

set proj_path [file normalize $proj_path ]
#创建输出文件夹
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

    #创建工程 设置器件：
    puts $tclfile_fid  "create_project $proj_name $proj_path -part $device_part -force"
    puts $tclfile_fid  "# STEP#2: setup design sources and constraints"
    gets $filelist_fid myline
        puts $myline
    while {![eof $filelist_fid]} {
        gets $filelist_fid myline
        puts $myline
        if {[regexp {^\#} $myline mat]} {
            puts "$myline invalid !!!!!!!!!!!!"
        } elseif {[regexp {(.*tb_)+(.*)+(\.)+(v)\s*$} $myline mat] } {    ;#tb_xxx.v 仿真文件
           #puts $myline
            puts $tclfile_fid "add_files -fileset sim_1 -norecurse $myline"
        } elseif {[regexp {(\.)+(xdc)\s*$} $myline mat] } {         ;# add xdc
            puts $tclfile_fid "add_files -fileset constrs_1 -norecurse $myline"
        } elseif {[regexp {(\.)+(v|vhd|vh|xci|tcl|txt)\s*$} $myline mat] } {
            puts $tclfile_fid "add_files -norecurse $myline"
        } elseif {[regexp {(\.)+(bd)\s*$} $myline mat] } {
            puts $tclfile_fid "read_bd  $myline"
        } elseif {[regexp {^\s*\s*$} $myline mat] } {
            puts "空白行！！！！"
        } else {
            puts "未识别的的文件格式！！！！"
            puts $myline
        }
    }
    puts $tclfile_fid "set_property top $top_name \[current_fileset\]"
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
generate_tcl2vivado $tcl_file $filelist_file $proj_name $proj_path $device_part $top_name
puts "执行 done "
exit