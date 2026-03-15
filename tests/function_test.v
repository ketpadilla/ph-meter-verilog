// tests/function_test.v
// AI-GENERATED
//
// Implementation of a 1-bit full subtractor using behavioral Verilog.

module function_test(
    output diff,
    output borrow_out,
    input a,
    input b,
    input borrow_in
);
  // The subtraction result is mapped to two bits:
  // The MSB represents the borrow_out and the LSB represents the diff.
  assign {borrow_out, diff} = a - b - borrow_in;

endmodule