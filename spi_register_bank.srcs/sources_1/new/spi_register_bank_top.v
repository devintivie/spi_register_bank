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
    output wire MISO_a_out,       //MASTER IN SLAVE OUT
    
    //SPI interface B
    input wire SCK_b,             //SERIAL CLOCK FROM MASTER
    input wire MOSI_b,            //MASTER OUT SLAVE IN
    input wire SSEL_b,            //SLAVE/CHIP SELECT
    output wire MISO_b_out       //MASTER IN SLAVE OUT
);

//IDENTIFICATION
localparam  PROGRAM_ID = 16'h0100,      //Tells Microcontroller that this a basic spi setup        
            VERSION_LARGE = 12'd0,      //Top 12 bits of Version
            VERSION_SMALL = 4'd2;      //Bottom 4 bits of Version
reg [15:0] ID_reg, VERSION_reg;

localparam MAX_SPI_ADDR = 15'hffff;
wire MISO_a;          //OUTPUT HOLDER FOR MISO
wire MISO_b;          //OUTPUT HOLDER FOR MISO

//ARM
wire spi_rx_command_a;
wire [(SPIAddrSize-1):0] spi_rx_addr_a;
reg [(SPIAddrSize-1):0] dpr_address_a;
reg dpr_write_enable_a;  
wire read_write_data_complete_a;                 //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
wire addr_cmnd_set_complete_a;                      //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
wire [15:0] spi_write_data_a;
wire [15:0] dpr_data_output_a;        //
reg [15:0] spi_data_out_a;            //miso output
//reg [15:0] dpr_data_in_a;
reg dpr_enable_a;//_reg, dpr_enable_a_next;   
wire dprc_enable_a;     

//PI
wire spi_rx_command_b;
wire [(SPIAddrSize-1):0] spi_rx_addr_b;
reg [(SPIAddrSize-1):0] dpr_address_b;
reg dpr_write_enable_b;  
wire read_write_data_complete_b;                 //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
wire addr_cmnd_set_complete_b;                      //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
wire [15:0] spi_write_data_b;
wire [15:0] dpr_data_output_b;        //
reg [15:0] spi_data_out_b;            //miso output
//reg [15:0] dpr_data_in_b;
reg dpr_enable_b;//_reg, dpr_enable_a_next;   
wire dprc_enable_b;     

integer i;
localparam  STRING_DATA_BASE1 = 12'h000,
            STRING_DATA_END1 =  12'h0ff,
            STRING_DATA_BASE2 = 12'h100,    
            STRING_DATA_END2 = 12'h1ff,
            STRING_DATA_BASE3 = 12'h200,    
            STRING_DATA_END3 = 12'h2ff;      

//STRING MODULE 1 VARIABLES
reg [(StringModuleAddrSize-1):0] string_module1_address_reg, string_module1_address_next;
reg [0:0] string_module1_write_enable_reg, string_module1_write_enable_next;
wire [15:0] string_module1_data_out;
reg string_module1_enable_reg, string_module1_enable_next;
reg [15:0] string_module1_data_in_reg, string_module1_data_in_next;

//STRING MODULE 2 VARIABLES
reg [(StringModuleAddrSize-1):0] string_module2_address_reg, string_module2_address_next;
reg [0:0] string_module2_write_enable_reg, string_module2_write_enable_next;
wire [15:0] string_module2_data_out;
reg string_module2_enable_reg, string_module2_enable_next;
reg [15:0] string_module2_data_in_reg, string_module2_data_in_next;

//STRING MODULE 3 (SHARED) VARIABLES
reg [(StringModuleAddrSize-1):0] string_module3_address_reg, string_module3_address_next;
reg [0:0] string_module3_write_enable_reg, string_module3_write_enable_next;
wire [15:0] string_module3_data_out;
reg string_module3_enable_reg, string_module3_enable_next;
reg [15:0] string_module3_data_in_reg, string_module3_data_in_next;


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

