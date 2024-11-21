/*
    Problem:
    https://acm.sjtu.edu.cn/OnlineJudge/problem?problem_id=1250
 
    任务：掌握组合逻辑，完成一个加法器。
*/


module GeneratePropagate4(
        input       [3:0]          a,
        input       [3:0]          b,
        output      [3:0]          g,
        output      [3:0]          p
    );
    assign g[0] = a[0] & b[0];
    assign g[1] = a[1] & b[1];
    assign g[2] = a[2] & b[2];
    assign g[3] = a[3] & b[3];

    assign p[0] = a[0] | b[0];
    assign p[1] = a[1] | b[1];
    assign p[2] = a[2] | b[2];
    assign p[3] = a[3] | b[3];
endmodule


module CarryLookaheadGenerator4(
        input       [3:0]          g,
        input       [3:0]          p,
        input                c_in,
        output      [3:1]          c
    );
    assign c[1] = g[0] | (p[0] & c_in);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_in);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_in);
endmodule

module CarryLookaheadAdder4 (
        input wire [3:0] a,
        input wire [3:0] b,
        input wire [3:0] g,
        input wire [3:0] p,
        input wire c_in,
        output wire [3:0] sum
    );
    wire [3:1] c;

    assign c[1] = g[0] | (p[0] & c_in);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_in);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_in);

    assign sum[0] = a[0] ^ b[0] ^ c_in;
    assign sum[1] = a[1] ^ b[1] ^ c[1];
    assign sum[2] = a[2] ^ b[2] ^ c[2];
    assign sum[3] = a[3] ^ b[3] ^ c[3];

endmodule

module BlockGeneratePropagate (
        input wire [3:0] g,
        input wire [3:0] p,
        output wire G,
        output wire P
    );
    assign G = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign P = p[3] & p[2] & p[1] & p[0];
endmodule

module CarryLookaheadAdder16 (
        input wire [15:0] a, // 16-bit input A
        input wire [15:0] b, // 16-bit input B
        input wire c_in,     // Carry input
        output wire [15:0] sum, // 16-bit Sum output
        output wire c_out      // Carry output
    );
    wire [3:0] sum0, sum1, sum2, sum3; // Sum outputs of the 4-bit CLAs
    wire c_out0, c_out1, c_out2, c_out3; // Carry outputs of the 4-bit CLAs
    wire [3:0] g0, p0, g1, p1, g2, p2, g3, p3; // Generate and propagate signals of the 4-bit CLAs
    wire G0, P0, G1, P1, G2, P2, G3, P3; // Block generate and propagate signals
    wire c1, c2, c3; // Carry signals between blocks

    GeneratePropagate4 gp0 (a[3:0], b[3:0], g0, p0);
    GeneratePropagate4 gp1 (a[7:4], b[7:4], g1, p1);
    GeneratePropagate4 gp2 (a[11:8], b[11:8], g2, p2);
    GeneratePropagate4 gp3 (a[15:12], b[15:12], g3, p3);


    // Block generate and propagate signals
    BlockGeneratePropagate bgp0 (g0, p0, G0, P0);
    BlockGeneratePropagate bgp1 (g1, p1, G1, P1);
    BlockGeneratePropagate bgp2 (g2, p2, G2, P2);
    BlockGeneratePropagate bgp3 (g3, p3, G3, P3);

    // Carry lookahead logic for blocks
    assign c1 = G0 | (P0 & c_in);
    assign c2 = G1 | (P1 & G0) | (P1 & P0 & c_in);
    assign c3 = G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & c_in);
    assign c_out = G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0) | (P3 & P2 & P1 & P0 & c_in);

    // Instantiate four 4-bit CLAs
    CarryLookaheadAdder4 cla0 (a[3:0], b[3:0], g0, p0, c_in, sum0);
    CarryLookaheadAdder4 cla1 (a[7:4], b[7:4], g1, p1, c1, sum1);
    CarryLookaheadAdder4 cla2 (a[11:8], b[11:8], g2, p2, c2, sum2);
    CarryLookaheadAdder4 cla3 (a[15:12], b[15:12], g3, p3, c3, sum3);

    // Combine results
    assign sum = {sum3, sum2, sum1, sum0};
endmodule

module Add(
        input       [31:0]          a,
        input       [31:0]          b,
        output reg  [31:0]          sum
    );

    wire c_mid;
    wire c_out;
    wire [15:0] sum_low, sum_high;
    CarryLookaheadAdder16 cla4 (
                              .a(a[15:0]),
                              .b(b[15:0]),
                              .c_in(1'b0),
                              .sum(sum_low),
                              .c_out(c_mid)
                          );

    CarryLookaheadAdder16 cla5 (
                              .a(a[31:16]),
                              .b(b[31:16]),
                              .c_in(c_mid),
                              .sum(sum_high),
                              .c_out(c_out)
                          );
    always @(*) begin
        sum <= {sum_high, sum_low}; // Concatenate high and low 16 bits
    end
endmodule
