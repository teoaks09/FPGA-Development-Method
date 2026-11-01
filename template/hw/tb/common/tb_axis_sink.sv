`default_nettype none
// Module      : tb_axis_sink
// Description : AXI-Stream sink with random backpressure; collects packets; call receive()
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
// tready is driven on the falling edge, data sampled on the rising edge (race-free in all
// simulators). Packets are kept as a flat byte queue plus lengths (no queue of queues).
/* verilator lint_off BLKSEQ */
module tb_axis_sink #(
    parameter int unsigned DATA_BYTES    = 4,
    parameter int          STALL_PERCENT = 0     // probability (0-100) of tready low
) (
    input  wire logic                      clk,
    input  wire logic [8*DATA_BYTES-1:0]   s_axis_tdata,
    input  wire logic [DATA_BYTES-1:0]     s_axis_tkeep,
    input  wire logic                      s_axis_tlast,
    input  wire logic                      s_axis_tvalid,
    output logic                           s_axis_tready
);
    byte unsigned received_bytes[$];
    int unsigned  packet_lengths[$];
    int unsigned  current_length;
    byte unsigned packet[$];      // receive() leaves the packet here

    initial begin
        s_axis_tready = 1'b0;
        current_length = 0;
    end

    always @(negedge clk) s_axis_tready = (int'($urandom % 100) >= STALL_PERCENT);

    always @(posedge clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            for (int unsigned lane = 0; lane < DATA_BYTES; lane++) begin
                if (s_axis_tkeep[lane]) begin
                    received_bytes.push_back(s_axis_tdata[8*lane +: 8]);
                    current_length = current_length + 1;
                end
            end
            if (s_axis_tlast) begin
                packet_lengths.push_back(current_length);
                current_length = 0;
            end
        end
    end

    // Blocks until a complete packet is available; result in `packet`.
    task automatic receive();
        int unsigned length;
        packet.delete();
        while (packet_lengths.size() == 0) @(posedge clk);
        length = packet_lengths.pop_front();
        repeat (length) packet.push_back(received_bytes.pop_front());
    endtask
endmodule
`default_nettype wire
