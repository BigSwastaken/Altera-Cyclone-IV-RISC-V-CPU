module riscv_cpu (
  input  wire        clk_i,
  input  wire        rst_ni,
  output reg  [31:0] pc_o,
    
  output wire [31:0] mem_addr_o,
  output wire [31:0] write_data_o,  
  input  wire [31:0] read_data_i,   
  output wire        mem_write_o,
  output wire [2:0]  mem_size_o,

  output wire [3:0]  current_state_o,
  input  wire [4:0]  debug_addr_i,
  output wire [31:0] debug_data_o
);

  reg [31:0] ir, old_pc, a_buf, b_buf, alu_out; //buffer registers

  wire [31:0] result; //final value to write back to register file

  //PC calculation wires
  wire        pc_src;
  wire [31:0] imm_ext;
  wire [31:0] pc_plus_4       = pc_o + 32'd4;
  wire [31:0] pc_target_base  = (ir[6:0] == 7'b1100111) ? a_buf : old_pc; //JALR uses a_buf, others use old_pc
  wire [31:0] pc_target       = pc_target_base + imm_ext; //target address is base + immediate offset, base depends on instruction type
  wire [31:0] pc_next         = (pc_src) ? pc_target : pc_plus_4; //next PC value is either target or PC+4

  //control wires for buffers
  wire        pc_write, ir_write;
  wire [31:0] rdata1, rdata2, alu_raw; //raw outputs from regfile and ALU before buffering

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pc_o    <= 32'd0;
      ir      <= 32'd0;
      old_pc  <= 32'd0;
      a_buf   <= 32'd0;
      b_buf   <= 32'd0;
      alu_out <= 32'd0;
    end 
    else begin
      if (pc_write | pc_src) begin //update PC during fetch and when needed to jump/branch
        pc_o <= pc_next;
      end
      if (ir_write) begin //update IR during fetch to capture instruction from memory
        ir     <= read_data_i;
        old_pc <= pc_o; //save the PC value
      end 
      a_buf   <= rdata1;
      b_buf   <= rdata2;
      alu_out <= alu_raw;
    end
  end

  wire adr_src; 
  assign mem_addr_o   = (adr_src) ? alu_out : pc_o;    //memory address from ALUOut for store instructions, from PC for instruction fetch
  assign write_data_o = b_buf;  //memory data to write comes directly from B_buf 
  assign mem_size_o   = ir[14:12];  //funct3 to memory to determine size

  //control modules
  wire       reg_write, less_than, unsigned_less_than, zero, alu_src_b, alu_src_a;
  wire [1:0] result_src;
  wire [2:0] imm_src;
  wire [3:0] alu_control;

  control_fsm u_fsm (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .opcode_i        (ir[6:0]), 
    .pc_write_o      (pc_write),
    .ir_write_o      (ir_write),
    .reg_write_o     (reg_write),
    .mem_write_o     (mem_write_o),
    .adr_src_o       (adr_src),
    .current_state_o (current_state_o) 
  );

  control_unit u_control_unit (
    .opcode_i             (ir[6:0]),
    .funct3_i             (ir[14:12]),
    .funct7_5_i           (ir[30]),
    .zero_i               (zero),
    .less_than_i          (less_than),
    .unsigned_less_than_i (unsigned_less_than),
    .pc_src_o             (pc_src),
    .result_src_o         (result_src),
    .alu_src_b_o          (alu_src_b),
    .alu_src_a_o          (alu_src_a),
    .imm_src_o            (imm_src),
    .alu_control_o        (alu_control)
  );

  //datapath modules
  regfile u_regfile (
    .clk_i        (clk_i),
    .we_i         (reg_write & rst_ni),
    .rs1_i        (ir[19:15]), 
    .rs2_i        (ir[24:20]), 
    .rd_i         (ir[11:7]),  
    .wd_i         (result),     
    .rdata1_o     (rdata1),       
    .rdata2_o     (rdata2),       
    .debug_addr_i (debug_addr_i),
    .debug_data_o (debug_data_o)
  );

  wire [31:0] read_data_ext; //output of load extender
  load_extender u_load_extender (
    .read_data_i     (read_data_i), 
    .byte_addr_i     (alu_out[1:0]),
    .mem_size_i      (mem_size_o),
    .read_data_ext_o (read_data_ext)
  );

  sign_extend u_sign_extend (
    .instr_i   (ir[31:7]),
    .imm_src_i (imm_src),
    .imm_ext_o (imm_ext)
  );

  //execute and write back stages
  wire [31:0] src_a, src_b;
  assign src_a = (alu_src_a) ? old_pc : a_buf; 
  assign src_b = (alu_src_b) ? imm_ext : b_buf; 

  alu u_alu (
    .src_a_i              (src_a),
    .src_b_i              (src_b),
    .alu_control_i        (alu_control),
    .alu_result_o         (alu_raw), 
    .zero_o               (zero),
    .less_than_o          (less_than),
    .unsigned_less_than_o (unsigned_less_than)
  );

  //result mux
  assign result = (result_src == 2'b10) ? (old_pc + 32'd4) : 
                  (result_src == 2'b01) ? read_data_ext : alu_out;

endmodule