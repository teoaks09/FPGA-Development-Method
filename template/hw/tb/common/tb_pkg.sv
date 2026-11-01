`default_nettype none
// Package     : tb_pkg
// Description : Common testbench reporting: requirement-tagged checks and a single final verdict
// Requirements: none (verification infrastructure)
// Xilinx IP   : none
package tb_pkg;

    int unsigned check_count = 0;
    int unsigned error_count = 0;

    // Check one condition. requirement is the ID being verified (e.g. "UART-003").
    function automatic void tb_check(input bit condition, input string message,
                                     input string requirement = "");
        check_count++;
        if (condition) begin
            $display("[PASS] %s %s", requirement, message);
        end else begin
            error_count++;
            $display("[FAIL] %s %s (time %0t)", requirement, message, $time);
        end
    endfunction

    function automatic void tb_info(input string message);
        $display("[INFO] %s", message);
    endfunction

    // Print the single verdict line parsed by flow/sim/run_sim.sh, then stop.
    function automatic void tb_finish();
        if (error_count == 0 && check_count > 0) begin
            $display("TB_RESULT: PASS (%0d checks)", check_count);
        end else begin
            $display("TB_RESULT: FAIL (%0d errors, %0d checks)", error_count, check_count);
        end
        $finish;
    endfunction

endpackage
`default_nettype wire
