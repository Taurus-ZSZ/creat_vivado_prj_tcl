
import os

#get parameter
# config_device_name EPCS128
# serial_flash_loader_device_name EP4SGX230


TCL_file_path = ' ./bit_convert_program.tcl'
# cmd = ' -mode tcl -source F:/XD1901_abroad/07_modify_sdc/test_bit.tcl '

print ('''project_type : 
            1:vivado
            2:quartus
\n''')

input_done_flag = 0
while (input_done_flag == 0 ):
    project_type = input('请输入你的工程类型:\n')
    print(project_type)
    if (project_type == '1'):
        MODE = ' -mode tcl '
        # MODE = '  '
        SOURCE = ' -notrace -source '
        OTHER_OPT = ' -nojournal -nolog '
        parameter = ' '
        EDA_PATH = 'd:/Xilinx/Vivado/2016.4/bin/vivado '
        input_done_flag = 1
    elif (project_type == '2') :
        MODE = ' -t '
        # SOURCE = ' -source -encoding utf-8 '
        SOURCE = ' '
        OTHER_OPT = ' ' 
        config_device_name= 'EPCS128'
        print ('''serial_flash_loader_device_type : 
            1:EP4SGX230
            2:EP4SGX530
        \n''')
        while (input_done_flag == 0 ):
            serial_flash_loader_device_type = input('请输入你的FPGA类型:\n')
            if (serial_flash_loader_device_type == '1') :
                input_done_flag = 1
                serial_flash_loader_device_name = 'EP4SGX230'
            elif (serial_flash_loader_device_type == '2') :
                input_done_flag = 1
                serial_flash_loader_device_name = 'EP4SGX530'
            else :
                input_done_flag = 0
                print("输入错误请重新输入\n")
        parameter =  ' '+config_device_name+ ' '+serial_flash_loader_device_name
        EDA_PATH = 'D:/altera/15.1/quartus/bin64/quartus_sh.exe '
        
    else :
        input_done_flag = 0
        print("输入错误请重新输入\n")


cmd = EDA_PATH + MODE + OTHER_OPT + SOURCE + TCL_file_path + parameter
os.system(cmd)