//SPI SLAVE INTERFACE B
SPI_slave 
#(
.MsgBitCount(MsgBitCount), 
.AddrCmndMsgSize(AddrCmndMsgSize), 
.DataMsgSize(DataMsgSize), 
.AddrSize(SPIAddrSize) 
)
spi_slave_inst_b(
    .clk(clk),          //in
    //.reset(reset),      //in
    //SPI SIGNALS
    .SCK(SCK_b),          //in//SERIAL CLOCK FROM MASTER
    .MOSI(MOSI_b),        //in//MASTER OUT SLAVE IN
    .SSEL(SSEL_b),        //in//SLAVE/CHIP SELECT
    .MISO(MISO_b),        //out//MASTER IN SLAVE OUT
    //DATA TO/FROM DUAL PORT RAM
    .DPR_READ_DATA(spi_data_out_b),       //in//DATA FROM RAM TO WRITE TO MASTER
    .DPR_WRITE_DATA(spi_write_data_b),    //out//DATA TO WRITE TO RAM DURING WRITE OPERATION
    //CONTROL SIGNALS
    .readwritedata_complete(read_write_data_complete_b),//out   //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
    .addrcmnd_complete(addr_cmnd_set_complete_b),          //out   //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
    .SPI_CommandOut(spi_rx_command_b),                       //out   //READ/WRITE BIT IN ADDRESS AND COMMAND MESSAGE
    .SPI_AddressOut(spi_rx_addr_b)                        //out   //READ/WRITE ADDRESS IN ADDRESS AND COMMAND MESSAGE
);

//DUAL PORT RAM CONTROL INTERFACE A
DualPortRamCtrl DPRC_a(
    .clk(clk),                                                      //in
    //.reset(reset),                                                  //in
    .SPI_Slave_CommandIn(spi_rx_command_a),                              //in
    .spi_slave_addrcmnd_complete(addr_cmnd_set_complete_a),            //in
    .spi_slave_readwritedata_complete(read_write_data_complete_a),  //in
    .DPR_Enable(dprc_enable_a),                                 //out
    .DPR_WriteEnable(dprc_write_enable_a)                        //out
//    .start()                                                      //out
);

//DUAL PORT RAM CONTROL INTERFACE B
DualPortRamCtrl DPRC_b(
    .clk(clk),                                                      //in
    //.reset(reset),                                                  //in
    .SPI_Slave_CommandIn(spi_rx_command_b),                              //in
    .spi_slave_addrcmnd_complete(addr_cmnd_set_complete_b),            //in
    .spi_slave_readwritedata_complete(read_write_data_complete_b),  //in
    .DPR_Enable(dprc_enable_b),                                 //out
    .DPR_WriteEnable(dprc_write_enable_b)                        //out
//    .start()                                                      //out
);

/******MODULES******/
//MODULE 1
test_string_module 
#(
.AddrSize(StringModuleAddrSize)
)
string_module_inst1
(
    .clk(clk),               //in
    .ena(string_module1_enable_reg),          //in
    .wea(string_module1_write_enable_reg),     //in
    .spi_addr(string_module1_address_reg),           //in
    .dina(string_module1_data_in_reg),//dpr_data_in_a),             //in
    .douta(string_module1_data_out)           //out  
);

//MODULE 2
test_string_module 
#(
.AddrSize(StringModuleAddrSize)
)
string_module_inst2
(
    .clk(clk),               //in
    .ena(string_module2_enable_reg),          //in
    .wea(string_module2_write_enable_reg),     //in
    .spi_addr(string_module2_address_reg),           //in
    .dina(string_module2_data_in_reg),             //in
    .douta(string_module2_data_out)           //out  
);

//MODULE 3
test_string_module 
#(
.AddrSize(StringModuleAddrSize)
)
string_module_inst3
(
    .clk(clk),               //in
    .ena(string_module3_enable_reg),          //in
    .wea(string_module3_write_enable_reg),     //in
    .spi_addr(string_module3_address_reg),           //in
    .dina(string_module3_data_in_reg),             //in
    .douta(string_module3_data_out)           //out  
);



