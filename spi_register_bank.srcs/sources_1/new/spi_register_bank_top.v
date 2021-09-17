`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2020 09:34:02 AM
// Design Name: 
// Module Name: spi_register_bank_top
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


module spi_register_bank_top
#(
    parameter MsgBitCount=32,
    parameter AddrCmndMsgSize=16,
    parameter DataMsgSize=16,
    parameter SPIAddrSize=15,
    parameter StringModuleAddrSize=8
)
(
    //GPIO
    input wire clk,                 //INPUT CLOCK
//    input wire [3:0]switches,       //ARTY SWITCHES
//    input wire btn0,                //ARTY BTN0
//    input wire btn1,                //ARTY BTN1
//    input wire btn2,                //ARTY BTN2
//    input wire btn3,                //ARTY BTN3
//    output wire [3:0] led,          //ARTY LEDS

    //SPI interface A
    input wire SCK_a,             //SERIAL CLOCK FROM MASTER
    input wire MOSI_a,            //MASTER OUT SLAVE IN
    input wire SSEL_a,            //SLAVE/CHIP SELECT
    output wire MISO_a_out       //MASTER IN SLAVE OUT
);

//IDENTIFICATION
localparam  PROGRAM_ID = 16'h0100,      //Tells Microcontroller that this a basic spi setup        
            VERSION_LARGE = 12'd0,      //Top 12 bits of Version
            VERSION_SMALL = 4'd2;      //Bottom 4 bits of Version
reg [15:0] ID_reg, VERSION_reg;

localparam MAX_SPI_ADDR = 15'hffff;
wire MISO_a;          //OUTPUT HOLDER FOR MISO

//ARM
wire spi_rx_command_a;
wire [(SPIAddrSize-1):0] spi_rx_addr_a;
reg [(SPIAddrSize-1):0] dpr_address_a;
//reg [15:0] dpr_data_in_a;
//reg dpr_enable_a_reg;
//reg dpr_enable_a_next;        

//reg [0:0] dpr_write_enable_reg_a;
wire dpr_write_enable_a;  

wire read_write_data_complete_a;                 //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
wire addr_cmnd_set_complete_a;                      //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
wire [15:0] spi_write_data_a;
wire [15:0] dpr_data_output_a;        //
reg [15:0] spi_data_out_a;            //miso output

integer i;
localparam  STRING_DATA_BASE1 = 12'h000,
            STRING_DATA_END1 =  12'h0ff,
            STRING_DATA_BASE2 = 12'h100,    
            STRING_DATA_END2 = 12'h1ff;    

//STRING MODULE 1 VARIABLES
reg [(StringModuleAddrSize-1):0] string_module1_address;
reg [0:0] string_module1_write_enable_reg, string_module1_write_enable_next;
wire [15:0] string_module1_data_out;
reg string_module1_enable_reg, string_module1_enable_next;
reg [15:0] string_module1_data_in;

//STRING MODULE 2 VARIABLES
reg [(StringModuleAddrSize-1):0] string_module2_address;
reg [0:0] string_module2_write_enable_reg, string_module2_write_enable_next;
wire [15:0] string_module2_data_out;
reg string_module2_enable_reg, string_module2_enable_next;
reg [15:0] string_module2_data_in;

//SPI SLAVE INTERFACE A
SPI_slave 
#(
.MsgBitCount(MsgBitCount), 
.AddrCmndMsgSize(AddrCmndMsgSize), 
.DataMsgSize(DataMsgSize), 
.AddrSize(SPIAddrSize) 
)
spi_slave_inst_a(
    .clk(clk),          //in
    //.reset(reset),      //in
    //SPI SIGNALS
    .SCK(SCK_a),          //in//SERIAL CLOCK FROM MASTER
    .MOSI(MOSI_a),        //in//MASTER OUT SLAVE IN
    .SSEL(SSEL_a),        //in//SLAVE/CHIP SELECT
    .MISO(MISO_a),        //out//MASTER IN SLAVE OUT
    //DATA TO/FROM DUAL PORT RAM
    .DPR_READ_DATA(spi_data_out_a),       //in//DATA FROM RAM TO WRITE TO MASTER
    .DPR_WRITE_DATA(spi_write_data_a),    //out//DATA TO WRITE TO RAM DURING WRITE OPERATION
    //CONTROL SIGNALS
    .readwritedata_complete(read_write_data_complete_a),//out   //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
    .addrcmnd_complete(addr_cmnd_set_complete_a),          //out   //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
    .SPI_CommandOut(spi_rx_command_a),                       //out   //READ/WRITE BIT IN ADDRESS AND COMMAND MESSAGE
    .SPI_AddressOut(spi_rx_addr_a)                        //out   //READ/WRITE ADDRESS IN ADDRESS AND COMMAND MESSAGE
);

//DUAL PORT RAM CONTROL PI #1
DualPortRamCtrl DPRC_a(
    .clk(clk),                                                      //in
    //.reset(reset),                                                  //in
    .SPI_Slave_CommandIn(spi_rx_command_a),                              //in
    .spi_slave_addrcmnd_complete(addr_cmnd_set_complete_a),            //in
    .spi_slave_readwritedata_complete(read_write_data_complete_a),  //in
    .DPR_Enable(dpr_enable_a),                                 //out
    .DPR_WriteEnable(dpr_write_enable_a)                        //out
//    .start()                                                      //out
);

test_string_module 
#(
.AddrSize(StringModuleAddrSize)
)
string_module_inst1
(
    .clk(clk),               //in
    .ena(string_module1_enable_reg),          //in
    .wea(string_module1_write_enable_reg),     //in
    .spi_addr(string_module1_address),           //in
    .dina(string_module1_data_in),             //in
    .douta(string_module1_data_out)           //out  
);

test_string_module 
#(
.AddrSize(StringModuleAddrSize)
)
string_module_inst2
(
    .clk(clk),               //in
    .ena(string_module2_enable_reg),          //in
    .wea(string_module2_write_enable_reg),     //in
    .spi_addr(string_module2_address),           //in
    .dina(string_module2_data_in),             //in
    .douta(string_module2_data_out)           //out  
);



//SYNC SHARED REGISTERS
always @(posedge clk)
begin
    ID_reg <= PROGRAM_ID;
    VERSION_reg <= {VERSION_LARGE, VERSION_SMALL};

    //Set flat register space address
    dpr_address_a <= spi_rx_addr_a;
end

////UPDATE SHARED REGISTERS
//always @*
//begin
//    dpr_enable_a_next = dpr_enable_a;
//end


//MODULE 1 SYNC
//For writing from spi interface to module 1
always @(posedge clk)
begin
    //Set string module address
    string_module1_address <= spi_rx_addr_a - STRING_DATA_BASE1;
    //spi data to dps control
    string_module1_data_in <= spi_write_data_a;
    //sync dpr enables from controller
    string_module1_enable_reg <= string_module1_enable_next;
    //sync string module write enable
    string_module1_write_enable_reg <= string_module1_write_enable_next;
end

//MODULE 1 ASYNC CONTROL
//For writing from spi interface a
always@*
begin
    string_module1_write_enable_next = 1'b0;
    string_module1_enable_next = 1'b0;
    
    if(spi_rx_addr_a >= STRING_DATA_BASE1 && spi_rx_addr_a <= STRING_DATA_END1)
    begin
        string_module1_write_enable_next = dpr_write_enable_a;
        string_module1_enable_next = dpr_enable_a;
    end

    
end

//MODULE 2 SYNC
//For writing from spi interface to module 2
always @(posedge clk)
begin
    //Set string module address
    string_module2_address <= spi_rx_addr_a - STRING_DATA_BASE2;
    //spi data to dps control
    string_module2_data_in <= spi_write_data_a;
    
    //sync dpr enables from controller
    string_module2_enable_reg <= string_module2_enable_next;    
    //sync string module write enable
    string_module2_write_enable_reg <= string_module2_write_enable_next;
end

//MODULE 2 ASYNC CONTROL
//For writing from spi interface a
always@*
begin
    string_module2_write_enable_next = 1'b0;
    string_module2_enable_next = 1'b0;
    
    if(spi_rx_addr_a >= STRING_DATA_BASE2 && spi_rx_addr_a <= STRING_DATA_END2)
    begin
        string_module2_write_enable_next = dpr_write_enable_a;
        string_module2_enable_next = dpr_enable_a;
    end
end

//REGISTERS LOGIC UPDATE
//For reading out to spi interface a
always @(posedge clk)
begin
    //if address is in string module then access from within module
    if(spi_rx_addr_a >= STRING_DATA_BASE1 && spi_rx_addr_a <= STRING_DATA_END1)
    begin
        //Set data output from module 1
        spi_data_out_a = string_module1_data_out;
    end
    else if(spi_rx_addr_a >= STRING_DATA_BASE2 && spi_rx_addr_a <= STRING_DATA_END2)
    begin
        //Set data output from module 2
        spi_data_out_a = string_module2_data_out;
    end
    else
    //if address is in config space then get config registers
    begin
        casex(dpr_address_a)
            MAX_SPI_ADDR - 1 : spi_data_out_a = VERSION_reg;
            MAX_SPI_ADDR : spi_data_out_a = ID_reg;     
            default: spi_data_out_a = 16'hffff;
        endcase
    end
end
    

assign MISO_a_out = MISO_a;         //CONNECT MISO OUTPUT TO MISO HOLDER



endmodule
