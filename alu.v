module alu (
  input  wire [31:0] src_a_i,              //register source A or PC
  input  wire [31:0] src_b_i,              //register source B or immediate
  input  wire [3:0]  alu_control_i,        //signal from control unit to determine operation
  output reg  [31:0] alu_result_o,         //result of operation

  output wire        zero_o,               //zero flag 
  output wire        less_than_o,          //less than flag (for BLT/BGE)
  output wire        unsigned_less_than_o  //unsigned less than flag (for BLTU/BGEU)
);

  // operation encodings funct3 + modifier
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

  always @(*) begin
    case (alu_control_i)
      ALU_ADD:  alu_result_o = src_a_i + src_b_i;
      ALU_SUB:  alu_result_o = src_a_i - src_b_i;
      ALU_SLL:  alu_result_o = src_a_i << src_b_i[4:0];
      ALU_SRL:  alu_result_o = src_a_i >> src_b_i[4:0];
      ALU_SRA:  alu_result_o = $signed(src_a_i) >>> src_b_i[4:0];
      ALU_SLT:  alu_result_o = ($signed(src_a_i) < $signed(src_b_i)) ? 32'd1 : 32'd0;
      ALU_SLTU: alu_result_o = (src_a_i < src_b_i) ? 32'd1 : 32'd0;
      ALU_XOR:  alu_result_o = src_a_i ^ src_b_i;
      ALU_OR:   alu_result_o = src_a_i | src_b_i;
      ALU_AND:  alu_result_o = src_a_i & src_b_i;
      ALU_LUI:  alu_result_o = src_b_i; 
      default:  alu_result_o = 32'd0;
    endcase
  end

  assign zero_o               = (alu_result_o == 32'd0); //zero flag
  assign less_than_o          = ($signed(src_a_i) < $signed(src_b_i)); //less than flag for signed comparison 
  assign unsigned_less_than_o = (src_a_i < src_b_i); //unsigned less than flag 

endmodule