//SYNC SHARED REGISTERS
always @(posedge clk)
begin
    ID_reg <= PROGRAM_ID;
    VERSION_reg <= {VERSION_LARGE, VERSION_SMALL};

    //Set flat register space address
    dpr_address_a <= spi_rx_addr_a;
    dpr_address_b <= spi_rx_addr_b;
    
    dpr_enable_a <= dprc_enable_a;
    dpr_enable_b <= dprc_enable_b;
    
    dpr_write_enable_a <= dprc_write_enable_a;
    dpr_write_enable_b <= dprc_write_enable_b;
//    dpr_data_in_a <= spi_write_data_a;
//    dpr_data_in_b <= spi_write_data_b;
end

////UPDATE SHARED REGISTERS
//always @*
//begin
//    dpr_enable_a_next = dpr_enable_a;
//end


//MODULE 1 SYNC Test
//For writing from spi interface to module 1
always @(posedge clk)
begin
    //sync string module write enable
    string_module1_write_enable_reg <= string_module1_write_enable_next;
    //sync dpr enables from controller
    string_module1_enable_reg <= string_module1_enable_next;
    //Set string module address
    string_module1_address_reg <= string_module1_address_next;
    //spi data to dps control
    string_module1_data_in_reg <= string_module1_data_in_next;
end

//MODULE 2 SYNC
//For writing from spi interface to module 2
always @(posedge clk)
begin
    //sync string module write enable
    string_module2_write_enable_reg <= string_module2_write_enable_next;
    //sync dpr enables from controller
    string_module2_enable_reg <= string_module2_enable_next;    
    //Set string module address
    string_module2_address_reg <= string_module2_address_next;
    //spi data to dps control
    string_module2_data_in_reg <= string_module2_data_in_next;
end

//MODULE 3 SYNC
//For writing from spi interface to module 2
always @(posedge clk)
begin
    //sync string module write enable
    string_module3_write_enable_reg <= string_module3_write_enable_next;
    //sync dpr enables from controller
    string_module3_enable_reg <= string_module3_enable_next;    
    //Set string module address
    string_module3_address_reg <= string_module3_address_next;
    //spi data to dps control
    string_module3_data_in_reg <= string_module3_data_in_next;
end

//MODULE 1 ASYNC CONTROL
//For writing from any spi interface
always@*
begin
    string_module1_write_enable_next = 1'b0;
    string_module1_enable_next = 1'b0;
    string_module1_address_next = string_module1_address_reg;
    string_module1_data_in_next = string_module1_data_in_reg;
    
    if(dpr_enable_b)
    begin
        if(dpr_address_b >= STRING_DATA_BASE1 && dpr_address_b <= STRING_DATA_END1)
        begin
            string_module1_write_enable_next = dpr_write_enable_b;
            string_module1_enable_next = dpr_enable_b;
            string_module1_address_next = dpr_address_b - STRING_DATA_BASE1;
            string_module1_data_in_next = spi_write_data_b;
        end
    end
    else if(dpr_enable_a)
    begin
        if(dpr_address_a >= STRING_DATA_BASE1 && dpr_address_a <= STRING_DATA_END1)
        begin
            string_module1_write_enable_next = dpr_write_enable_a;
            string_module1_enable_next = dpr_enable_a;
            string_module1_address_next = dpr_address_a - STRING_DATA_BASE1;
            string_module1_data_in_next = spi_write_data_a;
        end
    end
end

