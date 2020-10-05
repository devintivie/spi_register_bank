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
    parameter SPIAddrSize=15
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

    //SPI interface W
    input wire SCK,             //SERIAL CLOCK FROM MASTER
    input wire MOSI,            //MASTER OUT SLAVE IN
    input wire SSEL,            //SLAVE/CHIP SELECT
    output wire MISO_out       //MASTER IN SLAVE OUT
);

//IDENTIFICATION
localparam  PROGRAM_ID = 16'h0100,      //Tells Microcontroller that this a basic spi setup        
            VERSION_LARGE = 12'd1,      //Top 12 bits of Version
            VERSION_SMALL = 4'd1;      //Bottom 4 bits of Version
reg [15:0] ID_reg, VERSION_reg;

localparam MAX_SPI_ADDR = 15'hffff;
wire MISO;          //OUTPUT HOLDER FOR MISO

//ARM
wire rx_cmnd;
wire [(SPIAddrSize-1):0] rx_addr;
reg [(SPIAddrSize-1):0] DPR_Address;
reg [15:0] DPR_DataIn;
reg DPR_Enable;
reg [0:0] DPR_WriteEnable;
wire readwritedata_complete;                 //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
wire addrcmnd_complete;                      //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
wire [15:0] spi_write_data;
wire [15:0] DPR_DataOut;
reg [15:0] SPI_DataOut;
wire DPRAC_Enable;                            
wire DPRAC_WriteEnable;  

integer i;
localparam  STRING_DATA_BASE =  12'h000,
            STRING_DATA_COUNT = 160;    
reg [15:0]  string_data_reg[0:STRING_DATA_COUNT];
reg [15:0]  string_data_next[0:STRING_DATA_COUNT];


//SPI SLAVE PI #1
SPI_slave 
#(
.MsgBitCount(MsgBitCount), 
.AddrCmndMsgSize(AddrCmndMsgSize), 
.DataMsgSize(DataMsgSize), 
.AddrSize(SPIAddrSize) 
)
spi_slave_inst(
    .clk(clk),          //in
    //.reset(reset),      //in
    //SPI SIGNALS
    .SCK(SCK),          //in//SERIAL CLOCK FROM MASTER
    .MOSI(MOSI),        //in//MASTER OUT SLAVE IN
    .SSEL(SSEL),        //in//SLAVE/CHIP SELECT
    .MISO(MISO),        //out//MASTER IN SLAVE OUT
    //DATA TO/FROM DUAL PORT RAM
    .DPR_READ_DATA(SPI_DataOut),       //in//DATA FROM RAM TO WRITE TO MASTER
    .DPR_WRITE_DATA(spi_write_data),    //out//DATA TO WRITE TO RAM DURING WRITE OPERATION
    //CONTROL SIGNALS
    .readwritedata_complete(readwritedata_complete),//out   //SUCCESSFULLY READ FROM MASTER(WRITE_DATA) OR WRITE TO MASTER(READ_DATA)
    .addrcmnd_complete(addrcmnd_complete),          //out   //ADDRESS AND COMMAND SUCCESSFULLY READ FROM MASTER
    .SPI_CommandOut(rx_cmnd),                       //out   //READ/WRITE BIT IN ADDRESS AND COMMAND MESSAGE
    .SPI_AddressOut(rx_addr)                        //out   //READ/WRITE ADDRESS IN ADDRESS AND COMMAND MESSAGE
);

//DUAL PORT RAM CONTROL PI #1
DualPortRamCtrl DPRC(
    .clk(clk),                                                      //in
    //.reset(reset),                                                  //in
    .SPI_Slave_CommandIn(rx_cmnd),                              //in
    .spi_slave_addrcmnd_complete(addrcmnd_complete),            //in
    .spi_slave_readwritedata_complete(readwritedata_complete),  //in
    .DPR_Enable(DPRAC_Enable),                                 //out
    .DPR_WriteEnable(DPRAC_WriteEnable)                        //out
//    .start()                                                      //out
);

