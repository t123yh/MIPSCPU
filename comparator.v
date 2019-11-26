`include "constants.v"
module Comparator (
    input signed [31:0] A,
    input signed [31:0] B,
    input [3:0] ctrl,
    output reg action
);

always @(*) begin
    action = 0;
    case (ctrl)
        `cmpEqual:
            action = (A == B) ? 1 : 0;
        `cmpNotEqual:
            action = (A != B) ? 1 : 0;
        `cmpLessThanOrEqualToZero:
            action = (A <= 0) ? 1 : 0;
        `cmpLessThanZero:
            action = (A < 0) ? 1 : 0;
        `cmpGreaterThanOrEqualToZero:
            action = (A >= 0) ? 1 : 0;
        `cmpGreaterThanZero:
            action = (A > 0) ? 1 : 0;
    endcase
end

endmodule