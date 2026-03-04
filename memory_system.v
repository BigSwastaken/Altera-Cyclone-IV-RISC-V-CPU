module memory_system (
  input  wire        clk_i, 
  input  wire [31:0] addr_i, 
  input  wire [31:0] wdata_i,
  input  wire        we_i,    
  input  wire [2:0]  mem_size_i, 
  output wire [31:0] rdata_o    
);

  reg [3:0]  write_mask;
  reg [31:0] aligned_wdata;

  //write mask and alignment generation
  always @(*) begin
    case (mem_size_i)
      3'b000: begin //SB 
        write_mask    = 4'b0001 << addr_i[1:0];
        aligned_wdata = {4{wdata_i[7:0]}}; 
      end
      3'b001: begin //SH 
        write_mask    = 4'b0011 << {addr_i[1], 1'b0};
        aligned_wdata = {2{wdata_i[15:0]}};
      end
      default: begin //SW 
        write_mask    = 4'b1111; 
        aligned_wdata = wdata_i;
      end
    endcase
  end

  wire [3:0] byte_we = {4{we_i}} & write_mask; //generate byte enables based on mem_size and we_i

  //direct silicon primitive for Altera M9K RAM block
  altsyncram #(
    .operation_mode("SINGLE_PORT"),
    .width_a(32),
    .widthad_a(8),
    .numwords_a(256),
    .outdata_reg_a("UNREGISTERED"),
    .width_byteena_a(4),
    .init_file("program.mif"), //can replace with [program file name].hex if using intel hex format
    .ram_block_type("AUTO")
  ) m9k_block (
    .clock0    (clk_i),
    .address_a (addr_i[9:2]),
    .data_a    (aligned_wdata),
    .wren_a    (we_i),
    .byteena_a (byte_we),
    .q_a       (rdata_o)
  );

endmodule