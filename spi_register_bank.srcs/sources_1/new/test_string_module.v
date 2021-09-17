`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/15/2021 04:21:54 PM
// Design Name: 
// Module Name: test_string_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_string_module
#(
    parameter AddrSize=8
)
(
    input wire clk,
    input wire ena,
    input wire [0:0] wea,
    input wire [(AddrSize-1):0] spi_addr,
    input wire [15:0] dina,
    output wire [15:0] douta
);
    

string_module_blk_mem
module_memory(
    .clka(clk),     //in
    .ena(ena),      //in
    .wea(wea),      //in[0:0]
    .addra(spi_addr),   //in[7:0]
    .dina(dina),        //in[15:0]
    .douta(douta),       //out[15:0]
    .clkb(clk),   //IN STD_LOGIC;
    .enb(),      //IN STD_LOGIC;
    .web(), //IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    .addrb(),// IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    .dinb(),// IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    .doutb()// OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
);




//string_module_blk_mem
//module_memory(
//    .clka(clk),     //in
//    .ena(dpr_enable_a_reg),      //in
//    .wea(string_module_write_enable_a_reg),      //in[0:0]
//    .addra(string_module_address),   //in[7:0]
//    .dina(dpr_data_in_a),        //in[15:0]
//    .douta(string_module_data_out),       //out[15:0]
//    .clkb(),   //IN STD_LOGIC;
//    .enb(),      //IN STD_LOGIC;
//    .web(), //IN STD_LOGIC_VECTOR(0 DOWNTO 0);
//    .addrb(),// IN STD_LOGIC_VECTOR(7 DOWNTO 0);
//    .dinb(),// IN STD_LOGIC_VECTOR(15 DOWNTO 0);
//    .doutb()// OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
//);





endmodule
