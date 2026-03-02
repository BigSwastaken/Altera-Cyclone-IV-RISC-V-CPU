module top_wrapper (
  input  wire       clk_i,       // board clock 
  input  wire       rst_ni,      // reset button (active low)
  input  wire [3:0] key_i,       // buttons on board
  output wire [7:0] led_o,       // 8 LEDs on board
  output wire [3:0] seg_sel_o,   // 4-digit select
  output wire [7:0] seg_data_o   // 7-segment data pins
);

  //button debouncer, manual clock, and display register selector
  reg [19:0] debounce_cnt_q    = 20'b0;
  reg        key0_clean_q      = 1'b1; 
  reg        key1_clean_q      = 1'b1;
  reg        key2_clean_q      = 1'b1;
  reg [4:0]  display_reg_sel_q = 5'b0; //default to x0 (always 0)
  
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      debounce_cnt_q    <= 20'b0;
      key0_clean_q      <= 1'b1; 
      key1_clean_q      <= 1'b1;
      key2_clean_q      <= 1'b1;
      display_reg_sel_q <= 5'b0; 
    end else begin
      debounce_cnt_q <= debounce_cnt_q + 20'b1;
      if (debounce_cnt_q == 20'b0) begin
        if (key1_clean_q == 1'b1 && key_i[1] == 1'b0) begin
          display_reg_sel_q <= display_reg_sel_q - 5'b1;
        end else if (key2_clean_q == 1'b1 && key_i[2] == 1'b0) begin
          display_reg_sel_q <= display_reg_sel_q + 5'b1;
        end
        key0_clean_q <= key_i[0];
        key1_clean_q <= key_i[1];
        key2_clean_q <= key_i[2];
      end
    end
  end

  wire clk_manual = ~key0_clean_q; //one button press = one clock cycle

  //connections between CPU, memory, and display
  wire [31:0] pc, mem_addr, write_data, read_data, debug_data;
  wire        mem_write;
  wire [2:0]  mem_size;
  wire [3:0]  fsm_state;  //fsm state for led debugging

  riscv_cpu u_cpu (
    .clk_i           (clk_i),//(clk_manual), manual clock from debounced button can be replaced with clk_i 
    .rst_ni          (rst_ni),
    .pc_o            (pc),
    .mem_addr_o      (mem_addr), 
    .write_data_o    (write_data),
    .read_data_i     (read_data), 
    .mem_write_o     (mem_write),
    .mem_size_o      (mem_size),
    .current_state_o (fsm_state), 
    .debug_addr_i    (display_reg_sel_q), 
    .debug_data_o    (debug_data) 
  );

  memory_system u_mem (
    .clk_i      (clk_i),//(clk_manual),
    .addr_i     (mem_addr), 
    .wdata_i    (write_data),
    .we_i       (mem_write),
    .mem_size_i (mem_size), 
    .rdata_o    (read_data)
  );

  seven_seg_controller display (
    .clk_i          (clk_i),
    .display_data_i (debug_data[15:0]), //the bottom 16 bits of the register to display
    .seg_sel_o      (seg_sel_o),
    .seg_data_o     (seg_data_o)
  );

  //FSM state on the right 4 LEDs, bottom of PC on the left 4 LEDs
  assign led_o[3:0] = ~fsm_state; 
  assign led_o[7:4] = ~pc[5:2];   

endmodule