module spislave (
    input  wire sclk,   
    input  wire ss,     
    input  wire mosi,   
    output reg  miso,   
    output reg [7:0] received_data,
    input  wire [7:0] transmit_data 
);
    reg [7:0] shift_reg_in;  
    reg [7:0] shift_reg_out; 
    reg [3:0] bit_count;

    always @(posedge sclk or posedge ss) begin
        if (ss) begin
            shift_reg_out <= transmit_data;
            shift_reg_in <= 8'd0;
            bit_count <= 4'd0;
        end else begin
            miso <= shift_reg_out[0];
            shift_reg_out <= {1'b0, shift_reg_out[7:1]};
            shift_reg_in <= {mosi, shift_reg_in[7:1]};
            if (bit_count == 7) begin
                received_data <= {mosi, shift_reg_in[7:1]};
                bit_count <= 0;
            end else begin
                bit_count <= bit_count + 1;
            end
        end
    end
endmodule
