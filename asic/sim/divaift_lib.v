import "DPI-C" function int unsigned register_reference(string hierarchy);

// module taintcell_1I1O(A, Y, A_taint, Y_taint);
module taintcell_1I1O(A, A_taint, Y_taint);

    parameter int    A_SIGNED = 0;
    parameter int    A_WIDTH = 0;
    parameter int    Y_WIDTH = 0;
    parameter string TYPE = "default";
    parameter string IFT_RULE = "none";

    localparam int   INPUT_WIDTH = A_WIDTH;
    localparam int   OUTPUT_WIDTH = Y_WIDTH;

    input [A_WIDTH-1:0] A;
    input [A_WIDTH-1:0] A_taint;
    // input [Y_WIDTH-1:0] Y;
    output [Y_WIDTH-1:0] Y_taint;

    wire [INPUT_WIDTH-1:0] A_san = $isunknown(A) ? {Y_WIDTH{1'b0}} : A_SIGNED ? $signed(A) : A;
    // wire [OUTPUT_WIDTH-1:0] Y_san = $isunknown(Y) ? {Y_WIDTH{1'b0}} : Y;
    wire [INPUT_WIDTH-1:0] At_san = A_SIGNED ? $signed(A_taint) : A_taint;

    generate
        case (IFT_RULE)
            "diva", "data": begin
                case (TYPE)
                    "logic_not", "reduce_or", "reduce_bool": begin: genreducenot
                        assign Y_taint = !(~At_san & A_san) & |At_san;
                    end
                    "reduce_and": begin: genreduceand
                        assign Y_taint = &(At_san | A_san) & |At_san;
                    end
                    "reduce_xor": begin: genreducexor
                        assign Y_taint = |At_san;
                    end
                    default: begin: gendefault
                        assign Y_taint = At_san;
                    end
                endcase
            end
            default: begin: gendefault
                assign Y_taint = 0;
            end
        endcase
    endgenerate

endmodule

module taintcell_2I1O(A, B, Y, A_taint, B_taint, Y_taint);

    parameter int    A_SIGNED = 0;
    parameter int    A_WIDTH = 0;
    parameter int    B_SIGNED = 0;
    parameter int    B_WIDTH = 0;
    parameter int    Y_WIDTH = 0;
    parameter string TYPE = "default";
    parameter string IFT_RULE = "none";

    localparam int   INPUT_WIDTH = A_WIDTH > B_WIDTH ? A_WIDTH : B_WIDTH;
    localparam int   OUTPUT_WIDTH = Y_WIDTH;

    input [A_WIDTH-1:0] A;
    input [B_WIDTH-1:0] B;
    input [A_WIDTH-1:0] A_taint;
    input [B_WIDTH-1:0] B_taint;
    input [Y_WIDTH-1:0] Y;
    output [Y_WIDTH-1:0] Y_taint;

    wire [INPUT_WIDTH-1:0]  A_san = $isunknown(A) ? {Y_WIDTH{1'b0}} : A_SIGNED ? $signed(A) : A;
    wire [INPUT_WIDTH-1:0]  B_san = $isunknown(B) ? {Y_WIDTH{1'b0}} : B_SIGNED ? $signed(B) : B;
    wire [OUTPUT_WIDTH-1:0] Y_san = $isunknown(Y) ? {Y_WIDTH{1'b0}} : Y;
    wire [INPUT_WIDTH-1:0]  At_san = A_SIGNED ? $signed(A_taint) : A_taint;
    wire [INPUT_WIDTH-1:0]  Bt_san = B_SIGNED ? $signed(B_taint) : B_taint;

    int unsigned ref_id = 0;
    initial begin
        ref_id = register_reference($sformatf("%m"));
    end

    import "DPI-C" function byte unsigned xref_diff_gate_cmp(longint now, int unsigned ref_id);
    export "DPI-C" function get_gate_cmp;
    function void get_gate_cmp();
        output byte unsigned cmp;
        cmp = Y_san[0];
    endfunction

    generate
        case (IFT_RULE)
            "diva", "data": begin
                case (TYPE)
                    "and": begin: genand
                        assign Y_taint = (At_san & B_san) | (Bt_san & A_san) | (At_san & Bt_san);
                    end
                    "or": begin: genor
                        assign Y_taint = (At_san & ~B_san) | (Bt_san & ~A_san) | (At_san & Bt_san);
                    end
                    "eq", "ne", "lt", "le", "gt", "ge": begin: gencmp
                        if (IFT_RULE == "diva") begin
                            reg cmp_diff;
                            always @(*) begin
                                if (|{At_san, Bt_san}) begin
                                    cmp_diff = xref_diff_gate_cmp($time, ref_id);
                                end
                                else begin
                                    cmp_diff = 0;
                                end
                            end
                            assign Y_taint = cmp_diff;
                        end
                        else begin
                            assign Y_taint = ((A_san & ~(At_san | Bt_san)) == (B_san & ~(At_san | Bt_san))) & |{At_san, Bt_san};
                        end
                    end
                    "shl": begin: genshl
                        assign Y_taint = Bt_san ? {Y_WIDTH{1'b1}} : At_san << B_san;
                    end
                    "sshl": begin: gensshl
                        assign Y_taint = Bt_san ? {Y_WIDTH{1'b1}} : At_san <<< B_san;
                    end
                    "shr": begin: genshr
                        assign Y_taint = Bt_san ? {Y_WIDTH{1'b1}} : At_san >> B_san;
                    end
                    "sshr", "shift", "shiftx": begin: gensshr
                        assign Y_taint = Bt_san ? {Y_WIDTH{1'b1}} : At_san >>> B_san;
                    end
                    "add": begin: genadd
                        assign Y_taint = (((A_san & ~At_san) + (B_san & ~Bt_san)) ^ ((A_san | At_san) + (B_san | Bt_san))) | At_san | Bt_san;
                    end
                    "sub": begin: gensub
                        assign Y_taint = (((A_san & ~At_san) - (B_san & ~Bt_san)) ^ ((A_san | At_san) - (B_san | Bt_san))) | At_san | Bt_san;
                    end
                    default: begin: gendefault
                        assign Y_taint = {Y_WIDTH{|{At_san, Bt_san}}};
                    end
                endcase
            end
            default: begin
                assign Y_taint = 0;
            end
        endcase
    endgenerate

endmodule

// module taintcell_mux (A, B, S, Y, A_taint, B_taint, S_taint, Y_taint);
module taintcell_mux (A, B, S, A_taint, B_taint, S_taint, Y_taint);

    parameter int    WIDTH = 32'd64;
    parameter string TYPE = "mux";
    parameter string IFT_RULE = "none";

    input [WIDTH-1:0] A;
    input [WIDTH-1:0] B;
    input S;
    // input [WIDTH-1:0] Y;
    input [WIDTH-1:0] A_taint;
    input [WIDTH-1:0] B_taint;
    input S_taint;
    output reg [WIDTH-1:0] Y_taint;

    wire [WIDTH-1:0] A_san = $isunknown(A) ? {WIDTH{1'b0}} : A;
    wire [WIDTH-1:0] B_san = $isunknown(B) ? {WIDTH{1'b0}} : B;
    wire S_san = $isunknown(S) ? 0 : S;

    int unsigned ref_id = 0;
    initial begin
        ref_id = register_reference($sformatf("%m"));
    end

    import "DPI-C" function byte unsigned xref_diff_mux_sel(longint now, int unsigned ref_id);
    export "DPI-C" function get_mux_sel;
    function void get_mux_sel();
        output byte select;
        select = S_san;
    endfunction

    generate
        case (IFT_RULE)
            "diva": begin
                reg S_diff = 1;
                always @(*) begin
                    if (S_taint) begin
                        S_diff = xref_diff_mux_sel($time, ref_id);
                        Y_taint = (S_san ? B_taint : A_taint) | (S_diff ? A_san ^ B_san : 0);
                    end
                    else begin
                        Y_taint = S_san ? B_taint : A_taint;
                    end
                end
            end
            "data": begin
                always @(*) begin
                    Y_taint = S_san ? B_taint : A_taint;
                end
            end
            default: begin
                always @(*) begin
                    Y_taint = 0;
                end
            end
        endcase
    endgenerate

endmodule

module taintcell_dff (CLK, SRST, ARST, EN, D, Q, SRST_taint, ARST_taint, EN_taint, D_taint, Q_taint,
    LIVENESS_OP0, LIVENESS_OP1, LIVENESS_OP2, taint_sum, taint_hash);

    parameter CLK_POLARITY = 1'b1;
    parameter EN_POLARITY = 1'b1;
    parameter SRST_POLARITY = 1'b1;
    parameter SRST_VALUE = 0;
    parameter ARST_POLARITY = 1'b1;
    parameter ARST_VALUE = 0;

    parameter int    WIDTH = 0;
    parameter string TYPE = "dff";
    parameter string IFT_RULE = "none";
    parameter int    TAINT_SINK = 0;
    parameter string LIVENESS_TYPE = "none";
    parameter int    LIVENESS_SIZE = 0;
    parameter int    LIVENESS_IDX = 0;
    parameter int    COVERAGE_WIDTH = 0;
    parameter int    COVERAGE_ID = 0;

    input CLK, ARST, SRST, EN;
    input [WIDTH-1:0] D;
    input [WIDTH-1:0] Q;
    input SRST_taint, ARST_taint, EN_taint;
    input [WIDTH-1:0] D_taint;
    output [WIDTH-1:0] Q_taint;
    input [LIVENESS_SIZE-1:0] LIVENESS_OP0, LIVENESS_OP1, LIVENESS_OP2;
    output taint_sum;
    output [COVERAGE_WIDTH-1:0] taint_hash;

    wire pos_clk = CLK == CLK_POLARITY;
    wire pos_srst = SRST == SRST_POLARITY;
    wire pos_arst = ARST == ARST_POLARITY;
    wire pos_en = EN == EN_POLARITY;

    wire [WIDTH-1:0] D_san = $isunknown(D) ? {WIDTH{1'b0}} : D;
    wire [WIDTH-1:0] Q_san = $isunknown(Q) ? {WIDTH{1'b0}} : Q;

    reg [WIDTH-1:0] register_taint = 0;
    assign Q_taint = register_taint;
    assign taint_sum = |register_taint;
    assign taint_hash = taint_sum;

    int unsigned ref_id = 0;
    initial begin
`ifdef HASVARIANT
        ref_id = register_reference($sformatf("%m"));
`endif
    end

    final begin
        if (TAINT_SINK && (IFT_RULE == "diva")) begin
            if (register_taint) begin
                reg liveness_mask = 1;
                case (LIVENESS_TYPE)
                    "queue": begin: queuemask
                        if (LIVENESS_OP1 < LIVENESS_OP0) begin
                            liveness_mask = LIVENESS_OP1 <= LIVENESS_IDX && LIVENESS_IDX < LIVENESS_OP0;
                        end
                        else if (LIVENESS_OP0 < LIVENESS_OP1) begin
                            liveness_mask = LIVENESS_OP1 <= LIVENESS_IDX || LIVENESS_IDX < LIVENESS_OP0;
                        end
                        else begin
                            liveness_mask = LIVENESS_OP2;
                        end
                    end
                    "bitmap": begin: bitmapmask
                        liveness_mask = LIVENESS_OP0[LIVENESS_IDX];
                    end
                    "bitmap_n": begin: bitmapnmask
                        liveness_mask = ~LIVENESS_OP0[LIVENESS_IDX];
                    end
                    "cond": begin: bitmapsmask
                        liveness_mask = LIVENESS_OP0;
                    end
                    "cond_n": begin: bitmapsnmask
                        liveness_mask = ~LIVENESS_OP0;
                    end
                endcase

                if (liveness_mask) begin
                    $fwrite(Testbench.smon.live_fd, "%m\n");
                end
            end
        end
    end

    import "DPI-C" function byte unsigned xref_diff_dff_en(longint now, int unsigned ref_id);
    import "DPI-C" function byte unsigned xref_diff_dff_srst(longint now, int unsigned ref_id);
    import "DPI-C" function byte unsigned xref_diff_dff_arst(longint now, int unsigned ref_id);
    export "DPI-C" function get_dff_en;
    export "DPI-C" function get_dff_srst;
    export "DPI-C" function get_dff_arst;
    function void get_dff_en();
        output byte unsigned en;
        en = pos_en;
    endfunction
    function void get_dff_srst();
        output byte unsigned srst;
        srst = pos_arst;
    endfunction
    function void get_dff_arst();
        output byte unsigned arst;
        arst = pos_arst;
    endfunction

    generate
        case (IFT_RULE)
            "diva": begin
                reg en_diff = 1, srst_diff = 1, arst_diff = 1;
                case (TYPE)
                    "dff": begin: gendff
                        always @(posedge pos_clk) begin
                            register_taint <= D_taint;
                        end
                    end
                    "sdff": begin: gensdff
                        always @(posedge pos_clk) begin
                            if (pos_srst) begin
                                if (SRST_taint) begin
                                    srst_diff = xref_diff_dff_srst($time, ref_id);
                                    register_taint <= srst_diff ? SRST_VALUE ^ D_san : 0;
                                end
                                else begin
                                    register_taint <= 0;
                                end
                            end
                            else begin
                                if (SRST_taint) begin
                                    srst_diff = xref_diff_dff_srst($time, ref_id);
                                    register_taint <= D_taint | (srst_diff ? SRST_VALUE ^ D_san : 0);
                                end
                                else begin
                                    register_taint <= D_taint;
                                end
                            end
                        end
                    end
                    "adff": begin: genadff
                        always @(posedge pos_clk, posedge pos_arst) begin
                            if (pos_arst) begin
                                if (ARST_taint) begin
                                    arst_diff = xref_diff_dff_arst($time, ref_id);
                                    register_taint <= arst_diff ? ARST_VALUE ^ D_san : 0;
                                end
                                else begin
                                    register_taint <= 0;
                                end
                            end
                            else begin
                                if (ARST_taint) begin
                                    arst_diff = xref_diff_dff_arst($time, ref_id);
                                    register_taint <= D_taint | (arst_diff ? ARST_VALUE ^ D_san : 0);
                                end
                                else begin
                                    register_taint <= D_taint;
                                end
                            end
                        end
                    end
                    "dffe": begin: gendffe
                        always @(posedge pos_clk) begin
                            if (pos_en) begin
                                if (EN_taint) begin
                                    en_diff = xref_diff_dff_en($time, ref_id);
                                    register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                                end
                                else begin
                                    register_taint <= D_taint;
                                end
                            end
                            else begin
                                if (EN_taint) begin
                                    en_diff = xref_diff_dff_en($time, ref_id);
                                    register_taint <= register_taint | (en_diff ? D_san ^ Q_san : 0);
                                end
                            end
                        end
                    end
                    "sdffe": begin: gensdffe
                        always @(posedge pos_clk) begin
                            if (pos_srst) begin
                                if (SRST_taint) begin
                                    srst_diff = xref_diff_dff_srst($time, ref_id);
                                    register_taint <= srst_diff ? SRST_VALUE ^ D_san : 0;
                                end
                                else begin
                                    register_taint <= 0;
                                end
                            end
                            else begin
                                if (pos_en) begin
                                    if (EN_taint) begin
                                        en_diff = xref_diff_dff_en($time, ref_id);
                                        register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                                    end
                                    else begin
                                        register_taint <= D_taint;
                                    end
                                end
                                else begin
                                    if (EN_taint) begin
                                        en_diff = xref_diff_dff_en($time, ref_id);
                                        register_taint <= register_taint | (en_diff ? D_san ^ Q_san : 0);
                                    end
                                end
                            end
                        end
                    end
                    "adffe": begin: genadffe
                        always @(posedge pos_clk, posedge pos_arst) begin
                            if (pos_arst) begin
                                if (ARST_taint) begin
                                    arst_diff = xref_diff_dff_arst($time, ref_id);
                                    register_taint <= arst_diff ? ARST_VALUE ^ D_san : 0;
                                end
                                else begin
                                    register_taint <= 0;
                                end
                            end
                            else begin
                                if (pos_en) begin
                                    if (EN_taint) begin
                                        en_diff = xref_diff_dff_en($time, ref_id);
                                        register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                                    end
                                    else begin
                                        register_taint <= D_taint;
                                    end
                                end
                                else begin
                                    if (EN_taint) begin
                                        en_diff = xref_diff_dff_en($time, ref_id);
                                        register_taint <= register_taint | (en_diff ? D_san ^ Q_san : 0);
                                    end
                                end
                            end
                        end
                    end
                    "sdffce": begin: gensdffce
                        always @(posedge pos_clk) begin
                            if (pos_en) begin
                                if (pos_srst) begin
                                    if (SRST_taint) begin
                                        srst_diff = xref_diff_dff_srst($time, ref_id);
                                        register_taint <= srst_diff ? SRST_VALUE ^ D_san : 0;
                                    end
                                    else begin
                                        register_taint <= 0;
                                    end
                                end
                                else begin
                                    if (EN_taint) begin
                                        en_diff = xref_diff_dff_en($time, ref_id);
                                        register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                                    end
                                    else begin
                                        register_taint <= D_taint;
                                    end
                                end
                            end
                            else begin
                                if (EN_taint) begin
                                    en_diff = xref_diff_dff_en($time, ref_id);
                                    register_taint <= register_taint | (en_diff ? D_san ^ Q_san : 0);
                                end
                                else if (SRST_taint) begin
                                    srst_diff = xref_diff_dff_srst($time, ref_id);
                                    register_taint <= register_taint | (srst_diff ? SRST_VALUE ^ Q_san : 0);
                                end
                            end
                        end
                    end
                    default: begin: generror
                        initial $error("Unknown dff type %s at %m", TYPE);
                    end
                endcase
            end
            "data": begin
                case (TYPE)
                    "dff": begin: gendff
                        always @(posedge pos_clk) begin
                            register_taint <= D_taint;
                        end
                    end
                    "sdff": begin: gensdff
                        always @(posedge pos_clk) begin
                            register_taint <= pos_srst ? 0 : D_taint;
                        end
                    end
                    "adff": begin: genadff
                        always @(posedge pos_clk, posedge pos_arst) begin
                            register_taint <= pos_arst ? 0 : D_taint;
                        end
                    end
                    "dffe": begin: gendffe
                        always @(posedge pos_clk) begin
                            register_taint <= pos_en ? D_taint : register_taint;
                        end
                    end
                    "sdffe": begin: gensdffe
                        always @(posedge pos_clk) begin
                            register_taint <= pos_srst ? 0 : pos_en ? D_taint : register_taint;
                        end
                    end
                    "adffe": begin: genadffe
                        always @(posedge pos_clk, posedge pos_arst) begin
                            register_taint <= pos_arst ? 0 : pos_en ? D_taint : register_taint;
                        end
                    end
                    "sdffce": begin: gensdffce
                        always @(posedge pos_clk) begin
                            register_taint <= pos_en ? (pos_srst ? 0 : D_taint) : register_taint;
                        end
                    end
                    default: begin: generror
                        initial $error("Unknown dff type %s at %m", TYPE);
                    end
                endcase
            end
            default: begin
                always @(*) begin
                    register_taint <= 0;
                end
            end
        endcase

    endgenerate
endmodule

// module taintcell_mem (RD_CLK, RD_EN, RD_ARST, RD_SRST, RD_ADDR, RD_DATA, WR_CLK, WR_EN, WR_ADDR, WR_DATA,
//     RD_EN_taint, RD_ARST_taint, RD_SRST_taint, RD_ADDR_taint, RD_DATA_taint, WR_EN_taint, WR_ADDR_taint, WR_DATA_taint, taint_sum);
module taintcell_mem (RD_CLK, RD_EN, RD_ARST, RD_SRST, RD_ADDR, WR_CLK, WR_EN, WR_ADDR,
    RD_EN_taint, RD_ARST_taint, RD_SRST_taint, RD_ADDR_taint, RD_DATA_taint, WR_EN_taint, WR_ADDR_taint, WR_DATA_taint,
    LIVENESS_OP0, LIVENESS_OP1, LIVENESS_OP2, taint_sum);

    parameter RD_CLK_ENABLE = 1'b1;
    parameter RD_CLK_POLARITY = 1'b1;
    parameter RD_TRANSPARENCY_MASK = 1'b0;
    parameter RD_COLLISION_X_MASK = 1'b0;
    parameter RD_CE_OVER_SRST = 1'b0;
    parameter RD_ARST_VALUE = 1'b0;
    parameter RD_SRST_VALUE = 1'b0;
    parameter WR_CLK_ENABLE = 1'b1;
    parameter WR_CLK_POLARITY = 1'b1;
    parameter WR_PRIORITY_MASK = 1'b0;
    parameter WR_WIDE_CONTINUATION = 1'b0;

    parameter string MEMID = "";
    parameter string IFT_RULE = "none";
    parameter int    SIZE = 4;
    parameter int    OFFSET = 0;
    parameter int    ABITS = 2;
    parameter int    WIDTH = 8;
    parameter int    RD_PORTS = 1;
    parameter int    WR_PORTS = 1;
    parameter int    TAINT_SINK = 0;
    parameter string LIVENESS_TYPE = "none";

    localparam int   EXT_SIZE = $pow(2, $clog2(SIZE));

    input [RD_PORTS-1:0] RD_CLK;
    input [RD_PORTS-1:0] RD_EN;
    input [RD_PORTS-1:0] RD_EN_taint;
    input [RD_PORTS-1:0] RD_ARST;
    input [RD_PORTS-1:0] RD_ARST_taint;
    input [RD_PORTS-1:0] RD_SRST;
    input [RD_PORTS-1:0] RD_SRST_taint;
    input [RD_PORTS*ABITS-1:0] RD_ADDR;
    input [RD_PORTS*ABITS-1:0] RD_ADDR_taint;
    // input [RD_PORTS*WIDTH-1:0] RD_DATA;
    output [RD_PORTS*WIDTH-1:0] RD_DATA_taint;

    reg [RD_PORTS*WIDTH-1:0] memory_rd_taint;
    assign RD_DATA_taint = memory_rd_taint;

    input [WR_PORTS-1:0] WR_CLK;
    input [WR_PORTS*WIDTH-1:0] WR_EN;
    input [WR_PORTS*WIDTH-1:0] WR_EN_taint;
    input [WR_PORTS*ABITS-1:0] WR_ADDR;
    input [WR_PORTS*ABITS-1:0] WR_ADDR_taint;
    // input [WR_PORTS*WIDTH-1:0] WR_DATA;
    input [WR_PORTS*WIDTH-1:0] WR_DATA_taint;

    input [SIZE-1:0] LIVENESS_OP0, LIVENESS_OP1, LIVENESS_OP2;
    output reg [ABITS:0] taint_sum = 0;

    int i, j;
    wire pos_rd_clk = RD_CLK[0] == RD_CLK_POLARITY[0];
    wire pos_wt_clk = WR_CLK[0] == WR_CLK_POLARITY[0];

    int unsigned ref_id;
    reg [WIDTH-1:0] memory_taint [EXT_SIZE-1:0];
    bit bitmap[bit [31:0]];
  
    initial begin
        // if (EXT_SIZE != SIZE) begin
        //     $display("Unmatched memory size %d/%d for %m", SIZE, EXT_SIZE);
        // end
        if (RD_PORTS > 8) begin
            $error("Too many read ports %d for %m", RD_PORTS);
        end
        if (WR_PORTS > 16) begin
            $error("Too many write ports %d for %m", WR_PORTS);
        end
        if (ABITS > 32) begin
            $error("Too deep memory 2^%d for %m", ABITS);
        end

        ref_id = register_reference($sformatf("%m"));

        for (i = 0; i < EXT_SIZE; i = i+1)
            memory_taint[i] = 0;
    end

    final begin
        reg [ABITS:0] liveness_sum = 0;
        for (i = 0; i < SIZE; i = i+1) begin
            if (memory_taint[i] && (IFT_RULE == "diva")) begin
                reg liveness_mask = 1;
                case (LIVENESS_TYPE)
                    "queue": begin: queuemask
                        if (LIVENESS_OP1 < LIVENESS_OP0) begin
                            liveness_mask = LIVENESS_OP1 <= i && i < LIVENESS_OP0;
                        end
                        else if (LIVENESS_OP0 < LIVENESS_OP1) begin
                            liveness_mask = LIVENESS_OP1 <= i || i < LIVENESS_OP0;
                        end
                        else begin
                            liveness_mask = LIVENESS_OP2;
                        end
                    end
                    "bitmap": begin: bitmapmask
                        liveness_mask = LIVENESS_OP0[i];
                    end
                    "bitmap_n": begin: bitmapnmask
                        liveness_mask = ~LIVENESS_OP0[i];
                    end
                    "cond": begin: bitmapsmask
                        liveness_mask = LIVENESS_OP0;
                    end
                    "cond_n": begin: bitmapsnmask
                        liveness_mask = ~LIVENESS_OP0;
                    end
                endcase
                liveness_sum = liveness_sum + liveness_mask;
            end
        end

        if (liveness_sum) begin
            $fwrite(Testbench.smon.live_fd, "%m: %d\n", liveness_sum);
        end
    end

    final begin
        // $display("[%d] %m", bitmap.size());
        if ((bitmap.size() > 0) && (IFT_RULE == "diva")) begin
            $fwrite(Testbench.smon.cov_fd, "%m:");
            foreach(bitmap[hash])
                $fwrite(Testbench.smon.cov_fd, " %h", hash);
            $fwrite(Testbench.smon.cov_fd, "\n");
        end
    end


    import "DPI-C" function byte unsigned xref_diff_mem_rd_en(longint now, int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_wt_en(longint now, int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_rd_srst(longint now, int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_rd_arst(longint now, int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_rd_addr(longint now, int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_wt_addr(longint now, int unsigned ref_id, int unsigned index);
    export "DPI-C" function get_mem_rd_en;
    export "DPI-C" function get_mem_wt_en;
    export "DPI-C" function get_mem_rd_srst;
    export "DPI-C" function get_mem_rd_arst;
    export "DPI-C" function get_mem_rd_addr;
    export "DPI-C" function get_mem_wt_addr;
    function void get_mem_rd_en();
        input int unsigned index;
        output byte unsigned en;
        en = RD_EN[index];
    endfunction
    function void get_mem_wt_en();
        input int unsigned index;
        output byte unsigned en;
        en = |WR_EN[index*WIDTH +: WIDTH];
    endfunction
    function void get_mem_rd_srst();
        input int unsigned index;
        output byte unsigned srst;
        srst = RD_SRST[index];
    endfunction
    function void get_mem_rd_arst();
        input int unsigned index;
        output byte unsigned arst;
        arst = RD_ARST[index];
    endfunction
    function void get_mem_rd_addr();
        input int unsigned index;
        output int unsigned addr;
        addr = RD_ADDR[index*ABITS +: ABITS];
    endfunction
    function void get_mem_wt_addr();
        input int unsigned index;
        output int unsigned addr;
        addr = WR_ADDR[index*ABITS +: ABITS];
    endfunction

    reg previous_taint, current_taint;

    generate
        case (IFT_RULE)
            "diva": begin
                reg wt_en_diff = 1, wt_addr_diff = 1;
                reg rd_en_diff = 1, rd_srst_diff = 1, rd_arst_diff = 1, rd_addr_diff = 1;
                if (RD_CLK_ENABLE == 0) begin: async_read
                    always @(*) begin
                        for (i = 0; i < RD_PORTS; i = i+1) begin
                            if (RD_ARST[i]) begin
                                if (RD_ARST_taint[i]) begin
                                    rd_arst_diff = xref_diff_mem_rd_arst($time, ref_id, i);
                                    memory_rd_taint[i*WIDTH +: WIDTH] = rd_arst_diff ? {WIDTH{1'b1}} : 0;
                                end
                                else begin
                                    memory_rd_taint[i*WIDTH +: WIDTH] = 0;
                                end
                            end
                            else begin
                                rd_addr_diff = xref_diff_mem_rd_addr($time, ref_id, i);
                                if (RD_ARST_taint[i]) begin
                                    rd_arst_diff = xref_diff_mem_rd_arst($time, ref_id, i);
                                    memory_rd_taint[i*WIDTH +: WIDTH] = memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{rd_addr_diff}} |
                                        rd_arst_diff ? {WIDTH{1'b1}} : 0;
                                end
                                else begin
                                    memory_rd_taint[i*WIDTH +: WIDTH] = memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{rd_addr_diff}};
                                end
                            end
                        end
                    end
                end
                else if (&RD_CLK_ENABLE != 1) begin: mix_read
                    initial $fatal("Mixed read ports are not supported: %s at %m", MEMID);
                end
                else begin: sync_read
                    if (|RD_TRANSPARENCY_MASK | |RD_COLLISION_X_MASK)
                        initial $fatal("Transparency and collision masks are not supported: %s at %m", MEMID);
                    if (|RD_CLK_POLARITY && !&RD_CLK_POLARITY)
                        initial $fatal("Mixed read clock polarities are not supported: %s at %m", MEMID);
                    always @(posedge pos_rd_clk) begin
                        for (i = 0; i < RD_PORTS; i = i+1) begin
                            if (RD_CE_OVER_SRST[i]) begin
                                if (RD_EN[i]) begin
                                    if (RD_SRST[i]) begin
                                        if (RD_SRST_taint[i]) begin
                                            rd_srst_diff = xref_diff_mem_rd_srst($time, ref_id, i);
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= rd_srst_diff ? {WIDTH{1'b1}} : 0;
                                        end
                                        else begin
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= 0;
                                        end
                                    end
                                    else begin
                                        rd_addr_diff = xref_diff_mem_rd_addr($time, ref_id, i);
                                        if (RD_EN_taint[i]) begin
                                            rd_en_diff = xref_diff_mem_rd_en($time, ref_id, i);
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{rd_addr_diff}} |
                                                rd_en_diff ? {WIDTH{1'b1}} : 0;
                                        end
                                        else begin
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{rd_addr_diff}};
                                        end
                                    end
                                end
                                else begin
                                    if (RD_EN_taint[i]) begin
                                        rd_en_diff = xref_diff_mem_rd_en($time, ref_id, i);
                                        memory_rd_taint[i*WIDTH +: WIDTH] <= rd_en_diff ? {WIDTH{1'b1}} : 0;
                                    end
                                    else if (RD_SRST_taint[i]) begin
                                        rd_srst_diff = xref_diff_mem_rd_srst($time, ref_id, i);
                                        memory_rd_taint[i*WIDTH +: WIDTH] <= rd_srst_diff ? {WIDTH{1'b1}} : 0;
                                    end
                                    else begin
                                        memory_rd_taint[i*WIDTH +: WIDTH] <= 0;
                                    end
                                end
                            end
                            else begin
                                if (RD_SRST[i]) begin
                                    if (RD_SRST_taint[i]) begin
                                        rd_srst_diff = xref_diff_mem_rd_srst($time, ref_id, i);
                                        memory_rd_taint[i*WIDTH +: WIDTH] <= rd_srst_diff ? {WIDTH{1'b1}} : 0;
                                    end
                                    else begin
                                        memory_rd_taint[i*WIDTH +: WIDTH] <= 0;
                                    end
                                end
                                else begin
                                    if (RD_EN[i]) begin
                                        rd_addr_diff = xref_diff_mem_rd_addr($time, ref_id, i);
                                        if (RD_EN_taint[i]) begin
                                            rd_en_diff = xref_diff_mem_rd_en($time, ref_id, i);
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{rd_addr_diff}} |
                                                rd_en_diff ? {WIDTH{1'b1}} : 0;
                                        end
                                        else begin
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{rd_addr_diff}};
                                        end
                                    end
                                    else begin
                                        if (RD_EN_taint[i]) begin
                                            rd_en_diff = xref_diff_mem_rd_en($time, ref_id, i);
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= rd_en_diff ? {WIDTH{1'b1}} : 0;
                                        end
                                        else begin
                                            memory_rd_taint[i*WIDTH +: WIDTH] <= 0;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if (WR_CLK_ENABLE == 0) begin: async_write
                    always @(*) begin
                        for (i = 0; i < WR_PORTS; i = i+1) begin
                            previous_taint = |memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];
                            if (WR_EN[i*WIDTH +: WIDTH]) begin
                                wt_addr_diff = xref_diff_mem_wt_addr($time, ref_id, i);
                                if (WR_EN_taint[i*WIDTH +: WIDTH]) begin
                                    wt_en_diff = xref_diff_mem_wt_en($time, ref_id, i);
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = (memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] & ~WR_EN[i*WIDTH +: WIDTH]) |
                                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]) | {WIDTH{wt_addr_diff}} |
                                        wt_en_diff ? {WIDTH{1'b1}} : 0;
                                end
                                else begin
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = (memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] & ~WR_EN[i*WIDTH +: WIDTH]) |
                                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]) | {WIDTH{wt_addr_diff}};
                                end
                            end
                            else begin
                                if (WR_EN_taint[i*WIDTH +: WIDTH]) begin
                                    wt_en_diff = xref_diff_mem_wt_en($time, ref_id, i);
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] |
                                        wt_en_diff ? {WIDTH{1'b1}} : 0;
                                end
                            end
                            current_taint = |memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];

                            if (previous_taint ^ current_taint) begin
                                if (current_taint)
                                    taint_sum = taint_sum + 1;
                                else
                                    taint_sum = taint_sum - 1;

                                bitmap[taint_sum] = 1;
                            end
                        end
                    end
                end
                else if (&WR_CLK_ENABLE != 1) begin: mix_write
                    initial $fatal("Mixed write ports are not supported: %s at %m", MEMID);
                end
                else begin: sync_write
                    if (|WR_CLK_POLARITY && !&WR_CLK_POLARITY)
                        initial $fatal("Mixed write clock polarities are not supported: %s at %m", MEMID);
                    always @(posedge pos_wt_clk) begin
                        for (i = 0; i < WR_PORTS; i = i+1) begin
                            previous_taint = |memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];
                            if (WR_EN[i*WIDTH +: WIDTH]) begin
                                wt_addr_diff = xref_diff_mem_wt_addr($time, ref_id, i);
                                if (WR_EN_taint[i*WIDTH +: WIDTH]) begin
                                    wt_en_diff = xref_diff_mem_wt_en($time, ref_id, i);
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = (memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] & ~WR_EN[i*WIDTH +: WIDTH]) |
                                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]) | {WIDTH{wt_addr_diff}} |
                                        wt_en_diff ? (WR_EN[i*WIDTH +: WIDTH] & WR_EN_taint[i*WIDTH +: WIDTH]) : 0;
                                end
                                else begin
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = (memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] & ~WR_EN[i*WIDTH +: WIDTH]) |
                                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]) | {WIDTH{wt_addr_diff}};
                                end
                            end
                            else begin
                                if (WR_EN_taint[i*WIDTH +: WIDTH]) begin
                                    wt_en_diff = xref_diff_mem_wt_en($time, ref_id, i);
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] |
                                        wt_en_diff ? {WIDTH{1'b1}} : 0;
                                end
                            end
                            current_taint = |memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];

                            if (previous_taint ^ current_taint) begin
                                if (current_taint)
                                    taint_sum = taint_sum + 1;
                                else
                                    taint_sum = taint_sum - 1;

                                bitmap[taint_sum] = 1;
                            end
                        end
                    end
                end
            end
            "data": begin
                if (RD_CLK_ENABLE == 0) begin: async_read
                    always @(*) begin
                        for (i = 0; i < RD_PORTS; i = i+1) begin
                            memory_rd_taint[i*WIDTH +: WIDTH] = RD_ARST[i] ? 0 : memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET];
                        end
                    end
                end
                else if (&RD_CLK_ENABLE != 1) begin: mix_read
                    initial $fatal("Mixed read ports are not supported: %s at %m", MEMID);
                end
                else begin: sync_read
                    if (|RD_TRANSPARENCY_MASK | |RD_COLLISION_X_MASK)
                        initial $fatal("Transparency and collision masks are not supported: %s at %m", MEMID);
                    if (|RD_CLK_POLARITY && !&RD_CLK_POLARITY)
                        initial $fatal("Mixed read clock polarities are not supported: %s at %m", MEMID);
                    always @(posedge pos_rd_clk) begin
                        for (i = 0; i < RD_PORTS; i = i+1) begin
                            if (RD_CE_OVER_SRST[i]) begin
                                memory_rd_taint[i*WIDTH +: WIDTH] = RD_EN[i] ? (RD_SRST[i] ? 0 : memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET]) : 0;
                            end
                            else begin
                                memory_rd_taint[i*WIDTH +: WIDTH] = RD_SRST[i] ? 0 : RD_EN[i] ? memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] : 0;
                            end
                        end
                    end
                end

                if (WR_CLK_ENABLE == 0) begin: async_write
                    always @(*) begin
                        for (i = 0; i < WR_PORTS; i = i+1) begin
                            if (WR_EN[i*WIDTH +: WIDTH]) begin
                                memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = (memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] & ~WR_EN[i*WIDTH +: WIDTH]) |
                                    (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]);
                            end
                        end
                    end
                end
                else if (&WR_CLK_ENABLE != 1) begin: mix_write
                    initial $fatal("Mixed write ports are not supported: %s at %m", MEMID);
                end
                else begin: sync_write
                    if (|WR_CLK_POLARITY && !&WR_CLK_POLARITY)
                        initial $fatal("Mixed write clock polarities are not supported: %s at %m", MEMID);
                    always @(posedge pos_wt_clk) begin
                        for (i = 0; i < WR_PORTS; i = i+1) begin
                            if (WR_EN[i*WIDTH +: WIDTH]) begin
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = (memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] & ~WR_EN[i*WIDTH +: WIDTH]) |
                                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]);
                            end
                        end
                    end
                end
            end
            default: begin
                always @(*) begin
                    memory_rd_taint[i*WIDTH +: WIDTH] = 0;
                end
            end
        endcase
    endgenerate
endmodule

module tainthelp_coverage (COV_HASH);

    parameter signed COVERAGE_WIDTH = 0;
    parameter string IFT_RULE = "none";
    input [COVERAGE_WIDTH-1:0] COV_HASH;

    bit bitmap[bit [COVERAGE_WIDTH-1:0]];

    generate
        case (IFT_RULE)
            "diva": begin
                always @(posedge Testbench.clock) begin
                    if (COV_HASH)
                        bitmap[COV_HASH] = 1;
                end
            end
        endcase
    endgenerate

    final begin
        // $display("[%d] %m", bitmap.size());
        if ((bitmap.size() > 0) && (IFT_RULE == "diva")) begin
            $fwrite(Testbench.smon.cov_fd, "%m:");
            foreach(bitmap[hash])
                $fwrite(Testbench.smon.cov_fd, " %h", hash);
            $fwrite(Testbench.smon.cov_fd, "\n");
        end
    end

endmodule
