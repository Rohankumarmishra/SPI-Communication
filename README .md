# SPI-Communication

Designed SPI Master‑Slave communication in Verilog on Boolean FPGA board, enabling full‑duplex data exchange via 8‑bit shift registers and SPI clock. Used push‑buttons for reset/start and LEDs for transmission check. Achieved bi‑directional communication with edge‑triggered sampling.

---

(MASTER):
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

    reg [15:0] clk_div_counter;
    reg [2:0]  bit_counter;

    reg [7:0] m_tx_shift_reg;
    reg [7:0] m_rx_shift_reg;

    reg leading_sampling_edge;
    reg trailing_shifting_edge;

    assign mosi = m_tx_shift_reg[7];

    always @(posedge clk) begin
        if (rst) begin
            busy <= 0;
            cs_n <= 1;
            sclk <= 0;

            bit_counter <= 0;
            clk_div_counter <= 0;

            m_tx_shift_reg <= 0;
            m_rx_shift_reg <= 0;

            leading_sampling_edge <= 0;
            trailing_shifting_edge <= 0;

            data_out <= 0;

        end
        else begin

            leading_sampling_edge <= 0;
            trailing_shifting_edge <= 0;

            if (start && !busy)
            begin
                busy <= 1;
                cs_n <= 0;
                sclk <= 0;

                bit_counter <= 7;
                clk_div_counter <= 0;

                m_tx_shift_reg <= data_in;
                m_rx_shift_reg <= 0;
            end

            else if (busy)
            begin

                if (clk_div_counter == CLK_DIV-1)
                begin
                    sclk <= ~sclk;
                    clk_div_counter <= 0;

                    if (sclk == 0)
                    begin
                        leading_sampling_edge <= 1;
                    end
                    else
                    begin
                        trailing_shifting_edge <= 1;
                    end
                end
                else
                begin
                    clk_div_counter <= clk_div_counter + 1;
                end

                if (leading_sampling_edge)
                begin
                    m_rx_shift_reg <= {m_rx_shift_reg[6:0], miso};

                    if (bit_counter == 0)
                    begin
                        data_out <= {m_rx_shift_reg[6:0], miso};

                        busy <= 0;
                        cs_n <= 1;
                        sclk <= 0;
                    end
                end

                if (trailing_shifting_edge && busy)
                begin
                    m_tx_shift_reg <= {m_tx_shift_reg[6:0], 1'b0};

                    if (bit_counter > 0)
                    begin
                        bit_counter <= bit_counter - 1;
                    end
                end

            end
        end
    end

endmodule

(SLAVE)
module spislave (
    input  wire       sclk,
    input  wire       ss,
    input  wire       mosi,
    input  wire [7:0] transmit_data,

    output reg  [7:0] received_data,
    output wire       miso
);

    reg [7:0] shift_reg_in;
    reg [7:0] shift_reg_out;
    reg [2:0] bit_count;

    assign miso = shift_reg_out[7];

    always @(negedge ss)
    begin
        shift_reg_out <= transmit_data;
        shift_reg_in  <= 8'd0;
        bit_count     <= 3'd0;
    end

    always @(posedge sclk)
    begin
        if(!ss)
        begin
            shift_reg_in <= {shift_reg_in[6:0], mosi};

            if(bit_count == 3'd7)
            begin
                received_data <= {shift_reg_in[6:0], mosi};
            end
        end
    end

    always @(negedge sclk)
    begin
        if(!ss)
        begin
            shift_reg_out <= {shift_reg_out[6:0],1'b0};

            if(bit_count < 3'd7)
                bit_count <= bit_count + 1;
            else
                bit_count <= 3'd0;
        end
    end

endmodule

(TESTBENCH):
`timescale 1ns / 1ps

module tb_spi;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire busy;
    wire cs_n;
    wire sclk;
    wire mosi;
    wire miso;

    reg [7:0] slave_tx_data;
    wire [7:0] slave_rx_data;

    spim uut_master (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .start(start),

        .data_out(data_out),
        .busy(busy),
        .cs_n(cs_n),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso)
    );

    spislave uut_slave (
        .sclk(sclk),
        .ss(cs_n),
        .mosi(mosi),
        .miso(miso),

        .transmit_data(slave_tx_data),
        .received_data(slave_rx_data)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        rst = 1;
        start = 0;

        data_in = 8'b10110010;

        slave_tx_data = 8'b01110110;

        #20;
        rst = 0;

        #20;

        start = 1;

        #10;
        start = 0;

        wait(busy == 0);

        #20;

        $display("--------------------------------------");
        $display("MASTER SENT     : %b", data_in);
        $display("SLAVE RECEIVED  : %b", slave_rx_data);

        $display("");

        $display("SLAVE SENT      : %b", slave_tx_data);
        $display("MASTER RECEIVED : %b", data_out);
        $display("--------------------------------------");

        if ((slave_rx_data == data_in) &&
            (data_out == slave_tx_data))
        begin
            $display("********** TEST PASSED **********");
        end
        else
        begin
            $display("********** TEST FAILED **********");
        end

        #20;
        $finish;

    end

endmodule

Timing Diagram: https://drive.google.com/file/d/1n6-zK9nFxZzcFPs-jLZE7quDyQyVLd1j/view?usp=sharing


## 🔗 SPI Demo Video

🎥 [Watch the SPI demo video](https://drive.google.com/file/d/1yjIir6gsTuhqtL_1SDm9XiHnAzJr-hor/view?usp=sharing)

---

## 🖼️ SPI Connection Image

![SPI Connection](https://drive.google.com/uc?export=view&id=1cGYmu_vXMZvDYsQC5_s-jvg4YXZChHHf)

