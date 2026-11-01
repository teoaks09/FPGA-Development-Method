`default_nettype none
// Module      : tb_watchdog
// Description : Ends a hung simulation with TB_RESULT: FAIL after a cycle limit
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
module tb_watchdog #(
    parameter int unsigned CYCLE_LIMIT = 1_000_000
) (
    input wire logic clk
);
    int unsigned cycle_count = 0;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count == CYCLE_LIMIT) begin
            $display("[FAIL] watchdog: no completion after %0d cycles", CYCLE_LIMIT);
            $display("TB_RESULT: FAIL (watchdog)");
            $finish;
        end
    end
endmodule
`default_nettype wire
