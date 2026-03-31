module kogge32 (
    input  [31:0] A,
    input  [31:0] B,
    input         Cin,
    output [31:0] Sum,
    output        Cout
);

    wire [31:0] G [0:5];
    wire [31:0] P [0:5];
    wire [32:0] C;

    assign C[0] = Cin;
    assign G[0] = A & B;
    assign P[0] = A ^ B;

    genvar i, j;
    generate
        for (i = 1; i <= 5; i = i + 1) begin : stage
            for (j = 0; j < 32; j = j + 1) begin : prefix
                if (j < (1 << (i - 1))) begin : passthru
                    assign G[i][j] = G[i-1][j];
                    assign P[i][j] = P[i-1][j];
                end else begin : combine
                    assign G[i][j] = G[i-1][j] | (P[i-1][j] & G[i-1][j - (1 << (i - 1))]);
                    assign P[i][j] = P[i-1][j] & P[i-1][j - (1 << (i - 1))];
                end
            end
        end
    endgenerate

    generate
        for (j = 0; j < 32; j = j + 1) begin : carry
            assign C[j+1] = G[5][j] | (P[5][j] & C[0]);
        end
    endgenerate

    assign Sum  = P[0] ^ C[31:0];
    assign Cout = C[32];
endmodule

module ksa (
    input  [31:0] A,
    input  [31:0] B,
    input  [31:0] C,
    output [31:0] Sum,
    output        Cout
);
    wire [31:0] t_sum;
    wire        t_cout;

    kogge32 add_bc (
        .A(B),
        .B(C),
        .Cin(1'b0),
        .Sum(t_sum),
        .Cout(t_cout)
    );

    kogge32 add_at (
        .A(A),
        .B(t_sum),
        .Cin(1'b0),
        .Sum(Sum),
        .Cout(Cout)
    );
endmodule


module two_bit_pp_gen (
    input  signed [15:0] a,
    input  signed [15:0] b,
    output reg signed [31:0] pp0,
    output reg signed [31:0] pp1,
    output reg signed [31:0] pp2,
    output reg signed [31:0] pp3,
    output reg signed [31:0] pp4,
    output reg signed [31:0] pp5,
    output reg signed [31:0] pp6,
    output reg signed [31:0] pp7
);
    reg signed [31:0] temp;
    reg [2:0] bits;
    reg [16:0] b_ext; 
    always @(*) begin
        b_ext = {b, 1'b0}; 

        // PP0
        bits = b_ext[2:0];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp0 = temp <<< 0;

        // PP1
        bits = b_ext[4:2];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp1 = temp <<< 2;

        // PP2
        bits = b_ext[6:4];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp2 = temp <<< 4;

        // PP3
        bits = b_ext[8:6];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp3 = temp <<< 6;

        // PP4
        bits = b_ext[10:8];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp4 = temp <<< 8;

        // PP5
        bits = b_ext[12:10];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp5 = temp <<< 10;

        // PP6
        bits = b_ext[14:12];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp6 = temp <<< 12;

        // PP7
        bits = b_ext[16:14];
        case (bits)
            3'b000, 3'b111: temp = 0;
            3'b001, 3'b010: temp = a;
            3'b011: temp = a <<< 1;
            3'b100: temp = -(a <<< 1);
            3'b101, 3'b110: temp = -a;
            default: temp = 0;
        endcase
        pp7 = temp <<< 14;
    end
endmodule


module booth_dadda_multiplier (
    input  clk,
    input  rst,
    input  signed [15:0] a,
    input  signed [15:0] b,
    output reg signed [31:0] y
);

    wire signed [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;

    wire [31:0] s1 [0:2];
    
    wire c1 [0:2];

    wire [31:0] s2 [0:1];
    wire c2 [0:1];

    wire [31:0] s3;
    wire c3;

    wire [31:0] final_sum;
    wire [31:0] final_carry;

    two_bit_pp_gen gen (
        .a(a), .b(b),
        .pp0(pp0), .pp1(pp1), .pp2(pp2), .pp3(pp3),
        .pp4(pp4), .pp5(pp5), .pp6(pp6), .pp7(pp7)
    );

    ksa csa1 (
        .A(pp0),
        .B(pp1),
        .C(pp2),
        .Sum(s1[0]),
        .Cout(c1[0])
    );

    ksa csa2 (
        .A(pp3),
        .B(pp4),
        .C(pp5),
        .Sum(s1[1]),
        .Cout(c1[1])
    );

    ksa csa3 (
        .A(pp6),
        .B(pp7),
        .C(32'd0),
        .Sum(s1[2]),
        .Cout(c1[2])
    );

    ksa csa4 (
        .A(s1[0]),
        .B(s1[1]),
        .C(s1[2]),
        .Sum(s2[0]),
        .Cout(c2[0])
    );

    ksa csa5 (
        .A({31'd0, c1[0]} << 1),
        .B({31'd0, c1[1]} << 1),
        .C({31'd0, c1[2]} << 1),
        .Sum(s2[1]),
        .Cout(c2[1])
    );

    ksa csa6 (
        .A(s2[0]),
        .B(s2[1]),
        .C({31'd0, c2[0]} << 1),
        .Sum(s3),
        .Cout(c3)
    );

    assign final_sum = s3;

    assign final_carry = ({31'd0, c3} << 1) + ({31'd0, c2[1]} << 2);

    always @(posedge clk or posedge rst) begin
        if (rst)
            y <= 0;
        else
            y <= {final_carry,final_sum};
    end
endmodule



module multiplier_tb;
    reg clk, rst;
    reg signed [15:0] a, b;
    wire signed [31:0] y;

    booth_dadda_multiplier uut (.clk(clk), .rst(rst), .a(a), .b(b), .y(y));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        rst = 1; a = 0; b = 0;
        #12 rst = 0;  

        @(posedge clk);

        // TEST 1
        a = 4; b = 5;
        @(posedge clk); @(posedge clk);
        $display("a=%0d b=%0d -> y=%0d", a, b, y);

        // TEST 2
        a = 520; b = 284;
        @(posedge clk); @(posedge clk);
        $display("a=%0d b=%0d -> y=%0d", a, b, y);

        // TEST 3
        a = 25; b = -16784;
        @(posedge clk); @(posedge clk);
        $display("a=%0d b=%0d -> y=%0d", a, b, y);

        // TEST 4
        a = -12; b = 21;
        @(posedge clk); @(posedge clk);
        $display("a=%0d b=%0d -> y=%0d", a, b, y);

        // TEST 5
        a = -25; b = 26;
        @(posedge clk); @(posedge clk);
        $display("a=%0d b=%0d -> y=%0d", a, b, y);

        // TEST 6
        a = -25457; b = 16220;
        @(posedge clk); @(posedge clk);
        $display("a=%0d b=%0d -> y=%0d", a, b, y);

        #50;
        $finish;
    end
endmodule