@echo off
cd /d%~dp0
md "..\\..\\work"
copy .\\fpga_run_xilinx.bat ..\\..\\work
cd ..\\..\\work
fpga_run_xilinx.bat
pause