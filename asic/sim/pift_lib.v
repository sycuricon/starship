module taintcell_1I1O(A, Y, A_taint, Y_taint);

    parameter A_SIGNED = 0;
    parameter A_WIDTH = 0;
    parameter TYPE = "default";
    parameter Y_WIDTH = 0;

    input [A_WIDTH-1:0] A;
    input [A_WIDTH-1:0] A_taint;
    input [Y_WIDTH-1:0] Y;
    output [Y_WIDTH-1:0] Y_taint;

    wire [Y_WIDTH-1:0] A_san = $isunknown(A) ? {Y_WIDTH{1'b0}} : A_SIGNED ? $signed(A) : A;
    wire [Y_WIDTH-1:0] Y_san = $isunknown(Y) ? {Y_WIDTH{1'b0}} : Y;
    wire [Y_WIDTH-1:0] At_san = A_SIGNED ? $signed(A_taint) : A_taint;

    generate
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
    endgenerate

endmodule

module taintcell_2I1O(A, B, Y, A_taint, B_taint, Y_taint);

    parameter A_SIGNED = 0;
    parameter A_WIDTH = 0;
    parameter B_SIGNED = 0;
    parameter B_WIDTH = 0;
    parameter TYPE = "default";
    parameter Y_WIDTH = 0;

    input [A_WIDTH-1:0] A;
    input [B_WIDTH-1:0] B;
    input [A_WIDTH-1:0] A_taint;
    input [B_WIDTH-1:0] B_taint;
    input [Y_WIDTH-1:0] Y;
    output [Y_WIDTH-1:0] Y_taint;

    wire [Y_WIDTH-1:0] A_san = $isunknown(A) ? {Y_WIDTH{1'b0}} : A_SIGNED ? $signed(A) : A;
    wire [Y_WIDTH-1:0] B_san = $isunknown(B) ? {Y_WIDTH{1'b0}} : B_SIGNED ? $signed(B) : B;
    wire [Y_WIDTH-1:0] Y_san = $isunknown(Y) ? {Y_WIDTH{1'b0}} : Y;
    wire [Y_WIDTH-1:0] At_san = A_SIGNED ? $signed(A_taint) : A_taint;
    wire [Y_WIDTH-1:0] Bt_san = B_SIGNED ? $signed(B_taint) : B_taint;

    generate
        case (TYPE)
            "and": begin: genand
                // assign Y_taint = (At_san & B_san) | (Bt_san & A_san);
                assign Y_taint = (At_san & B_san) | (Bt_san & A_san) | (At_san & Bt_san);
            end
            "or": begin: genor
                // assign Y_taint = (At_san & ~B_san) | (Bt_san & ~A_san);
                assign Y_taint = (At_san & ~B_san) | (Bt_san & ~A_san) | (At_san & Bt_san);
            end
            "eq", "ne": begin: geneq
                // assign Y_taint = |{At_san, Bt_san};
                assign Y_taint = ((A_san & ~(At_san | Bt_san)) == (B_san & ~(At_san | Bt_san))) & |{At_san, Bt_san};
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
            "sshr": begin: gensshr
                assign Y_taint = Bt_san ? {Y_WIDTH{1'b1}} : At_san >>> B_san;
            end
            "mul": begin: genmul
                assign Y_taint = {Y_WIDTH{|{At_san, Bt_san}}};
            end
            default: begin: gendefault
                assign Y_taint = At_san | Bt_san;
            end
        endcase
    endgenerate

endmodule

module taintcell_mux (A, B, S, Y, A_taint, B_taint, S_taint, Y_taint);

    parameter WIDTH = 32'd64;
    parameter TYPE = "mux";

    input [WIDTH-1:0] A;
    input [WIDTH-1:0] B;
    input S;
    input [WIDTH-1:0] Y;
    input [WIDTH-1:0] A_taint;
    input [WIDTH-1:0] B_taint;
    input S_taint;
    output [WIDTH-1:0] Y_taint;

    wire [WIDTH-1:0] A_san = $isunknown(A) ? {WIDTH{1'b0}} : A;
    wire [WIDTH-1:0] B_san = $isunknown(B) ? {WIDTH{1'b0}} : B;

    import "DPI-C" function byte xref_variant_mux(string hierarchy);
    export "DPI-C" function get_selection;
    function void get_selection();
        output byte select;
        select = S;
    endfunction

    reg S_diff;
    always @(negedge `SOC_TOP.clock) begin
        S_diff = xref_variant_mux($sformatf("%m"));
    end

    assign Y_taint = (S ? B_taint : A_taint) | (S_taint & S_diff ? A_san ^ B_san : {WIDTH{1'b0}});

endmodule

module taintcell_dff (CLK, SRST, ARST, EN, D, Q, SRST_taint, ARST_taint, EN_taint, D_taint, Q_taint,
    taint_sum);

    parameter WIDTH = 0;
    parameter CLK_POLARITY = 1'b1;
    parameter EN_POLARITY = 1'b1;
    parameter SRST_POLARITY = 1'b1;
    parameter SRST_VALUE = 0;
    parameter ARST_POLARITY = 1'b1;
    parameter ARST_VALUE = 0;
    parameter TYPE="dff";

    input CLK, ARST, SRST, EN;
    input [WIDTH-1:0] D;
    input [WIDTH-1:0] Q;
    input SRST_taint, ARST_taint, EN_taint;
    input [WIDTH-1:0] D_taint;
    output reg [WIDTH-1:0] Q_taint;
    output taint_sum;

    wire pos_clk = CLK == CLK_POLARITY;
    wire pos_srst = SRST == SRST_POLARITY;
    wire pos_arst = ARST == ARST_POLARITY;
    wire pos_en = EN == EN_POLARITY;

    wire [WIDTH-1:0] D_san = $isunknown(D) ? {WIDTH{1'b0}} : D;
    wire [WIDTH-1:0] Q_san = $isunknown(Q) ? {WIDTH{1'b0}} : Q;

    import "DPI-C" function byte xref_variant_dffe(string hierarchy);
    import "DPI-C" function byte xref_variant_sdff(string hierarchy);
    import "DPI-C" function byte xref_variant_adff(string hierarchy);
    export "DPI-C" function get_enable;
    export "DPI-C" function get_srst;
    export "DPI-C" function get_arst;
    function void get_enable();
        output byte enable;
        enable = pos_en;
    endfunction
    function void get_srst();
        output byte srst;
        srst = pos_arst;
    endfunction
    function void get_arst();
        output byte arst;
        arst = pos_arst;
    endfunction

    reg en_diff, srst_diff, arst_diff;
    always @(negedge `SOC_TOP.clock) begin
        en_diff = xref_variant_dffe($sformatf("%m"));
        srst_diff = xref_variant_sdff($sformatf("%m"));
        arst_diff = xref_variant_adff($sformatf("%m"));
            end

    generate
        initial #(`RESET_DELAY) Q_taint = 0;
        case (TYPE)
            "dff": begin: gendff
                always @(posedge pos_clk) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= D_taint;
                end
            end
            "sdff": begin: gensdff
                always @(posedge pos_clk) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= (pos_srst ? 0 : D_taint) |
                                   (SRST_taint & srst_diff ? SRST_VALUE ^ D_san : {WIDTH{1'b0}});
                end
            end
            "adff": begin: genadff
                always @(posedge pos_clk, posedge pos_arst) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= (pos_arst ? 0 : D_taint) | 
                                   (ARST_taint & arst_diff ? ARST_VALUE ^ D_san : {WIDTH{1'b0}});
                end
            end
            "dffe": begin: gendffe
                always @(posedge pos_clk) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= (pos_en ? D_taint : Q_taint) | 
                                   (EN_taint & en_diff ? D_san ^ Q_san : {WIDTH{1'b0}});
                end
            end
            "sdffe": begin: gensdffe
                always @(posedge pos_clk) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= (pos_srst ? 0 : (pos_en ? D_taint : Q_taint)) | 
                            (SRST_taint & srst_diff ? SRST_VALUE ^ Q_san : 
                                (EN_taint & en_diff ? D_san ^ Q_san : {WIDTH{1'b0}}));
                end
            end
            "adffe": begin: genadffe
                always @(posedge pos_clk, posedge pos_arst) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= (pos_arst ? 0 : (pos_en ? D_taint : Q_taint)) | 
                            (ARST_taint & arst_diff ? ARST_VALUE ^ Q_san : 
                                (EN_taint & en_diff ? D_san ^ Q_san : {WIDTH{1'b0}}));
                end
            end
            "sdffce": begin: gensdffce
                always @(posedge pos_clk) begin
                    if (`SOC_TOP.reset)
                        Q_taint <= 0;
                    else
                        Q_taint <= (pos_en ? (pos_srst ? 0 : D_taint) : Q_taint) |
                            (EN_taint & en_diff ? (SRST_taint & srst_diff ? SRST_VALUE ^ Q_san : D_san ^ Q_san) : 
                                {WIDTH{1'b0}});
                end
            end
            default: begin: generror
                initial $error("Unknown dff type %s at %m", TYPE);
            end
        endcase

        assign taint_sum = |Q_taint;

    endgenerate
endmodule

module taintcell_mem (RD_CLK, RD_EN, RD_ARST, RD_SRST, RD_ADDR, RD_DATA, WR_CLK, WR_EN, WR_ADDR, WR_DATA,
    RD_EN_taint, RD_ARST_taint, RD_SRST_taint, RD_ADDR_taint, RD_DATA_taint, WR_EN_taint, WR_ADDR_taint, WR_DATA_taint, taint_sum);

    parameter MEMID = "";
    parameter signed SIZE = 4;
    parameter signed OFFSET = 0;
    parameter signed ABITS = 2;
    parameter signed WIDTH = 8;

    parameter signed RD_PORTS = 1;
    parameter RD_CLK_ENABLE = 1'b1;
    parameter RD_CLK_POLARITY = 1'b1;
    parameter RD_TRANSPARENCY_MASK = 1'b0;
    parameter RD_COLLISION_X_MASK = 1'b0;
    parameter RD_CE_OVER_SRST = 1'b0;
    parameter RD_ARST_VALUE = 1'b0;
    parameter RD_SRST_VALUE = 1'b0;

    parameter signed WR_PORTS = 1;
    parameter WR_CLK_ENABLE = 1'b1;
    parameter WR_CLK_POLARITY = 1'b1;
    parameter WR_PRIORITY_MASK = 1'b0;
    parameter WR_WIDE_CONTINUATION = 1'b0;

    input [RD_PORTS-1:0] RD_CLK;
    input [RD_PORTS-1:0] RD_EN;
    input [RD_PORTS-1:0] RD_EN_taint;
    input [RD_PORTS-1:0] RD_ARST;
    input [RD_PORTS-1:0] RD_ARST_taint;
    input [RD_PORTS-1:0] RD_SRST;
    input [RD_PORTS-1:0] RD_SRST_taint;
    input [RD_PORTS*ABITS-1:0] RD_ADDR;
    input [RD_PORTS*ABITS-1:0] RD_ADDR_taint;
    input [RD_PORTS*WIDTH-1:0] RD_DATA;
    output reg [RD_PORTS*WIDTH-1:0] RD_DATA_taint;

    input [WR_PORTS-1:0] WR_CLK;
    input [WR_PORTS*WIDTH-1:0] WR_EN;
    input [WR_PORTS*WIDTH-1:0] WR_EN_taint;
    input [WR_PORTS*ABITS-1:0] WR_ADDR;
    input [WR_PORTS*ABITS-1:0] WR_ADDR_taint;
    input [WR_PORTS*WIDTH-1:0] WR_DATA;
    input [WR_PORTS*WIDTH-1:0] WR_DATA_taint;

    output reg [ABITS:0] taint_sum;

    integer i, j;
    reg [WIDTH-1:0] memory_taint [SIZE-1:0];
    initial begin
        #(`RESET_DELAY)
        for (i = 0; i < SIZE; i = i+1)
            memory_taint[i] = 0;
    end

    generate
        if (RD_CLK_ENABLE == 0) begin: async_read
            always @(*) begin
                for (i = 0; i < RD_PORTS; i = i+1)
                    RD_DATA_taint[i*WIDTH +: WIDTH] = 
                        (RD_ARST[i] ? 0 : memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{|RD_ADDR_taint[i*ABITS +: ABITS]}}) |
                        RD_ARST_taint[i] ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
            end
        end
        else if (&RD_CLK_ENABLE != 1) begin: mix_read
            initial $error("Mixed read ports are not supported: %s at %m", MEMID);
        end
        else begin: sync_read
            if (|RD_TRANSPARENCY_MASK | |RD_COLLISION_X_MASK)
                initial $error("Transparency and collision masks are not supported: %s at %m", MEMID);
            if (|RD_CLK_POLARITY && !&RD_CLK_POLARITY)
                initial $error("Mixed read clock polarities are not supported: %s at %m", MEMID);
            wire pos_clk = RD_CLK[0] == RD_CLK_POLARITY[0];
            always @(posedge pos_clk) begin
                for (i = 0; i < RD_PORTS; i = i+1)
                    if (RD_CE_OVER_SRST[i])
                        RD_DATA_taint[i*WIDTH +: WIDTH] <= 
                            (RD_EN[i] ? 
                                (RD_SRST[i] ? 
                                    0 : 
                                    memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{|RD_ADDR_taint[i*ABITS +: ABITS]}}) : 
                                0) |
                            RD_EN[i] & RD_EN_taint[i] ? 
                                {WIDTH{1'b1}} : 
                                (RD_EN[i] & RD_SRST[i] & RD_SRST_taint[i] ? {WIDTH{1'b1}} : {WIDTH{1'b0}});
                    else
                        RD_DATA_taint[i*WIDTH +: WIDTH] <= 
                            (RD_SRST[i] ? 
                                0 : 
                                (RD_EN[i] ? 
                                    memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{|RD_ADDR_taint[i*ABITS +: ABITS]}} : 
                                    0)) |
                            RD_SRST[i] & RD_SRST_taint[i] ? 
                                {WIDTH{1'b1}} : 
                                (!RD_SRST[i] & RD_EN[i] & RD_EN_taint[i] ? {WIDTH{1'b1}} : {WIDTH{1'b0}});
            end
        end

        if (WR_CLK_ENABLE == 0) begin: async_write
            always @(*) begin
                if (`SOC_TOP.reset) begin
                    for (i = 0; i < SIZE; i = i+1)
                        memory_taint[i] = 0;
                end
                else begin
                    for (i = 0; i < WR_PORTS; i = i+1)
                            for (j = 0; j < WIDTH; j = j+1)
                                if (WR_EN[i*WIDTH+j])
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET][j] = 
                                        WR_DATA_taint[i*WIDTH+j] |
                                        |WR_ADDR_taint[i*ABITS +: ABITS] | 
                                        WR_EN_taint[i*WIDTH+j];
                end
            end
        end
        else if (&WR_CLK_ENABLE != 1) begin: mix_write
            initial $error("Mixed write ports are not supported: %s at %m", MEMID);
        end
        else begin: sync_write
            if (|WR_CLK_POLARITY && !&WR_CLK_POLARITY)
                initial $error("Mixed write clock polarities are not supported: %s at %m", MEMID);
            wire pos_clk = WR_CLK[0] == WR_CLK_POLARITY[0];
            always @(posedge pos_clk) begin
                if (`SOC_TOP.reset) begin
                    for (i = 0; i < SIZE; i = i+1)
                        memory_taint[i] = 0;
                end
                else begin
                    for (i = 0; i < WR_PORTS; i = i+1)
                            for (j = 0; j < WIDTH; j = j+1)
                                if (WR_EN[i*WIDTH+j])
                                    // use blocking assigment here, because verilator doesn't support non-blocking assignments in generate blocks
                                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET][j] = 
                                        WR_DATA_taint[i*WIDTH+j] | 
                                        |WR_ADDR_taint[i*ABITS +: ABITS] | 
                                        WR_EN_taint[i*WIDTH+j];
                end
            end
        end

        always @(*) begin
            taint_sum = 0;
            for (i = 0; i < SIZE; i = i+1)
                taint_sum = taint_sum + |memory_taint[i];
        end

    endgenerate

endmodule
