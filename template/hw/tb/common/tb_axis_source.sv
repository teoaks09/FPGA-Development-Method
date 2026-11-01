`default_nettype none
// Module      : tb_axis_source
// Description : AXI-Stream packet source with optional random valid gaps; call send()
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
module tb_axis_source #(
    parameter int unsigned DATA_BYTES   = 4,
    parameter int GAP_PERCENT  = 0      // probability (0-100) of an idle cycle
) (
    input  wire logic                      clk,
    output logic [8*DATA_BYTES-1:0]        m_axis_tdata,
    output logic [DATA_BYTES-1:0]          m_axis_tkeep,
    output logic                           m_axis_tlast,
    output logic                           m_axis_tvalid,
    input  wire logic                      m_axis_tready
);
    initial begin
        m_axis_tdata  = '0;
        m_axis_tkeep  = '0;
        m_axis_tlast  = 1'b0;
        m_axis_tvalid = 1'b0;
    end

    task automatic send(input byte unsigned packet[$]);
        int unsigned index = 0;
        int unsigned total = packet.size();
        while (index < total) begin
            @(posedge clk);
            if (m_axis_tvalid && !m_axis_tready) continue;   // hold until accepted
            /* verilator lint_off UNSIGNED */
            if (int'($urandom % 100) < GAP_PERCENT) begin
            /* verilator lint_on UNSIGNED */
                m_axis_tvalid <= 1'b0;
                continue;
            end
            for (int unsigned lane = 0; lane < DATA_BYTES; lane++) begin
                m_axis_tdata[8*lane +: 8] <= (index + lane < total) ? packet[index + lane] : 8'h00;
                m_axis_tkeep[lane]        <= (index + lane < total);
            end
            m_axis_tlast  <= (index + DATA_BYTES >= total);
            m_axis_tvalid <= 1'b1;
            index += DATA_BYTES;
        end
        do @(posedge clk); while (!m_axis_tready);
        m_axis_tvalid <= 1'b0;
        m_axis_tlast  <= 1'b0;
    endtask
endmodule
`default_nettype wire