//MODULE 2 ASYNC CONTROL
//For writing from any spi interface
always@*
begin
    string_module2_write_enable_next = 1'b0;
    string_module2_enable_next = 1'b0;
    string_module2_address_next = string_module2_address_reg;
    string_module2_data_in_next = string_module2_data_in_reg;
    
    if(dpr_enable_b)
    begin
        if(dpr_address_b >= STRING_DATA_BASE2 && dpr_address_b <= STRING_DATA_END2)
        begin
            string_module2_write_enable_next = dpr_write_enable_b;
            string_module2_enable_next = dpr_enable_b;
            string_module2_address_next = dpr_address_b - STRING_DATA_BASE2;
            string_module2_data_in_next = spi_write_data_b;
        end
    end
    else if(dpr_enable_a)
    begin
        if(dpr_address_a >= STRING_DATA_BASE2 && dpr_address_a <= STRING_DATA_END2)
        begin
            string_module2_write_enable_next = dpr_write_enable_a;
            string_module2_enable_next = dpr_enable_a;
            string_module2_address_next = dpr_address_a - STRING_DATA_BASE2;
            string_module2_data_in_next = spi_write_data_a;
        end
    end
end

//MODULE 3 ASYNC CONTROL
//For writing from any spi interface
always@*
begin
    string_module3_write_enable_next = 1'b0;
    string_module3_enable_next = 1'b0;
    string_module3_address_next = string_module3_address_reg;
    string_module3_data_in_next = string_module3_data_in_reg;
    
    if(dpr_enable_b)
    begin
        if(dpr_address_b >= STRING_DATA_BASE3 && dpr_address_b <= STRING_DATA_END3)
        begin
            string_module3_write_enable_next = dpr_write_enable_b;
            string_module3_enable_next = dpr_enable_b;
            string_module3_address_next = dpr_address_b;
            string_module3_data_in_next = spi_write_data_b;
        end
    end
    else if(dpr_enable_a)
    begin
        if(dpr_address_a >= STRING_DATA_BASE3 && dpr_address_a <= STRING_DATA_END3)
        begin
            string_module3_write_enable_next = dpr_write_enable_a;
            string_module3_enable_next = dpr_enable_a;
            string_module3_address_next = dpr_address_a;
            string_module3_data_in_next = spi_write_data_a;
        end
    end
end

//REGISTERS LOGIC UPDATE
//For reading out to spi interface a
always @(posedge clk)
begin
    //if address is in string module then access from within module
    if(dpr_address_a >= STRING_DATA_BASE1 && dpr_address_a <= STRING_DATA_END1)
    begin
        //Set data output from module 1
        spi_data_out_a = string_module1_data_out;
    end
    else if(dpr_address_a >= STRING_DATA_BASE2 && dpr_address_a <= STRING_DATA_END2)
    begin
        //Set data output from module 2
        spi_data_out_a = string_module2_data_out;
    end
    //if address is in config space then get config registers
    else
    begin
        casex(dpr_address_a)
            MAX_SPI_ADDR - 1 : spi_data_out_a = VERSION_reg;
            MAX_SPI_ADDR : spi_data_out_a = ID_reg;     
            default: spi_data_out_a = 16'hffff;
        endcase
    end
end

//REGISTERS LOGIC UPDATE
//For reading out to spi interface b
always @(posedge clk)
begin
    //if address is in string module then access from within module
    if(dpr_address_b >= STRING_DATA_BASE1 && dpr_address_b <= STRING_DATA_END1)
    begin
        //Set data output from module 1
        spi_data_out_b = string_module1_data_out;
    end
    else if(dpr_address_b >= STRING_DATA_BASE2 && dpr_address_b <= STRING_DATA_END2)
    begin
        //Set data output from module 2
        spi_data_out_b = string_module2_data_out;
    end
    else
    //if address is in config space then get config registers
    begin
        casex(dpr_address_b)
            MAX_SPI_ADDR - 1 : spi_data_out_b = VERSION_reg;
            MAX_SPI_ADDR : spi_data_out_b = ID_reg;     
            default: spi_data_out_b = 16'hffff;
        endcase
    end
end
    

assign MISO_a_out = MISO_a;         //CONNECT MISO OUTPUT TO MISO HOLDER
assign MISO_b_out = MISO_b;         //CONNECT MISO OUTPUT TO MISO HOLDER

endmodule
