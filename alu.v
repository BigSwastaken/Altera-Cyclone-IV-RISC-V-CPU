module alu (
  input  wire [31:0] src_a_i,              //register source A or PC
  input  wire [31:0] src_b_i,              //register source B or immediate
  input  wire [3:0]  alu_control_i,        //signal from control unit to determine operation
  output reg  [31:0] alu_result_o,         //result of operation

  output wire        zero_o,               //zero flag 
  output wire        less_than_o,          //less than flag (for BLT/BGE)
  output wire        unsigned_less_than_o  //unsigned less than flag (for BLTU/BGEU)
);

  //operation encodings funct3 + modifier
  localparam [3:0] ALU_ADD  = 4'b0000, 
                   ALU_SLL  = 4'b0001, 
                   ALU_SLT  = 4'b0010, 
                   ALU_SLTU = 4'b0011, 
                   ALU_XOR  = 4'b0100, 
                   ALU_SRL  = 4'b0101, 
                   ALU_OR   = 4'b0110, 
                   ALU_AND  = 4'b0111, 
                   ALU_SUB  = 4'b1000, 
                   ALU_SRA  = 4'b1101, 
                   ALU_LUI  = 4'b1010; 

  //function to reverse bits for the universal shifter
  function [31:0] reverse_32;
    input [31:0] x;
    integer i;
    begin
      for (i = 0; i < 32; i = i + 1) begin
        reverse_32[i] = x[31 - i];
      end
    end
  endfunction

  //single 33-bit subtractor to handle subtraction and all comparisons
  wire [32:0] alu_minus_33 = {1'b0, src_a_i} - {1'b0, src_b_i};
  assign less_than_o = (src_a_i[31] ^ src_b_i[31]) ? src_a_i[31] : alu_minus_33[32]; 
  //less than flag checks sign bits first, then checks if result of subtraction is negative
  assign unsigned_less_than_o = alu_minus_33[32]; //if subtraction is negative, then A < B(unsigned)

  //universal shifter logic
  wire        is_shift_left  = (alu_control_i == ALU_SLL);
  wire        is_arith_shift = (alu_control_i == ALU_SRA);
  wire [31:0] shifter_in     = is_shift_left ? reverse_32(src_a_i) : src_a_i;
  wire [31:0] shifter        = $signed({is_arith_shift & src_a_i[31], shifter_in}) >>> src_b_i[4:0];
  wire [31:0] left_shift     = reverse_32(shifter);

  always @(*) begin
    case (alu_control_i)
      ALU_ADD:  alu_result_o = src_a_i + src_b_i;
      ALU_SUB:  alu_result_o = alu_minus_33[31:0];
      ALU_SLL:  alu_result_o = left_shift;
      ALU_SRL:  alu_result_o = shifter;
      ALU_SRA:  alu_result_o = shifter;
      ALU_SLT:  alu_result_o = {31'd0, less_than_o};
      ALU_SLTU: alu_result_o = {31'd0, unsigned_less_than_o};
      ALU_XOR:  alu_result_o = src_a_i ^ src_b_i;
      ALU_OR:   alu_result_o = src_a_i | src_b_i;
      ALU_AND:  alu_result_o = src_a_i & src_b_i;
      ALU_LUI:  alu_result_o = src_b_i; 
      default:  alu_result_o = 32'd0;
    endcase
  end

  assign zero_o = (alu_result_o == 32'd0); 

endmodule