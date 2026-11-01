`default_nettype none
// Module      : tb_axis_source
// Description : AXI-Stream packet source with optional random valid gaps; call send()
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
// Drives on the falling edge and samples the handshake on the rising edge, so there are no
// races in xsim, Verilator or iverilog. No break/continue and no queue arguments (iverilog).
module tb_axis_source #(
    parameter int unsigned DATA_BYTES  = 4,
    parameter int          GAP_PERCENT = 0       // probability (0-100) of an idle cycle
) (
    input  wire logic                      clk,
    output logic [8*DATA_BYTES-1:0]        m_axis_tdata,
    output logic [DATA_BYTES-1:0]          m_axis_tkeep,
    output logic                           m_axis_tlast,
    output logic                           m_axis_tvalid,
    input  wire logic                      m_axis_tready
);
    byte unsigned packet[$];   // fill with push_back, then call send()

    initial begin
        m_axis_tdata  = '0;
        m_axis_tkeep  = '0;
        m_axis_tlast  = 1'b0;
        m_axis_tvalid = 1'b0;
    end

    task automatic send();
        int unsigned index;
        int unsigned total;
        bit accepted;
        index = 0;
        total = packet.size();
        while (index < total) begin
            @(negedge clk);
            if (int'($urandom % 100) < GAP_PERCENT) begin
                m_axis_tvalid = 1'b0;
                @(posedge clk);
            end else begin
                for (int unsigned lane = 0; lane < DATA_BYTES; lane++) begin
                    m_axis_tdata[8*lane +: 8] = (index + lane < total) ? packet[index + lane] : 8'h00;
                    m_axis_tkeep[lane]        = (index + lane < total);
                end
                m_axis_tlast  = (index + DATA_BYTES >= total);
                m_axis_tvalid = 1'b1;
                accepted = 1'b0;
                while (!accepted) begin
                    @(posedge clk);
                    accepted = m_axis_tready;
                end
                index = index + DATA_BYTES;
            end
        end
        @(negedge clk);
        m_axis_tvalid = 1'b0;
        m_axis_tlast  = 1'b0;
        packet.delete();
    endtask
endmodule
`default_nettype wire
