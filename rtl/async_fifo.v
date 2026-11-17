`timescale 1ns/1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter ALMOST_FULL_THRESHOLD = 14,
    parameter ALMOST_EMPTY_THRESHOLD = 2
)
(
    input wire wr_clk,
    input wire rd_clk,
    input wire rst_n,

    input wire wr_en,
    input wire rd_en,

    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out,

    output reg full,
    output reg empty,

    output wire almost_full,
    output wire almost_empty,

    output reg overflow,
    output reg underflow
);

    // ------------------------------------------------
    // 1. FIFO PARAMETERS
    // ------------------------------------------------

    localparam FIFO_DEPTH = (1 << ADDR_WIDTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;


    // ------------------------------------------------
    // 2. BINARY POINTERS
    // ------------------------------------------------

    reg [PTR_WIDTH-1:0] wr_bin;
    reg [PTR_WIDTH-1:0] rd_bin;


    // ------------------------------------------------
    // 3. GRAY-CODE POINTERS
    // ------------------------------------------------

    reg [PTR_WIDTH-1:0] wr_gray;
    reg [PTR_WIDTH-1:0] rd_gray;


    // ------------------------------------------------
    // 4. NEXT POINTER VALUES
    // ------------------------------------------------

    wire [PTR_WIDTH-1:0] wr_bin_next;
    wire [PTR_WIDTH-1:0] rd_bin_next;

    wire [PTR_WIDTH-1:0] wr_gray_next;
    wire [PTR_WIDTH-1:0] rd_gray_next;


    // ------------------------------------------------
    // 5. SYNCHRONIZED POINTERS
    // ------------------------------------------------

    wire [PTR_WIDTH-1:0] rd_gray_sync;
    wire [PTR_WIDTH-1:0] wr_gray_sync;

    wire [PTR_WIDTH-1:0] rd_bin_sync;
    wire [PTR_WIDTH-1:0] wr_bin_sync;


    // ------------------------------------------------
    // 6. FIFO CONTROL SIGNALS
    // ------------------------------------------------

    wire wr_accept;
    wire rd_accept;

    wire wr_mem_en;
    wire rd_mem_en;

    wire full_next;
    wire empty_next;


    // ------------------------------------------------
    // 7. OCCUPANCY CALCULATIONS
    // ------------------------------------------------

    wire [PTR_WIDTH-1:0] wr_occupancy;
    wire [PTR_WIDTH-1:0] rd_occupancy;


    // ------------------------------------------------
    // 8. ACCEPT VALID READ/WRITE OPERATIONS
    // ------------------------------------------------

    assign wr_accept = wr_en && !full;
    assign rd_accept = rd_en && !empty;

    assign wr_mem_en = wr_accept;
    assign rd_mem_en = rd_accept;


    // ------------------------------------------------
    // 9. BINARY POINTER INCREMENT
    // ------------------------------------------------

    assign wr_bin_next = wr_bin + wr_accept;
    assign rd_bin_next = rd_bin + rd_accept;


    // ------------------------------------------------
    // 10. BINARY TO GRAY CONVERSION
    // ------------------------------------------------

    assign wr_gray_next =
        (wr_bin_next >> 1) ^ wr_bin_next;

    assign rd_gray_next =
        (rd_bin_next >> 1) ^ rd_bin_next;


    // ------------------------------------------------
    // 11. WRITE POINTER UPDATE
    // ------------------------------------------------

    always @(posedge wr_clk or negedge rst_n) begin

        if (!rst_n) begin
            wr_bin  <= 0;
            wr_gray <= 0;
        end

        else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end

    end


    // ------------------------------------------------
    // 12. READ POINTER UPDATE
    // ------------------------------------------------

    always @(posedge rd_clk or negedge rst_n) begin

        if (!rst_n) begin
            rd_bin  <= 0;
            rd_gray <= 0;
        end

        else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end

    end


    // ------------------------------------------------
    // 13. READ POINTER SYNCHRONIZER
    // ------------------------------------------------

    synchronizer #(
        .WIDTH(PTR_WIDTH)
    ) sync_read_ptr (

        .clk(wr_clk),
        .rst_n(rst_n),

        .data_in(rd_gray),
        .data_out(rd_gray_sync)

    );


    // ------------------------------------------------
    // 14. WRITE POINTER SYNCHRONIZER
    // ------------------------------------------------

    synchronizer #(
        .WIDTH(PTR_WIDTH)
    ) sync_write_ptr (

        .clk(rd_clk),
        .rst_n(rst_n),

        .data_in(wr_gray),
        .data_out(wr_gray_sync)

    );


    // ------------------------------------------------
    // 15. FULL DETECTION
    // ------------------------------------------------

    assign full_next =
        (wr_gray_next ==
        {
            ~rd_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2],
             rd_gray_sync[PTR_WIDTH-3:0]
        });


    // Register full flag in write clock domain

    always @(posedge wr_clk or negedge rst_n) begin

        if (!rst_n)
            full <= 1'b0;

        else
            full <= full_next;

    end


    // ------------------------------------------------
    // 16. EMPTY DETECTION
    // ------------------------------------------------

    assign empty_next =
        (rd_gray_next == wr_gray_sync);


    // Register empty flag in read clock domain

    always @(posedge rd_clk or negedge rst_n) begin

        if (!rst_n)
            empty <= 1'b1;

        else
            empty <= empty_next;

    end


    // ------------------------------------------------
    // 17. GRAY TO BINARY CONVERSION
    // ------------------------------------------------

    function [PTR_WIDTH-1:0] gray_to_binary;

        input [PTR_WIDTH-1:0] gray;

        integer i;

        begin

            gray_to_binary[PTR_WIDTH-1] =
                gray[PTR_WIDTH-1];

            for (i = PTR_WIDTH-2; i >= 0; i = i-1) begin

                gray_to_binary[i] =
                    gray_to_binary[i+1] ^ gray[i];

            end

        end

    endfunction


    // Convert synchronized Gray pointers

    assign rd_bin_sync = gray_to_binary(rd_gray_sync);
    assign wr_bin_sync = gray_to_binary(wr_gray_sync);


    // ------------------------------------------------
    // 18. FIFO OCCUPANCY ESTIMATION
    // ------------------------------------------------

    assign wr_occupancy = wr_bin - rd_bin_sync;
    assign rd_occupancy = wr_bin_sync - rd_bin;


    // ------------------------------------------------
    // 19. ALMOST FULL DETECTION
    // ------------------------------------------------

    assign almost_full =
        (wr_occupancy >= ALMOST_FULL_THRESHOLD);


    // ------------------------------------------------
    // 20. ALMOST EMPTY DETECTION
    // ------------------------------------------------

    assign almost_empty =
        (rd_occupancy <= ALMOST_EMPTY_THRESHOLD);


    // ------------------------------------------------
    // 21. FIFO MEMORY
    // ------------------------------------------------

    fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory_inst (

        .wr_clk(wr_clk),
        .rd_clk(rd_clk),

        .wr_en(wr_mem_en),
        .rd_en(rd_mem_en),

        .wr_addr(wr_bin[ADDR_WIDTH-1:0]),
        .rd_addr(rd_bin[ADDR_WIDTH-1:0]),

        .data_in(data_in),
        .data_out(data_out)

    );


    // ------------------------------------------------
    // 22. OVERFLOW DETECTION
    // ------------------------------------------------

    always @(posedge wr_clk or negedge rst_n) begin

        if (!rst_n)
            overflow <= 1'b0;

        else
            overflow <= wr_en && full;

    end


    // ------------------------------------------------
    // 23. UNDERFLOW DETECTION
    // ------------------------------------------------

    always @(posedge rd_clk or negedge rst_n) begin

        if (!rst_n)
            underflow <= 1'b0;

        else
            underflow <= rd_en && empty;

    end


    // ------------------------------------------------
    // 24. PARAMETER VALIDATION
    // ------------------------------------------------

    initial begin

        if (ADDR_WIDTH < 2)
            $error("ADDR_WIDTH must be at least 2");

        if (ALMOST_FULL_THRESHOLD > FIFO_DEPTH)
            $error("ALMOST_FULL_THRESHOLD exceeds FIFO depth");

        if (ALMOST_EMPTY_THRESHOLD > FIFO_DEPTH)
            $error("ALMOST_EMPTY_THRESHOLD exceeds FIFO depth");

    end

endmodule