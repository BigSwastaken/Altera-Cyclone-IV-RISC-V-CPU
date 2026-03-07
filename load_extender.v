module load_extender (
  input  wire [31:0] read_data_i,     //full word read from memory
  input  wire [1:0]  byte_addr_i,     //bottom 2 bits of the address to determine which byte/halfword to extract
  input  wire [2:0]  mem_size_i,      //funct3 from Control Unit (000=LB, 001=LH, 010=LW, 100=LBU, 101=LHU)
  output reg  [31:0] read_data_ext_o  //the masked and extended data going to the register file
);

  reg [7:0]  byte_data;
  reg [15:0] half_data;

  always @(*) begin
    case (byte_addr_i) //which byte to extract for LB/LBU 
      2'b00: byte_data = read_data_i[7:0];
      2'b01: byte_data = read_data_i[15:8];
      2'b10: byte_data = read_data_i[23:16];
      2'b11: byte_data = read_data_i[31:24];
    endcase

    case (byte_addr_i[1]) //which half word to extract for LH/LHU
      1'b0: half_data = read_data_i[15:0]; 
      1'b1: half_data = read_data_i[31:16];
    endcase

    case (mem_size_i) //apply sign/zero extension based on MemSize
      3'b000:  read_data_ext_o = {{24{byte_data[7]}}, byte_data};    // LB (sign-extend byte)
      3'b001:  read_data_ext_o = {{16{half_data[15]}}, half_data};   // LH  (sign-extend halfword)
      3'b010:  read_data_ext_o = read_data_i;                        // LW  (word no extension)
      3'b100:  read_data_ext_o = {24'b0, byte_data};                 // LBU (zero-extend byte)
      3'b101:  read_data_ext_o = {16'b0, half_data};                 // LHU (zero-extend halfword)
      default: read_data_ext_o = read_data_i;                        // default to full word for unknown MemSize
    endcase
  end

endmodule