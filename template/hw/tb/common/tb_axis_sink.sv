`default_nettype none
// Module      : tb_axis_sink
// Description : AXI-Stream sink with random backpressure; collects packets; call receive()
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
module tb_axis_sink #(
    parameter int unsigned DATA_BYTES      = 4,
    parameter int STALL_PERCENT   = 0   // probability (0-100) of tready low
) (
    input  wire logic                      clk,
    input  wire logic [8*DATA_BYTES-1:0]   s_axis_tdata,
    input  wire logic [DATA_BYTES-1:0]     s_axis_tkeep,
    input  wire logic                      s_axis_tlast,
    input  wire logic                      s_axis_tvalid,
    output logic                           s_axis_tready
);
    byte unsigned current[$];
    byte unsigned completed[$][$];

    initial s_axis_tready = 1'b0;

    always @(posedge clk) begin
        /* verilator lint_off UNSIGNED */
        s_axis_tready <= (int'($urandom % 100) >= STALL_PERCENT);
        /* verilator lint_on UNSIGNED */
        if (s_axis_tvalid && s_axis_tready) begin
            for (int unsigned lane = 0; lane < DATA_BYTES; lane++) begin
                if (s_axis_tkeep[lane]) current.push_back(s_axis_tdata[8*lane +: 8]);
            end
            if (s_axis_tlast) begin
                completed.push_back(current);
                current.delete();
            end
        end
    end

    // Blocks until a complete packet is available.
    task automatic receive(output byte unsigned packet[$]);
        while (completed.size() == 0) @(posedge clk);
        packet = completed.pop_front();
    endtask
endmodule
`default_nettype wire
