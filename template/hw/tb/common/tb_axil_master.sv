`default_nettype none
// Module      : tb_axil_master
// Description : Task-based AXI4-Lite master model; call write()/read() hierarchically
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
module tb_axil_master #(
    parameter int unsigned ADDR_WIDTH    = 12,
    parameter int unsigned DATA_WIDTH    = 32,
    parameter int unsigned TIMEOUT_CYCLES = 1000
) (
    input  wire logic                      clk,
    output logic [ADDR_WIDTH-1:0]          m_axil_awaddr,
    output logic                           m_axil_awvalid,
    input  wire logic                      m_axil_awready,
    output logic [DATA_WIDTH-1:0]          m_axil_wdata,
    output logic [DATA_WIDTH/8-1:0]        m_axil_wstrb,
    output logic                           m_axil_wvalid,
    input  wire logic                      m_axil_wready,
    input  wire logic [1:0]                m_axil_bresp,
    input  wire logic                      m_axil_bvalid,
    output logic                           m_axil_bready,
    output logic [ADDR_WIDTH-1:0]          m_axil_araddr,
    output logic                           m_axil_arvalid,
    input  wire logic                      m_axil_arready,
    input  wire logic [DATA_WIDTH-1:0]     m_axil_rdata,
    input  wire logic [1:0]                m_axil_rresp,
    input  wire logic                      m_axil_rvalid,
    output logic                           m_axil_rready
);
    initial begin
        m_axil_awaddr  = '0;
        m_axil_awvalid = 1'b0;
        m_axil_wdata   = '0;
        m_axil_wstrb   = '0;
        m_axil_wvalid  = 1'b0;
        m_axil_bready  = 1'b0;
        m_axil_araddr  = '0;
        m_axil_arvalid = 1'b0;
        m_axil_rready  = 1'b0;
    end

    // Address and data are presented together; each channel completes independently.
    task automatic write(input logic [ADDR_WIDTH-1:0] address, input logic [DATA_WIDTH-1:0] data,
                         output logic [1:0] response, output bit timed_out);
        bit address_done = 1'b0;
        bit data_done = 1'b0;
        int unsigned cycles = 0;
        timed_out = 1'b0;
        @(posedge clk);
        m_axil_awaddr  <= address;
        m_axil_awvalid <= 1'b1;
        m_axil_wdata   <= data;
        m_axil_wstrb   <= '1;
        m_axil_wvalid  <= 1'b1;
        while (!(address_done && data_done)) begin
            @(posedge clk);
            if (m_axil_awvalid && m_axil_awready) begin
                address_done = 1'b1;
                m_axil_awvalid <= 1'b0;
            end
            if (m_axil_wvalid && m_axil_wready) begin
                data_done = 1'b1;
                m_axil_wvalid <= 1'b0;
            end
            if (++cycles == TIMEOUT_CYCLES) begin
                timed_out = 1'b1;
                break;
            end
        end
        m_axil_awvalid <= 1'b0;
        m_axil_wvalid  <= 1'b0;
        m_axil_bready  <= 1'b1;
        cycles = 0;
        while (!timed_out) begin
            @(posedge clk);
            if (m_axil_bvalid) begin
                response = m_axil_bresp;
                break;
            end
            if (++cycles == TIMEOUT_CYCLES) timed_out = 1'b1;
        end
        m_axil_bready <= 1'b0;
    endtask

    task automatic read(input logic [ADDR_WIDTH-1:0] address, output logic [DATA_WIDTH-1:0] data,
                        output logic [1:0] response, output bit timed_out);
        int unsigned cycles = 0;
        timed_out = 1'b0;
        @(posedge clk);
        m_axil_araddr  <= address;
        m_axil_arvalid <= 1'b1;
        while (1) begin
            @(posedge clk);
            if (m_axil_arready) break;
            if (++cycles == TIMEOUT_CYCLES) begin
                timed_out = 1'b1;
                break;
            end
        end
        m_axil_arvalid <= 1'b0;
        m_axil_rready  <= 1'b1;
        cycles = 0;
        while (!timed_out) begin
            @(posedge clk);
            if (m_axil_rvalid) begin
                data = m_axil_rdata;
                response = m_axil_rresp;
                break;
            end
            if (++cycles == TIMEOUT_CYCLES) timed_out = 1'b1;
        end
        m_axil_rready <= 1'b0;
    endtask
endmodule
`default_nettype wire
