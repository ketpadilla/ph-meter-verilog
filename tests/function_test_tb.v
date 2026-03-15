// tests/function_test_tb.v
// AI-GENERATED
//
// Testbench for the function_test module (1-bit full subtractor).
//
// To run this test:
// 1. Compile: iverilog -o out/function_test_tb tests/function_test_tb.v tests/function_test.v
// 2. Simulate: vvp out/function_test_tb
// 3. View Waveform: gtkwave out/dump.vcd

`timescale 1ns / 1ps

module function_test_tb;
  // Inputs to the Device Under Test (DUT).
  reg a;
  reg b;
  reg borrow_in;

  // Outputs from the DUT.
  wire diff;
  wire borrow_out;

  // Instantiate the function_test module. [cite: 5]
  function_test dut (
    .diff(diff),
    .borrow_out(borrow_out),
    .a(a),
    .b(b),
    .borrow_in(borrow_in)
  );

  // Apply test vectors and observe simulation results. [cite: 2]
  initial begin
    // Setup console monitoring. [cite: 2]
    $display(" a b borrow_in | diff borrow_out | time");
    $monitor(" %b %b %b        | %b    %b          | %0t", 
             a, b, borrow_in, diff, borrow_out, $time);

    // Configure VCD logging for waveform analysis. [cite: 3]
    $dumpfile("out/dump.vcd");
    $dumpvars(0, function_test_tb);

    // Test Case 1: Initial state (1 - 1 - 0). [cite: 3]
    a = 1'b1; b = 1'b1; borrow_in = 1'b0;

    // Test Case 2: Maintain state. [cite: 4]
    #10 a = 1'b1;

    // Test Case 3: Subtraction requiring a borrow (0 - 1 - 0). [cite: 4]
    #10 a = 1'b0; b = 1'b1;

    // Test Case 4: Subtraction without borrow (1 - 0 - 0). [cite: 4]
    #10 a = 1'b1; b = 1'b0;

    // Test Case 5: Subtraction with active borrow_in (1 - 0 - 1). [cite: 4]
    #10 borrow_in = 1'b1;

    // End simulation. [cite: 4]
    #10 $finish;
  end

endmodule