//REGISTERS LOGIC UPDATE
always @(posedge clk)
begin
    ID_reg <= PROGRAM_ID;
    VERSION_reg <= {VERSION_LARGE, VERSION_SMALL};
    
    DPR_Address <= rx_addr;
    DPR_DataIn <= spi_write_data;
    DPR_Enable <= DPRAC_Enable;
    DPR_WriteEnable <= DPRAC_WriteEnable; 

    for(i = 0; i < STRING_DATA_COUNT; i = i + 1)
    begin
        string_data_reg[i] <= string_data_next[i];
    end
    
    casex(rx_addr)
        MAX_SPI_ADDR - 1 : SPI_DataOut = VERSION_reg;
        MAX_SPI_ADDR : SPI_DataOut = ID_reg;        

        
        STRING_DATA_BASE + 8'd0 : SPI_DataOut = string_data_reg[0];
        STRING_DATA_BASE + 8'd1 : SPI_DataOut = string_data_reg[1];
        STRING_DATA_BASE + 8'd2 : SPI_DataOut = string_data_reg[2];
        STRING_DATA_BASE + 8'd3 : SPI_DataOut = string_data_reg[3];
        STRING_DATA_BASE + 8'd4 : SPI_DataOut = string_data_reg[4];
        STRING_DATA_BASE + 8'd5 : SPI_DataOut = string_data_reg[5];
        STRING_DATA_BASE + 8'd6 : SPI_DataOut = string_data_reg[6];
        STRING_DATA_BASE + 8'd7 : SPI_DataOut = string_data_reg[7];
        STRING_DATA_BASE + 8'd8 : SPI_DataOut = string_data_reg[8];
        STRING_DATA_BASE + 8'd9 : SPI_DataOut = string_data_reg[9];
        STRING_DATA_BASE + 8'd10 : SPI_DataOut = string_data_reg[10];
        STRING_DATA_BASE + 8'd11 : SPI_DataOut = string_data_reg[11];
        STRING_DATA_BASE + 8'd12 : SPI_DataOut = string_data_reg[12];
        STRING_DATA_BASE + 8'd13 : SPI_DataOut = string_data_reg[13];
        STRING_DATA_BASE + 8'd14 : SPI_DataOut = string_data_reg[14];
        STRING_DATA_BASE + 8'd15 : SPI_DataOut = string_data_reg[15];
        STRING_DATA_BASE + 8'd16 : SPI_DataOut = string_data_reg[16];
        STRING_DATA_BASE + 8'd17 : SPI_DataOut = string_data_reg[17];
        STRING_DATA_BASE + 8'd18 : SPI_DataOut = string_data_reg[18];
        STRING_DATA_BASE + 8'd19 : SPI_DataOut = string_data_reg[19];
        STRING_DATA_BASE + 8'd20 : SPI_DataOut = string_data_reg[20];
        STRING_DATA_BASE + 8'd21 : SPI_DataOut = string_data_reg[21];
        STRING_DATA_BASE + 8'd22 : SPI_DataOut = string_data_reg[22];
        STRING_DATA_BASE + 8'd23 : SPI_DataOut = string_data_reg[23];
        STRING_DATA_BASE + 8'd24 : SPI_DataOut = string_data_reg[24];
        STRING_DATA_BASE + 8'd25 : SPI_DataOut = string_data_reg[25];
        STRING_DATA_BASE + 8'd26 : SPI_DataOut = string_data_reg[26];
        STRING_DATA_BASE + 8'd27 : SPI_DataOut = string_data_reg[27];
        STRING_DATA_BASE + 8'd28 : SPI_DataOut = string_data_reg[28];
        STRING_DATA_BASE + 8'd29 : SPI_DataOut = string_data_reg[29];
        STRING_DATA_BASE + 8'd30 : SPI_DataOut = string_data_reg[30];
        STRING_DATA_BASE + 8'd31 : SPI_DataOut = string_data_reg[31];
        STRING_DATA_BASE + 8'd32 : SPI_DataOut = string_data_reg[32];
        STRING_DATA_BASE + 8'd33 : SPI_DataOut = string_data_reg[33];
        STRING_DATA_BASE + 8'd34 : SPI_DataOut = string_data_reg[34];
        STRING_DATA_BASE + 8'd35 : SPI_DataOut = string_data_reg[35];
        STRING_DATA_BASE + 8'd36 : SPI_DataOut = string_data_reg[36];
        STRING_DATA_BASE + 8'd37 : SPI_DataOut = string_data_reg[37];
        STRING_DATA_BASE + 8'd38 : SPI_DataOut = string_data_reg[38];
        STRING_DATA_BASE + 8'd39 : SPI_DataOut = string_data_reg[39];
        STRING_DATA_BASE + 8'd40 : SPI_DataOut = string_data_reg[40];
        STRING_DATA_BASE + 8'd41 : SPI_DataOut = string_data_reg[41];
        STRING_DATA_BASE + 8'd42 : SPI_DataOut = string_data_reg[42];
        STRING_DATA_BASE + 8'd43 : SPI_DataOut = string_data_reg[43];
        STRING_DATA_BASE + 8'd44 : SPI_DataOut = string_data_reg[44];
        STRING_DATA_BASE + 8'd45 : SPI_DataOut = string_data_reg[45];
        STRING_DATA_BASE + 8'd46 : SPI_DataOut = string_data_reg[46];
        STRING_DATA_BASE + 8'd47 : SPI_DataOut = string_data_reg[47];
        STRING_DATA_BASE + 8'd48 : SPI_DataOut = string_data_reg[48];
        STRING_DATA_BASE + 8'd49 : SPI_DataOut = string_data_reg[49];
        STRING_DATA_BASE + 8'd50 : SPI_DataOut = string_data_reg[50];
        STRING_DATA_BASE + 8'd51 : SPI_DataOut = string_data_reg[51];
        STRING_DATA_BASE + 8'd52 : SPI_DataOut = string_data_reg[52];
        STRING_DATA_BASE + 8'd53 : SPI_DataOut = string_data_reg[53];
        STRING_DATA_BASE + 8'd54 : SPI_DataOut = string_data_reg[54];
        STRING_DATA_BASE + 8'd55 : SPI_DataOut = string_data_reg[55];
        STRING_DATA_BASE + 8'd56 : SPI_DataOut = string_data_reg[56];
        STRING_DATA_BASE + 8'd57 : SPI_DataOut = string_data_reg[57];
        STRING_DATA_BASE + 8'd58 : SPI_DataOut = string_data_reg[58];
        STRING_DATA_BASE + 8'd59 : SPI_DataOut = string_data_reg[59];
        STRING_DATA_BASE + 8'd60 : SPI_DataOut = string_data_reg[60];
        STRING_DATA_BASE + 8'd61 : SPI_DataOut = string_data_reg[61];
        STRING_DATA_BASE + 8'd62 : SPI_DataOut = string_data_reg[62];
        STRING_DATA_BASE + 8'd63 : SPI_DataOut = string_data_reg[63];
        STRING_DATA_BASE + 8'd64 : SPI_DataOut = string_data_reg[64];
        STRING_DATA_BASE + 8'd65 : SPI_DataOut = string_data_reg[65];
        STRING_DATA_BASE + 8'd66 : SPI_DataOut = string_data_reg[66];
        STRING_DATA_BASE + 8'd67 : SPI_DataOut = string_data_reg[67];
        STRING_DATA_BASE + 8'd68 : SPI_DataOut = string_data_reg[68];
        STRING_DATA_BASE + 8'd69 : SPI_DataOut = string_data_reg[69];
        STRING_DATA_BASE + 8'd70 : SPI_DataOut = string_data_reg[70];
        STRING_DATA_BASE + 8'd71 : SPI_DataOut = string_data_reg[71];
        STRING_DATA_BASE + 8'd72 : SPI_DataOut = string_data_reg[72];
        STRING_DATA_BASE + 8'd73 : SPI_DataOut = string_data_reg[73];
        STRING_DATA_BASE + 8'd74 : SPI_DataOut = string_data_reg[74];
        STRING_DATA_BASE + 8'd75 : SPI_DataOut = string_data_reg[75];
        STRING_DATA_BASE + 8'd76 : SPI_DataOut = string_data_reg[76];
        STRING_DATA_BASE + 8'd77 : SPI_DataOut = string_data_reg[77];
        STRING_DATA_BASE + 8'd78 : SPI_DataOut = string_data_reg[78];
        STRING_DATA_BASE + 8'd79 : SPI_DataOut = string_data_reg[79];
        STRING_DATA_BASE + 8'd80 : SPI_DataOut = string_data_reg[80];
        STRING_DATA_BASE + 8'd81 : SPI_DataOut = string_data_reg[81];
        STRING_DATA_BASE + 8'd82 : SPI_DataOut = string_data_reg[82];
        STRING_DATA_BASE + 8'd83 : SPI_DataOut = string_data_reg[83];
        STRING_DATA_BASE + 8'd84 : SPI_DataOut = string_data_reg[84];
        STRING_DATA_BASE + 8'd85 : SPI_DataOut = string_data_reg[85];
        STRING_DATA_BASE + 8'd86 : SPI_DataOut = string_data_reg[86];
        STRING_DATA_BASE + 8'd87 : SPI_DataOut = string_data_reg[87];
        STRING_DATA_BASE + 8'd88 : SPI_DataOut = string_data_reg[88];
        STRING_DATA_BASE + 8'd89 : SPI_DataOut = string_data_reg[89];
        STRING_DATA_BASE + 8'd90 : SPI_DataOut = string_data_reg[90];
        STRING_DATA_BASE + 8'd91 : SPI_DataOut = string_data_reg[91];
        STRING_DATA_BASE + 8'd92 : SPI_DataOut = string_data_reg[92];
        STRING_DATA_BASE + 8'd93 : SPI_DataOut = string_data_reg[93];
        STRING_DATA_BASE + 8'd94 : SPI_DataOut = string_data_reg[94];
        STRING_DATA_BASE + 8'd95 : SPI_DataOut = string_data_reg[95];
        STRING_DATA_BASE + 8'd96 : SPI_DataOut = string_data_reg[96];
        STRING_DATA_BASE + 8'd97 : SPI_DataOut = string_data_reg[97];
        STRING_DATA_BASE + 8'd98 : SPI_DataOut = string_data_reg[98];
        STRING_DATA_BASE + 8'd99 : SPI_DataOut = string_data_reg[99];
        STRING_DATA_BASE + 8'd100 : SPI_DataOut = string_data_reg[100];
        STRING_DATA_BASE + 8'd101 : SPI_DataOut = string_data_reg[101];
        STRING_DATA_BASE + 8'd102 : SPI_DataOut = string_data_reg[102];
        STRING_DATA_BASE + 8'd103 : SPI_DataOut = string_data_reg[103];
        STRING_DATA_BASE + 8'd104 : SPI_DataOut = string_data_reg[104];
        STRING_DATA_BASE + 8'd105 : SPI_DataOut = string_data_reg[105];
        STRING_DATA_BASE + 8'd106 : SPI_DataOut = string_data_reg[106];
        STRING_DATA_BASE + 8'd107 : SPI_DataOut = string_data_reg[107];
        STRING_DATA_BASE + 8'd108 : SPI_DataOut = string_data_reg[108];
        STRING_DATA_BASE + 8'd109 : SPI_DataOut = string_data_reg[109];
        STRING_DATA_BASE + 8'd110 : SPI_DataOut = string_data_reg[110];
        STRING_DATA_BASE + 8'd111 : SPI_DataOut = string_data_reg[111];
        STRING_DATA_BASE + 8'd112 : SPI_DataOut = string_data_reg[112];
        STRING_DATA_BASE + 8'd113 : SPI_DataOut = string_data_reg[113];
        STRING_DATA_BASE + 8'd114 : SPI_DataOut = string_data_reg[114];
        STRING_DATA_BASE + 8'd115 : SPI_DataOut = string_data_reg[115];
        STRING_DATA_BASE + 8'd116 : SPI_DataOut = string_data_reg[116];
        STRING_DATA_BASE + 8'd117 : SPI_DataOut = string_data_reg[117];
        STRING_DATA_BASE + 8'd118 : SPI_DataOut = string_data_reg[118];
        STRING_DATA_BASE + 8'd119 : SPI_DataOut = string_data_reg[119];
        STRING_DATA_BASE + 8'd120 : SPI_DataOut = string_data_reg[120];
        STRING_DATA_BASE + 8'd121 : SPI_DataOut = string_data_reg[121];
        STRING_DATA_BASE + 8'd122 : SPI_DataOut = string_data_reg[122];
        STRING_DATA_BASE + 8'd123 : SPI_DataOut = string_data_reg[123];
        STRING_DATA_BASE + 8'd124 : SPI_DataOut = string_data_reg[124];
        STRING_DATA_BASE + 8'd125 : SPI_DataOut = string_data_reg[125];
        STRING_DATA_BASE + 8'd126 : SPI_DataOut = string_data_reg[126];
        STRING_DATA_BASE + 8'd127 : SPI_DataOut = string_data_reg[127];
        STRING_DATA_BASE + 8'd128 : SPI_DataOut = string_data_reg[128];
        STRING_DATA_BASE + 8'd129 : SPI_DataOut = string_data_reg[129];
        STRING_DATA_BASE + 8'd130 : SPI_DataOut = string_data_reg[130];
        STRING_DATA_BASE + 8'd131 : SPI_DataOut = string_data_reg[131];
        STRING_DATA_BASE + 8'd132 : SPI_DataOut = string_data_reg[132];
        STRING_DATA_BASE + 8'd133 : SPI_DataOut = string_data_reg[133];
        STRING_DATA_BASE + 8'd134 : SPI_DataOut = string_data_reg[134];
        STRING_DATA_BASE + 8'd135 : SPI_DataOut = string_data_reg[135];
        STRING_DATA_BASE + 8'd136 : SPI_DataOut = string_data_reg[136];
        STRING_DATA_BASE + 8'd137 : SPI_DataOut = string_data_reg[137];
        STRING_DATA_BASE + 8'd138 : SPI_DataOut = string_data_reg[138];
        STRING_DATA_BASE + 8'd139 : SPI_DataOut = string_data_reg[139];
        STRING_DATA_BASE + 8'd140 : SPI_DataOut = string_data_reg[140];
        STRING_DATA_BASE + 8'd141 : SPI_DataOut = string_data_reg[141];
        STRING_DATA_BASE + 8'd142 : SPI_DataOut = string_data_reg[142];
        STRING_DATA_BASE + 8'd143 : SPI_DataOut = string_data_reg[143];
        STRING_DATA_BASE + 8'd144 : SPI_DataOut = string_data_reg[144];
        STRING_DATA_BASE + 8'd145 : SPI_DataOut = string_data_reg[145];
        STRING_DATA_BASE + 8'd146 : SPI_DataOut = string_data_reg[146];
        STRING_DATA_BASE + 8'd147 : SPI_DataOut = string_data_reg[147];
        STRING_DATA_BASE + 8'd148 : SPI_DataOut = string_data_reg[148];
        STRING_DATA_BASE + 8'd149 : SPI_DataOut = string_data_reg[149];
        STRING_DATA_BASE + 8'd150 : SPI_DataOut = string_data_reg[150];
        STRING_DATA_BASE + 8'd151 : SPI_DataOut = string_data_reg[151];
        STRING_DATA_BASE + 8'd152 : SPI_DataOut = string_data_reg[152];
        STRING_DATA_BASE + 8'd153 : SPI_DataOut = string_data_reg[153];
        STRING_DATA_BASE + 8'd154 : SPI_DataOut = string_data_reg[154];
        STRING_DATA_BASE + 8'd155 : SPI_DataOut = string_data_reg[155];
        STRING_DATA_BASE + 8'd156 : SPI_DataOut = string_data_reg[156];
        STRING_DATA_BASE + 8'd157 : SPI_DataOut = string_data_reg[157];
        STRING_DATA_BASE + 8'd158 : SPI_DataOut = string_data_reg[158];
        STRING_DATA_BASE + 8'd159 : SPI_DataOut = string_data_reg[159];
        
        default: SPI_DataOut = 16'hffff;
    endcase
