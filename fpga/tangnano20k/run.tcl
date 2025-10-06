yosys read_verilog main.sv

yosys synth_gowin -json ./build/out.json -abc9
