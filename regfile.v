module regfile (
  input  wire        clk_i,
  input  wire [4:0]  rs1_i,        //read address 1 
  output reg  [31:0] rdata1_o,     //read data 1
  input  wire [4:0]  rs2_i,        //read address 2 
  output reg  [31:0] rdata2_o,     //read data 2

  input  wire        we_i,         //write enable
  input  wire [4:0]  rd_i,         //write address 
  input  wire [31:0] wd_i,         //write data
  input  wire [4:0]  debug_addr_i, //which register to probe for debugging, from buttons in top wrapper
  output reg  [31:0] debug_data_o  //for probing register file data on 7 segment display
);

  //compiler directive to force Quartus to use M9K blocks
  reg [31:0] rf_q [31:0]; 
  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      rf_q[i] = 32'd0;
    end
  end

  //synchronous write and read logic
  always @(posedge clk_i) begin
    if (we_i && (rd_i != 5'b00000)) begin 
      rf_q[rd_i] <= wd_i;
    end

    rdata1_o     <= rf_q[rs1_i];
    rdata2_o     <= rf_q[rs2_i];
    debug_data_o <= rf_q[debug_addr_i]; 
    
  end

endmodule