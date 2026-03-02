module seven_seg_controller (
  input  wire        clk_i,
  input  wire [15:0] display_data_i, //lower 16 bits of register data to display
  output reg  [3:0]  seg_sel_o,      //4 digit select pins
  output reg  [7:0]  seg_data_o      //8 segment data pins (including decimal point)
);

  reg [17:0] refresh_counter_q = 18'b0; //18 bits to create a refresh rate of 190Hz(4 digits) with 50MHz clock
  always @(posedge clk_i) begin //refresh counter increments every clock cycle
    refresh_counter_q <= refresh_counter_q + 18'b1;
  end

  wire [1:0] current_digit;
  assign current_digit = refresh_counter_q[17:16];

  //digit selection
  reg  [3:0] current_hex;

  always @(*) begin
    case (current_digit)
      2'b00: begin
        seg_sel_o   = 4'b1110; //activate digit 0 (Rightmost)
        current_hex = display_data_i[3:0];
      end
      2'b01: begin
        seg_sel_o   = 4'b1101; //activate digit 1
        current_hex = display_data_i[7:4];
      end
      2'b10: begin
        seg_sel_o   = 4'b1011; //activate digit 2
        current_hex = display_data_i[11:8];
      end
      2'b11: begin
        seg_sel_o   = 4'b0111; //activate digit 3 (Leftmost)
        current_hex = display_data_i[15:12];
      end
      default: begin
        seg_sel_o   = 4'b1111; //default to all digits off
        current_hex = 4'b0000;
      end
    endcase
  end
  //decode the selected hex nibble into physical segment states
  wire [6:0] decoded_seg;

  seven_seg_hex decoder (
    .hex_i (current_hex),
    .seg_o (decoded_seg)
  );
  //route to the physical pins
  always @(*) begin
    seg_data_o = {1'b1, decoded_seg[6:0]};  //decimal point is off, followed by segments g to a
  end

endmodule