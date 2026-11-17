`timescale 1ns/1ps

module synchronizer #(
    parameter WIDTH = 5
)
(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_stage1;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= {WIDTH{1'b0}};
            sync_stage2 <= {WIDTH{1'b0}};
        end
        else begin
            sync_stage1 <= data_in;
            sync_stage2 <= sync_stage1;
        end
    end

    assign data_out = sync_stage2;

endmodule