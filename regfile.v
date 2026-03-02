module regfile (
  input  wire        clk_i,
  input  wire [4:0]  rs1_i,        //read address 1 
  output wire [31:0] rdata1_o,     //read data 1
  input  wire [4:0]  rs2_i,        //read address 2 
  output wire [31:0] rdata2_o,     //read data 2

  input  wire        we_i,         //write enable
  input  wire [4:0]  rd_i,         //write address 
  input  wire [31:0] wd_i,         //write data
  input  wire [4:0]  debug_addr_i, //which register to probe for debugging, from buttons in top wrapper
  output wire [31:0] debug_data_o  //for probing register file data on 7 segment display
);

  reg [31:0] rf_q [31:0]; //32 registers

  //synchronous write logic
  always @(posedge clk_i) begin
    if (we_i && (rd_i != 5'b00000)) begin 
      rf_q[rd_i] <= wd_i;
    end
  end
   
  //combinational read logic (asynchronous read)
  //if address is 0, force 0. otherwise read from array
  assign rdata1_o     = (rs1_i == 5'b0) ? 32'd0 : rf_q[rs1_i];
  assign rdata2_o     = (rs2_i == 5'b0) ? 32'd0 : rf_q[rs2_i];
  assign debug_data_o = (debug_addr_i == 5'b00000) ? 32'd0 : rf_q[debug_addr_i]; 

endmodule