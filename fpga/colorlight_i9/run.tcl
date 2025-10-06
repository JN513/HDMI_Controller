yosys read_systemverilog -defer main.sv
yosys read_systemverilog -link

yosys synth_ecp5 -json ./build/out.json -abc9