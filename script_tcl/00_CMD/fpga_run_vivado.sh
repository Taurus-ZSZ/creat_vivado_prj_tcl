##!/bin/bash
echo "hello world!"

#exec tclsh ./vivado_filelist.tcl -device_part sr2367
proj_path=../../work
device_part=xc7z010clg400-2
proj_name=t_test
top_name=top

filelist_file=../filelist.f
#sys_param[0][0]=$proj_name
#sys_param[1][0]=$proj_path
#sys_param[2][0]=$device_part
#sys_param[3][0]=$top_name
#exec tclsh ./test.tcl "t_test" "./" "xc7z010clg400-2" "top"
#exec tclsh ./test.tcl  $proj_path $device_part $proj_name $top_name $filelist_file

#ע��ʹ�����exec ִ��tcl�ᵼ���޷�ִ������Ľű�����Ҫ�ǵ���vivado �����
#exec tclsh vivado_filelist.tcl $proj_path $device_part $proj_name $top_name $filelist_file

tclsh /opt/FPGA_work/Tcl/script_tcl/vivado_filelist.tcl $proj_path $device_part $proj_name $top_name $filelist_file

echo "generate file ok"
cd $proj_path

source  /opt/Xilinx/Vivado/2018.3/settings64.sh 
vivado -mode batch  -source ./_prj__.tcl