end
    


//REGISTERS LOGIC STATE CHANGE 
always@*
begin
    for(i = 0; i < STRING_DATA_COUNT; i = i + 1)
    begin
        string_data_next[i] = string_data_reg[i];
    end    
    
    //Add Global Reset Logic?
    if(DPR_Enable && DPR_WriteEnable)
    begin
        case(DPR_Address)
           
            STRING_DATA_BASE + 8'd0 : string_data_next[0] = DPR_DataIn;
            STRING_DATA_BASE + 8'd1 : string_data_next[1] = DPR_DataIn;
            STRING_DATA_BASE + 8'd2 : string_data_next[2] = DPR_DataIn;
            STRING_DATA_BASE + 8'd3 : string_data_next[3] = DPR_DataIn;
            STRING_DATA_BASE + 8'd4 : string_data_next[4] = DPR_DataIn;
            STRING_DATA_BASE + 8'd5 : string_data_next[5] = DPR_DataIn;
            STRING_DATA_BASE + 8'd6 : string_data_next[6] = DPR_DataIn;
            STRING_DATA_BASE + 8'd7 : string_data_next[7] = DPR_DataIn;
            STRING_DATA_BASE + 8'd8 : string_data_next[8] = DPR_DataIn;
            STRING_DATA_BASE + 8'd9 : string_data_next[9] = DPR_DataIn;
            STRING_DATA_BASE + 8'd10 : string_data_next[10] = DPR_DataIn;
            STRING_DATA_BASE + 8'd11 : string_data_next[11] = DPR_DataIn;
            STRING_DATA_BASE + 8'd12 : string_data_next[12] = DPR_DataIn;
            STRING_DATA_BASE + 8'd13 : string_data_next[13] = DPR_DataIn;
            STRING_DATA_BASE + 8'd14 : string_data_next[14] = DPR_DataIn;
            STRING_DATA_BASE + 8'd15 : string_data_next[15] = DPR_DataIn;
            STRING_DATA_BASE + 8'd16 : string_data_next[16] = DPR_DataIn;
            STRING_DATA_BASE + 8'd17 : string_data_next[17] = DPR_DataIn;
            STRING_DATA_BASE + 8'd18 : string_data_next[18] = DPR_DataIn;
            STRING_DATA_BASE + 8'd19 : string_data_next[19] = DPR_DataIn;
            STRING_DATA_BASE + 8'd20 : string_data_next[20] = DPR_DataIn;
            STRING_DATA_BASE + 8'd21 : string_data_next[21] = DPR_DataIn;
            STRING_DATA_BASE + 8'd22 : string_data_next[22] = DPR_DataIn;
            STRING_DATA_BASE + 8'd23 : string_data_next[23] = DPR_DataIn;
            STRING_DATA_BASE + 8'd24 : string_data_next[24] = DPR_DataIn;
            STRING_DATA_BASE + 8'd25 : string_data_next[25] = DPR_DataIn;
            STRING_DATA_BASE + 8'd26 : string_data_next[26] = DPR_DataIn;
            STRING_DATA_BASE + 8'd27 : string_data_next[27] = DPR_DataIn;
            STRING_DATA_BASE + 8'd28 : string_data_next[28] = DPR_DataIn;
            STRING_DATA_BASE + 8'd29 : string_data_next[29] = DPR_DataIn;
            STRING_DATA_BASE + 8'd30 : string_data_next[30] = DPR_DataIn;
            STRING_DATA_BASE + 8'd31 : string_data_next[31] = DPR_DataIn;
            STRING_DATA_BASE + 8'd32 : string_data_next[32] = DPR_DataIn;
            STRING_DATA_BASE + 8'd33 : string_data_next[33] = DPR_DataIn;
            STRING_DATA_BASE + 8'd34 : string_data_next[34] = DPR_DataIn;
            STRING_DATA_BASE + 8'd35 : string_data_next[35] = DPR_DataIn;
            STRING_DATA_BASE + 8'd36 : string_data_next[36] = DPR_DataIn;
            STRING_DATA_BASE + 8'd37 : string_data_next[37] = DPR_DataIn;
            STRING_DATA_BASE + 8'd38 : string_data_next[38] = DPR_DataIn;
            STRING_DATA_BASE + 8'd39 : string_data_next[39] = DPR_DataIn;
            STRING_DATA_BASE + 8'd40 : string_data_next[40] = DPR_DataIn;
            STRING_DATA_BASE + 8'd41 : string_data_next[41] = DPR_DataIn;
            STRING_DATA_BASE + 8'd42 : string_data_next[42] = DPR_DataIn;
            STRING_DATA_BASE + 8'd43 : string_data_next[43] = DPR_DataIn;
            STRING_DATA_BASE + 8'd44 : string_data_next[44] = DPR_DataIn;
            STRING_DATA_BASE + 8'd45 : string_data_next[45] = DPR_DataIn;
            STRING_DATA_BASE + 8'd46 : string_data_next[46] = DPR_DataIn;
            STRING_DATA_BASE + 8'd47 : string_data_next[47] = DPR_DataIn;
            STRING_DATA_BASE + 8'd48 : string_data_next[48] = DPR_DataIn;
            STRING_DATA_BASE + 8'd49 : string_data_next[49] = DPR_DataIn;
            STRING_DATA_BASE + 8'd50 : string_data_next[50] = DPR_DataIn;
            STRING_DATA_BASE + 8'd51 : string_data_next[51] = DPR_DataIn;
            STRING_DATA_BASE + 8'd52 : string_data_next[52] = DPR_DataIn;
            STRING_DATA_BASE + 8'd53 : string_data_next[53] = DPR_DataIn;
            STRING_DATA_BASE + 8'd54 : string_data_next[54] = DPR_DataIn;
            STRING_DATA_BASE + 8'd55 : string_data_next[55] = DPR_DataIn;
            STRING_DATA_BASE + 8'd56 : string_data_next[56] = DPR_DataIn;
            STRING_DATA_BASE + 8'd57 : string_data_next[57] = DPR_DataIn;
            STRING_DATA_BASE + 8'd58 : string_data_next[58] = DPR_DataIn;
            STRING_DATA_BASE + 8'd59 : string_data_next[59] = DPR_DataIn;
            STRING_DATA_BASE + 8'd60 : string_data_next[60] = DPR_DataIn;
            STRING_DATA_BASE + 8'd61 : string_data_next[61] = DPR_DataIn;
            STRING_DATA_BASE + 8'd62 : string_data_next[62] = DPR_DataIn;
            STRING_DATA_BASE + 8'd63 : string_data_next[63] = DPR_DataIn;
            STRING_DATA_BASE + 8'd64 : string_data_next[64] = DPR_DataIn;
            STRING_DATA_BASE + 8'd65 : string_data_next[65] = DPR_DataIn;
            STRING_DATA_BASE + 8'd66 : string_data_next[66] = DPR_DataIn;
            STRING_DATA_BASE + 8'd67 : string_data_next[67] = DPR_DataIn;
            STRING_DATA_BASE + 8'd68 : string_data_next[68] = DPR_DataIn;
            STRING_DATA_BASE + 8'd69 : string_data_next[69] = DPR_DataIn;
            STRING_DATA_BASE + 8'd70 : string_data_next[70] = DPR_DataIn;
            STRING_DATA_BASE + 8'd71 : string_data_next[71] = DPR_DataIn;
            STRING_DATA_BASE + 8'd72 : string_data_next[72] = DPR_DataIn;
            STRING_DATA_BASE + 8'd73 : string_data_next[73] = DPR_DataIn;
            STRING_DATA_BASE + 8'd74 : string_data_next[74] = DPR_DataIn;
            STRING_DATA_BASE + 8'd75 : string_data_next[75] = DPR_DataIn;
            STRING_DATA_BASE + 8'd76 : string_data_next[76] = DPR_DataIn;
            STRING_DATA_BASE + 8'd77 : string_data_next[77] = DPR_DataIn;
            STRING_DATA_BASE + 8'd78 : string_data_next[78] = DPR_DataIn;
            STRING_DATA_BASE + 8'd79 : string_data_next[79] = DPR_DataIn;
            STRING_DATA_BASE + 8'd80 : string_data_next[80] = DPR_DataIn;
            STRING_DATA_BASE + 8'd81 : string_data_next[81] = DPR_DataIn;
            STRING_DATA_BASE + 8'd82 : string_data_next[82] = DPR_DataIn;
            STRING_DATA_BASE + 8'd83 : string_data_next[83] = DPR_DataIn;
            STRING_DATA_BASE + 8'd84 : string_data_next[84] = DPR_DataIn;
            STRING_DATA_BASE + 8'd85 : string_data_next[85] = DPR_DataIn;
            STRING_DATA_BASE + 8'd86 : string_data_next[86] = DPR_DataIn;
            STRING_DATA_BASE + 8'd87 : string_data_next[87] = DPR_DataIn;
            STRING_DATA_BASE + 8'd88 : string_data_next[88] = DPR_DataIn;
            STRING_DATA_BASE + 8'd89 : string_data_next[89] = DPR_DataIn;
            STRING_DATA_BASE + 8'd90 : string_data_next[90] = DPR_DataIn;
            STRING_DATA_BASE + 8'd91 : string_data_next[91] = DPR_DataIn;
            STRING_DATA_BASE + 8'd92 : string_data_next[92] = DPR_DataIn;
            STRING_DATA_BASE + 8'd93 : string_data_next[93] = DPR_DataIn;
            STRING_DATA_BASE + 8'd94 : string_data_next[94] = DPR_DataIn;
            STRING_DATA_BASE + 8'd95 : string_data_next[95] = DPR_DataIn;
            STRING_DATA_BASE + 8'd96 : string_data_next[96] = DPR_DataIn;
            STRING_DATA_BASE + 8'd97 : string_data_next[97] = DPR_DataIn;
            STRING_DATA_BASE + 8'd98 : string_data_next[98] = DPR_DataIn;
            STRING_DATA_BASE + 8'd99 : string_data_next[99] = DPR_DataIn;
            STRING_DATA_BASE + 8'd100 : string_data_next[100] = DPR_DataIn;
            STRING_DATA_BASE + 8'd101 : string_data_next[101] = DPR_DataIn;
            STRING_DATA_BASE + 8'd102 : string_data_next[102] = DPR_DataIn;
            STRING_DATA_BASE + 8'd103 : string_data_next[103] = DPR_DataIn;
            STRING_DATA_BASE + 8'd104 : string_data_next[104] = DPR_DataIn;
            STRING_DATA_BASE + 8'd105 : string_data_next[105] = DPR_DataIn;
            STRING_DATA_BASE + 8'd106 : string_data_next[106] = DPR_DataIn;
            STRING_DATA_BASE + 8'd107 : string_data_next[107] = DPR_DataIn;
            STRING_DATA_BASE + 8'd108 : string_data_next[108] = DPR_DataIn;
            STRING_DATA_BASE + 8'd109 : string_data_next[109] = DPR_DataIn;
            STRING_DATA_BASE + 8'd110 : string_data_next[110] = DPR_DataIn;
            STRING_DATA_BASE + 8'd111 : string_data_next[111] = DPR_DataIn;
            STRING_DATA_BASE + 8'd112 : string_data_next[112] = DPR_DataIn;
            STRING_DATA_BASE + 8'd113 : string_data_next[113] = DPR_DataIn;
            STRING_DATA_BASE + 8'd114 : string_data_next[114] = DPR_DataIn;
            STRING_DATA_BASE + 8'd115 : string_data_next[115] = DPR_DataIn;
            STRING_DATA_BASE + 8'd116 : string_data_next[116] = DPR_DataIn;
            STRING_DATA_BASE + 8'd117 : string_data_next[117] = DPR_DataIn;
            STRING_DATA_BASE + 8'd118 : string_data_next[118] = DPR_DataIn;
            STRING_DATA_BASE + 8'd119 : string_data_next[119] = DPR_DataIn;
            STRING_DATA_BASE + 8'd120 : string_data_next[120] = DPR_DataIn;
            STRING_DATA_BASE + 8'd121 : string_data_next[121] = DPR_DataIn;
            STRING_DATA_BASE + 8'd122 : string_data_next[122] = DPR_DataIn;
            STRING_DATA_BASE + 8'd123 : string_data_next[123] = DPR_DataIn;
            STRING_DATA_BASE + 8'd124 : string_data_next[124] = DPR_DataIn;
            STRING_DATA_BASE + 8'd125 : string_data_next[125] = DPR_DataIn;
            STRING_DATA_BASE + 8'd126 : string_data_next[126] = DPR_DataIn;
            STRING_DATA_BASE + 8'd127 : string_data_next[127] = DPR_DataIn;
            STRING_DATA_BASE + 8'd128 : string_data_next[128] = DPR_DataIn;
            STRING_DATA_BASE + 8'd129 : string_data_next[129] = DPR_DataIn;
            STRING_DATA_BASE + 8'd130 : string_data_next[130] = DPR_DataIn;
            STRING_DATA_BASE + 8'd131 : string_data_next[131] = DPR_DataIn;
            STRING_DATA_BASE + 8'd132 : string_data_next[132] = DPR_DataIn;
            STRING_DATA_BASE + 8'd133 : string_data_next[133] = DPR_DataIn;
            STRING_DATA_BASE + 8'd134 : string_data_next[134] = DPR_DataIn;
            STRING_DATA_BASE + 8'd135 : string_data_next[135] = DPR_DataIn;
            STRING_DATA_BASE + 8'd136 : string_data_next[136] = DPR_DataIn;
            STRING_DATA_BASE + 8'd137 : string_data_next[137] = DPR_DataIn;
            STRING_DATA_BASE + 8'd138 : string_data_next[138] = DPR_DataIn;
            STRING_DATA_BASE + 8'd139 : string_data_next[139] = DPR_DataIn;
            STRING_DATA_BASE + 8'd140 : string_data_next[140] = DPR_DataIn;
            STRING_DATA_BASE + 8'd141 : string_data_next[141] = DPR_DataIn;
            STRING_DATA_BASE + 8'd142 : string_data_next[142] = DPR_DataIn;
            STRING_DATA_BASE + 8'd143 : string_data_next[143] = DPR_DataIn;
            STRING_DATA_BASE + 8'd144 : string_data_next[144] = DPR_DataIn;
            STRING_DATA_BASE + 8'd145 : string_data_next[145] = DPR_DataIn;
            STRING_DATA_BASE + 8'd146 : string_data_next[146] = DPR_DataIn;
            STRING_DATA_BASE + 8'd147 : string_data_next[147] = DPR_DataIn;
            STRING_DATA_BASE + 8'd148 : string_data_next[148] = DPR_DataIn;
            STRING_DATA_BASE + 8'd149 : string_data_next[149] = DPR_DataIn;
            STRING_DATA_BASE + 8'd150 : string_data_next[150] = DPR_DataIn;
            STRING_DATA_BASE + 8'd151 : string_data_next[151] = DPR_DataIn;
            STRING_DATA_BASE + 8'd152 : string_data_next[152] = DPR_DataIn;
            STRING_DATA_BASE + 8'd153 : string_data_next[153] = DPR_DataIn;
            STRING_DATA_BASE + 8'd154 : string_data_next[154] = DPR_DataIn;
            STRING_DATA_BASE + 8'd155 : string_data_next[155] = DPR_DataIn;
            STRING_DATA_BASE + 8'd156 : string_data_next[156] = DPR_DataIn;
            STRING_DATA_BASE + 8'd157 : string_data_next[157] = DPR_DataIn;
            STRING_DATA_BASE + 8'd158 : string_data_next[158] = DPR_DataIn;
            STRING_DATA_BASE + 8'd159 : string_data_next[159] = DPR_DataIn;
        endcase
    end
end

assign MISO_out = MISO;         //CONNECT MISO OUTPUT TO MISO HOLDER



endmodule
