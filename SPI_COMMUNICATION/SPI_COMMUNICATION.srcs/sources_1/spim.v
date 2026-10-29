`timescale 1ns / 1ps
module spim (
    input  wire        clk,        
    input  wire        rst,        
    input  wire [7:0]  data_in,   
    input  wire        start,      
    output reg  [7:0]  data_out,   
    output reg         busy,      
    output reg         cs_n,      
    output reg         sclk,     
    output wire        mosi,      
    input  wire        miso      
);
    parameter CLK_DIV = 4;
    
    reg [15:0] clk_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] r_TX_Byte;
    reg [7:0] r_RX_Byte;
    reg r_Leading_Edge;
    reg r_Trailing_Edge;

   
    assign mosi = r_TX_Byte[7]; 
    
    always @(posedge clk) begin
        if (rst) begin
            busy <= 0;
            cs_n <= 1;
            sclk <= 0;
            bit_cnt <= 0;
            clk_cnt <= 0;
            r_TX_Byte <= 0;
            r_RX_Byte <= 0;
            r_Leading_Edge <= 0;
            r_Trailing_Edge <= 0;
            data_out <= 0;
        end else begin
            r_Leading_Edge <= 0;
            r_Trailing_Edge <= 0;

            if (start && !busy) begin             
                busy <= 1;
                cs_n <= 0;
                sclk <= 0;
                bit_cnt <= 7;
                r_TX_Byte <= data_in;
                r_RX_Byte <= 0;
                clk_cnt <= 0;
            end else if (busy) begin              
                if (clk_cnt == CLK_DIV-1) begin
                    sclk <= ~sclk;
                    clk_cnt <= 0;
                    if (sclk == 0) begin                      
                        r_Leading_Edge <= 1;
                    end else begin                       
                        r_Trailing_Edge <= 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end               
                if (r_Leading_Edge) begin
                    r_RX_Byte <= {r_RX_Byte[6:0], miso};
                    if (bit_cnt == 0) begin                       
                        data_out <= {r_RX_Byte[6:0], miso};
                        busy <= 0;
                        cs_n <= 1;
                        sclk <= 0;
                    end
                end
                if (r_Trailing_Edge && busy) begin
                    r_TX_Byte <= {r_TX_Byte[6:0], 1'b0};
                    if (bit_cnt > 0) begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end
        end
    end
endmodule
