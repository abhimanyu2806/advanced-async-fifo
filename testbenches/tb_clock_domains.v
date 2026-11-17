`timescale 1ns/1ps

module tb_clock_domains;

    reg wr_clk, rd_clk, rst_n;
    reg wr_en, rd_en;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire full, empty;
    wire almost_full, almost_empty;
    wire overflow, underflow;

    integer i;
    integer errors;

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

        // WRITE 12 VALUES
        for (i = 0; i < 12; i = i + 1) begin

            @(negedge wr_clk);

            wr_en = 1;
            data_in = 8'hA0 + i;

        end

        @(negedge wr_clk);
        wr_en = 0;

        // Wait for synchronization
        repeat (5) @(posedge rd_clk);

        // READ 12 VALUES
        for (i = 0; i < 12; i = i + 1) begin

            wait (!empty);

            @(negedge rd_clk);
            rd_en = 1;

            @(posedge rd_clk);
            #1;

            if (data_out !== (8'hA0 + i)) begin

                $display("FAIL: Expected=%h Got=%h",
                         8'hA0+i, data_out);

                errors = errors + 1;

            end
            else begin

                $display("PASS: Data=%h", data_out);

            end

            @(negedge rd_clk);
            rd_en = 0;

        end

        repeat (4) @(posedge rd_clk);

        if (empty)
            $display("PASS: FIFO EMPTY");
        else begin
            $display("FAIL: FIFO NOT EMPTY");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("CLOCK DOMAIN TEST PASSED");
        else
            $display("CLOCK DOMAIN TEST FAILED: %0d errors", errors);

        $finish;

    end
