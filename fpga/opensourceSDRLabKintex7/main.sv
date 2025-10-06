module top (
    input  logic board_clk,
    input  logic rst_n,

    input  logic rxd,
    output logic txd,

    input  logic [4:0] btn,
    output logic [7:0] led,

    inout  logic [33:0] gpio

    `ifdef DRAM_ENABLE
    ,
    // DRAM interface
    inout  logic [31:0] ddram_dq,
    inout  logic [3:0]  ddram_dqs_n,
    inout  logic [3:0]  ddram_dqs_p,
    output logic [14:0] ddram_a,
    output logic [2:0]  ddram_ba,
    output logic        ddram_ras_n,
    output logic        ddram_cas_n,
    output logic        ddram_we_n,
    output logic        ddram_reset_n,
    output logic [0:0]  ddram_clk_p,
    output logic [0:0]  ddram_clk_n,
    output logic [0:0]  ddram_cke,
    output logic [0:0]  ddram_cs_n,
    output logic [3:0]  ddram_dm,
    output logic [0:0]  ddram_odt
    `endif
);

    // PLL and clock generation
    logic locked, sys_clk_100mhz;

    clk_wiz_0 clk_wiz_0_inst (
        .clk_out1 (sys_clk_100mhz), // 100 MHz system clock
        .resetn   (rst_n),          // Active low reset
        .locked   (locked),         // Locked signal
        .clk_in1  (board_clk)       // System clock - 50 MHz
    );


endmodule
