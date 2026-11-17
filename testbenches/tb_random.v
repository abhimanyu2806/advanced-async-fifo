`timescale 1ns/1ps

module tb_random;

reg wr_clk, rd_clk, rst_n;
    reg wr_en, rd_en;
    reg [7:0] data_in;

wire [7:0] data_out;
    wire full, empty;
    wire almost_full, almost_empty;
    wire overflow, underflow;

    reg [7:0] expected [0:11];

integer i, j, round;
    integer errors;
    integer delay_count;

async_fifo dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .overflow(overflow),
        .underflow(underflow)
    );

// Write clock: 10 ns period
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;
    end

// Read clock: 14 ns period
    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;
    end

    initial begin

rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        errors = 0;

#30;
        rst_n = 1;

// --------------------------------
        // FOUR RANDOMIZED ROUNDS
        // --------------------------------

        for (round = 0; round < 4; round = round + 1) begin

$display("--------------------------------");
            $display("ROUND %0d STARTED", round + 1);
            $display("--------------------------------");

// --------------------------------
            // RANDOMIZED WRITE OPERATIONS
            // --------------------------------

            for (i = 0; i < 12; i = i + 1) begin

                delay_count = $random % 3;

                if (delay_count <0)
                    delay_count = -delay_count;

repeat (delay_count)
                    @(negedge wr_clk);

                @(negedge wr_clk);

data_in = $random;
                expected[i] = data_in;
                wr_en = 1;

@(negedge wr_clk);
                wr_en = 0;

            end

// Wait for synchronized write pointer
            repeat (5) @(posedge rd_clk);

// --------------------------------
            // RANDOMIZED READ OPERATIONS
            // --------------------------------

            for (j = 0; j < 12; j = j + 1) begin

                delay_count = $random % 3;

                if (delay_count <0)
                    delay_count = -delay_count;

repeat (delay_count)
                    @(negedge rd_clk);

                wait (!empty);

@(negedge rd_clk);
                rd_en = 1;

@(posedge rd_clk);
                #1;

                if (data_out !== expected[j]) begin

$display("FAIL: Expected=%h Got=%h",
                             expected[j], data_out);

                    errors = errors + 1;

end
                else begin

                    $display("PASS: Data=%h", data_out);

                end

@(negedge rd_clk);
                rd_en = 0;

            end

// Wait for empty flag update
            repeat (5) @(posedge rd_clk);

            if (!empty) begin

$display("FAIL: FIFO NOT EMPTY");
                errors = errors + 1;

end
            else begin

                $display("PASS: FIFO EMPTY");

            end

        end

// --------------------------------
        // FINAL RESULT
        // --------------------------------

if (errors == 0)
            $display("ALL RANDOM TESTS PASSED");
        else
            $display("RANDOM TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule