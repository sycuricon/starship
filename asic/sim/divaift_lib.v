import "DPI-C" function int unsigned register_reference(string hierarchy);

// module taintcell_1I1O(A, Y, A_taint, Y_taint);
module taintcell_1I1O(A, A_taint, Y_taint);

    parameter A_SIGNED = 0;
    parameter A_WIDTH = 0;
    parameter TYPE = "default";
    parameter Y_WIDTH = 0;

    localparam integer INPUT_WIDTH = A_WIDTH;
    localparam integer OUTPUT_WIDTH = Y_WIDTH;

    input [A_WIDTH-1:0] A;
    input [A_WIDTH-1:0] A_taint;
    // input [Y_WIDTH-1:0] Y;
    output [Y_WIDTH-1:0] Y_taint;

    wire [INPUT_WIDTH-1:0] A_san = $isunknown(A) ? {Y_WIDTH{1'b0}} : A_SIGNED ? $signed(A) : A;
    // wire [OUTPUT_WIDTH-1:0] Y_san = $isunknown(Y) ? {Y_WIDTH{1'b0}} : Y;
    wire [INPUT_WIDTH-1:0] At_san = A_SIGNED ? $signed(A_taint) : A_taint;

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

    localparam integer INPUT_WIDTH = A_WIDTH > B_WIDTH ? A_WIDTH : B_WIDTH;
    localparam integer OUTPUT_WIDTH = Y_WIDTH;

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
`ifdef HASVARIANT
        ref_id = register_reference($sformatf("%m"));
`endif
    end

    import "DPI-C" function byte unsigned xref_diff_gate_cmp(int unsigned ref_id);
    export "DPI-C" function get_gate_cmp;
    function void get_gate_cmp();
        output byte unsigned cmp;
        cmp = Y_san[0];
    endfunction

    generate
        case (TYPE)
            "and": begin: genand
                assign Y_taint = (At_san & B_san) | (Bt_san & A_san) | (At_san & Bt_san);
            end
            "or": begin: genor
                assign Y_taint = (At_san & ~B_san) | (Bt_san & ~A_san) | (At_san & Bt_san);
            end
            "eq", "ne", "lt", "le", "gt", "ge": begin: gencmp
                reg [Y_WIDTH-1:0] gate_taint;
                reg cmp_diff = 1;
                always @(*) begin
                    if (|{At_san, Bt_san}) begin
`ifdef HASVARIANT
                        cmp_diff = xref_diff_gate_cmp(ref_id);
`endif
                        gate_taint = cmp_diff;
                    end
                    else begin
                        gate_taint = 0;
                    end
                end
                assign Y_taint = gate_taint;
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
    endgenerate

endmodule

// module taintcell_mux (A, B, S, Y, A_taint, B_taint, S_taint, Y_taint);
module taintcell_mux (A, B, S, A_taint, B_taint, S_taint, Y_taint);

    parameter WIDTH = 32'd64;
    parameter TYPE = "mux";

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
`ifdef HASVARIANT
        ref_id = register_reference($sformatf("%m"));
`endif
    end

    import "DPI-C" function byte unsigned xref_diff_mux_sel(int unsigned ref_id);
    export "DPI-C" function get_mux_sel;
    function void get_mux_sel();
        output byte select;
        select = S_san;
    endfunction

    reg S_diff = 1;

    always @(*) begin
        if (S_taint) begin
`ifdef HASVARIANT
            S_diff = xref_diff_mux_sel(ref_id);
`endif
            Y_taint = (S_san ? B_taint : A_taint) | (S_diff ? A_san ^ B_san : 0);
        end
        else begin
            Y_taint = S_san ? B_taint : A_taint;
        end
    end

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
    output [WIDTH-1:0] Q_taint;
    output taint_sum;

    reg [WIDTH-1:0] register_taint;
    assign Q_taint = register_taint;

    wire pos_clk = CLK == CLK_POLARITY;
    wire pos_srst = SRST == SRST_POLARITY;
    wire pos_arst = ARST == ARST_POLARITY;
    wire pos_en = EN == EN_POLARITY;

    wire [WIDTH-1:0] D_san = $isunknown(D) ? {WIDTH{1'b0}} : D;
    wire [WIDTH-1:0] Q_san = $isunknown(Q) ? {WIDTH{1'b0}} : Q;

    reg merged = 0;
    int unsigned ref_id = 0;
    initial begin
`ifdef HASVARIANT
        ref_id = register_reference($sformatf("%m"));
`endif
        #(`RESET_DELAY) register_taint = 0;
    end

    import "DPI-C" function byte unsigned xref_diff_dff_en(int unsigned ref_id);
    import "DPI-C" function byte unsigned xref_diff_dff_srst(int unsigned ref_id);
    import "DPI-C" function byte unsigned xref_diff_dff_arst(int unsigned ref_id);
    import "DPI-C" function byte unsigned xref_merge_dff_taint(int unsigned ref_id);
    export "DPI-C" function get_dff_en;
    export "DPI-C" function get_dff_srst;
    export "DPI-C" function get_dff_arst;
    export "DPI-C" function get_dff_taint;
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
    function void get_dff_taint();
        output byte unsigned tainted;
        tainted = |register_taint;
    endfunction

    reg query_taint;
    reg en_diff = 1, srst_diff = 1, arst_diff = 1;

    generate
        always @(negedge pos_clk) begin
            if (!merged && Testbench.smon.victim_done) begin
`ifdef HASVARIANT
                query_taint = xref_merge_dff_taint(ref_id);
                register_taint <= {WIDTH{query_taint}};
`endif
                merged = 1;
            end
        end

        assign taint_sum = |register_taint;

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
`ifdef HASVARIANT
                            srst_diff = xref_diff_dff_srst(ref_id);
`endif
                            register_taint <= srst_diff ? SRST_VALUE ^ D_san : 0;
                        end
                        else begin
                            register_taint <= 0;
                        end
                    end
                    else begin
                        if (SRST_taint) begin
`ifdef HASVARIANT
                            srst_diff = xref_diff_dff_srst(ref_id);
`endif
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
`ifdef HASVARIANT
                            arst_diff = xref_diff_dff_arst(ref_id);
`endif
                            register_taint <= arst_diff ? ARST_VALUE ^ D_san : 0;
                        end
                        else begin
                            register_taint <= 0;
                        end
                    end
                    else begin
                        if (ARST_taint) begin
`ifdef HASVARIANT
                            arst_diff = xref_diff_dff_arst(ref_id);
`endif
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
`ifdef HASVARIANT
                            en_diff = xref_diff_dff_en(ref_id);
`endif
                            register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                        end
                        else begin
                            register_taint <= D_taint;
                        end
                    end
                    else begin
                        if (EN_taint) begin
`ifdef HASVARIANT
                            en_diff = xref_diff_dff_en(ref_id);
`endif
                            register_taint <= register_taint | (en_diff ? D_san ^ Q_san : 0);
                        end
                    end
                end
            end
            "sdffe": begin: gensdffe
                always @(posedge pos_clk) begin
                    if (pos_srst) begin
                        if (SRST_taint) begin
`ifdef HASVARIANT
                            srst_diff = xref_diff_dff_srst(ref_id);
`endif
                            register_taint <= srst_diff ? SRST_VALUE ^ D_san : 0;
                        end
                        else begin
                            register_taint <= 0;
                        end
                    end
                    else begin
                        if (pos_en) begin
                            if (EN_taint) begin
`ifdef HASVARIANT
                                en_diff = xref_diff_dff_en(ref_id);
`endif
                                register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                            end
                            else begin
                                register_taint <= D_taint;
                            end
                        end
                        else begin
                            if (EN_taint) begin
`ifdef HASVARIANT
                                en_diff = xref_diff_dff_en(ref_id);
`endif
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
`ifdef HASVARIANT
                            arst_diff = xref_diff_dff_arst(ref_id);
`endif
                            register_taint <= arst_diff ? ARST_VALUE ^ D_san : 0;
                        end
                        else begin
                            register_taint <= 0;
                        end
                    end
                    else begin
                        if (pos_en) begin
                            if (EN_taint) begin
`ifdef HASVARIANT
                                en_diff = xref_diff_dff_en(ref_id);
`endif
                                register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                            end
                            else begin
                                register_taint <= D_taint;
                            end
                        end
                        else begin
                            if (EN_taint) begin
`ifdef HASVARIANT
                                en_diff = xref_diff_dff_en(ref_id);
`endif
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
`ifdef HASVARIANT
                                srst_diff = xref_diff_dff_srst(ref_id);
`endif
                                register_taint <= srst_diff ? SRST_VALUE ^ D_san : 0;
                            end
                            else begin
                                register_taint <= 0;
                            end
                        end
                        else begin
                            if (EN_taint) begin
`ifdef HASVARIANT
                                en_diff = xref_diff_dff_en(ref_id);
`endif
                                register_taint <= D_taint | (en_diff ? D_san ^ Q_san : 0);
                            end
                            else begin
                                register_taint <= D_taint;
                            end
                        end
                    end
                    else begin
                        if (EN_taint) begin
`ifdef HASVARIANT
                            en_diff = xref_diff_dff_en(ref_id);
`endif
                            register_taint <= register_taint | (en_diff ? D_san ^ Q_san : 0);
                        end
                        else if (SRST_taint) begin
`ifdef HASVARIANT
                            srst_diff = xref_diff_dff_srst(ref_id);
`endif
                            register_taint <= register_taint | (srst_diff ? SRST_VALUE ^ Q_san : 0);
                        end
                    end
                end
            end
            default: begin: generror
                initial $error("Unknown dff type %s at %m", TYPE);
            end
        endcase
    endgenerate
endmodule

// module taintcell_mem (RD_CLK, RD_EN, RD_ARST, RD_SRST, RD_ADDR, RD_DATA, WR_CLK, WR_EN, WR_ADDR, WR_DATA,
//     RD_EN_taint, RD_ARST_taint, RD_SRST_taint, RD_ADDR_taint, RD_DATA_taint, WR_EN_taint, WR_ADDR_taint, WR_DATA_taint, taint_sum);
module taintcell_mem (RD_CLK, RD_EN, RD_ARST, RD_SRST, RD_ADDR, WR_CLK, WR_EN, WR_ADDR,
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

    localparam integer EXT_SIZE = $pow(2, $clog2(SIZE));

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

    output reg [ABITS:0] taint_sum;

    int i, j;
    wire pos_rd_clk = RD_CLK[0] == RD_CLK_POLARITY[0];
    wire pos_wt_clk = WR_CLK[0] == WR_CLK_POLARITY[0];

    reg merged = 0;
    int unsigned ref_id;
    reg [WIDTH-1:0] memory_taint [EXT_SIZE-1:0];
    reg [WIDTH-1:0] cell_old_taint;
    reg [WIDTH-1:0] cell_new_taint;
    initial begin
        // if (EXT_SIZE != SIZE) begin
        //     $display("Unmatched memory size %d/%d for %m", SIZE, EXT_SIZE);
        // end
        cell_old_taint = 0;
        cell_new_taint = 0;
        taint_sum = 0;
        merged = 0;
        ref_id = register_reference($sformatf("%m"));
        #(`RESET_DELAY)
        for (i = 0; i < EXT_SIZE; i = i+1)
            memory_taint[i] = 0;
    end

    import "DPI-C" function byte unsigned xref_diff_mem_rd_en(int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_wt_en(int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_rd_srst(int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_diff_mem_rd_arst(int unsigned ref_id, int unsigned index);
    import "DPI-C" function byte unsigned xref_merge_mem_taint(int unsigned ref_id, int unsigned index);
    export "DPI-C" function get_mem_rd_en;
    export "DPI-C" function get_mem_wt_en;
    export "DPI-C" function get_mem_rd_srst;
    export "DPI-C" function get_mem_rd_arst;
    export "DPI-C" function get_mem_taint;
    function void get_mem_rd_en();
        input int unsigned index;
        output byte unsigned en;
        en = RD_EN[index];
    endfunction
    function void get_mem_wt_en();
        input int unsigned index;
        output byte unsigned en;
        en = WR_EN[index];
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
    function void get_mem_taint();
        input int unsigned index;
        output byte unsigned tainted;
        tainted = |memory_taint[index];
    endfunction

    // reg [RD_PORTS-1:0] rd_en_diff, rd_srst_diff, rd_arst_diff;
    // reg [WR_PORTS*WIDTH-1:0] wt_en_diff;

    // disable variant rule for performance optimization
    // always @(negedge Testbench.clock) begin
    //     for (i = 0; i < RD_PORTS; i = i+1) begin
    //         rd_en_diff[i] = xref_diff_mem_rd_en(ref_id, i);
    //         rd_srst_diff[i] = xref_diff_mem_rd_srst(ref_id, i);
    //         rd_arst_diff[i] = xref_diff_mem_rd_arst(ref_id, i);
    //     end
    //     for (i = 0; i < WR_PORTS; i = i+1) begin
    //         for (j = 0; j < WIDTH; j = j+1) begin
    //             wt_en_diff[i*WIDTH + j] = xref_diff_mem_wt_en(ref_id, i*WIDTH + j);
    //         end
    //     end
    // end

    generate
        reg query_taint;
        always @(negedge Testbench.clock) begin
            if (!merged && Testbench.smon.victim_done) begin
                taint_sum = 0;
                for (i = 0; i < SIZE; i = i+1) begin
                    query_taint = xref_merge_mem_taint(ref_id, i);
                    memory_taint[i] = {WIDTH{query_taint}};
                    taint_sum = taint_sum + |memory_taint[i];
                end
                merged = 1;
            end
            // taint_sum = 0;
            // for (i = 0; i < SIZE; i = i+1)
            //     taint_sum = taint_sum + |memory_taint[i];
        end

        if (RD_CLK_ENABLE == 0) begin: async_read
            always @(*) begin
                for (i = 0; i < RD_PORTS; i = i+1)
                    memory_rd_taint[i*WIDTH +: WIDTH] = 
                        (RD_ARST[i] ? 0 : memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{|RD_ADDR_taint[i*ABITS +: ABITS]}}) |
                        RD_ARST_taint[i] /* & rd_arst_diff[i] */ ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
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
            always @(posedge pos_rd_clk) begin
                for (i = 0; i < RD_PORTS; i = i+1)
                    if (RD_CE_OVER_SRST[i])
                        memory_rd_taint[i*WIDTH +: WIDTH] <= 
                            (RD_EN[i] ? 
                                (RD_SRST[i] ? 0 : memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{|RD_ADDR_taint[i*ABITS +: ABITS]}}) : 
                                0) |
                            RD_EN_taint[i] /* & rd_en_diff[i] */ ? 
                                {WIDTH{1'b1}} : 
                                (RD_SRST_taint[i] /* & rd_srst_diff[i] */ ? {WIDTH{1'b1}} : {WIDTH{1'b0}});
                    else
                        memory_rd_taint[i*WIDTH +: WIDTH] <= 
                            (RD_SRST[i] ? 
                                0 : (RD_EN[i] ? memory_taint[RD_ADDR[i*ABITS +: ABITS] - OFFSET] | {WIDTH{|RD_ADDR_taint[i*ABITS +: ABITS]}} : 0)) |
                            RD_SRST_taint[i] /* & rd_srst_diff[i] */ ? 
                                {WIDTH{1'b1}} : 
                                (RD_EN_taint[i] /* & rd_en_diff[i] */ ? {WIDTH{1'b1}} : {WIDTH{1'b0}});
            end
        end

        if (WR_CLK_ENABLE == 0) begin: async_write
            always @(*) begin
                for (i = 0; i < WR_PORTS; i = i+1) begin
                    cell_old_taint = memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];
                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = 
                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]) |
                        {WIDTH{|WR_ADDR_taint[i*ABITS +: ABITS]}} |
                        WR_EN_taint[i*WIDTH +: WIDTH];

                    // for (j = 0; j < WIDTH; j = j+1) begin
                    //     if (WR_EN[i*WIDTH+j]) begin
                    //         memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET][j] = 
                    //             WR_DATA_taint[i*WIDTH+j] |
                    //             |WR_ADDR_taint[i*ABITS +: ABITS] | 
                    //             WR_EN_taint[i*WIDTH+j] /* & wt_en_diff[i*WIDTH+j] */;
                    //     end
                    // end
                    cell_new_taint = memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];
                    if (cell_old_taint ^ cell_new_taint) begin
                        if (cell_new_taint)
                            taint_sum = taint_sum + 1;
                        else
                            taint_sum = taint_sum - 1;
                    end
                end
            end
        end
        else if (&WR_CLK_ENABLE != 1) begin: mix_write
            initial $error("Mixed write ports are not supported: %s at %m", MEMID);
        end
        else begin: sync_write
            if (|WR_CLK_POLARITY && !&WR_CLK_POLARITY)
                initial $error("Mixed write clock polarities are not supported: %s at %m", MEMID);
            always @(posedge pos_wt_clk) begin
                for (i = 0; i < WR_PORTS; i = i+1) begin
                    cell_old_taint = memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];
                    memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET] = 
                        (WR_DATA_taint[i*WIDTH +: WIDTH] & WR_EN[i*WIDTH +: WIDTH]) |
                        {WIDTH{|WR_ADDR_taint[i*ABITS +: ABITS]}} |
                        WR_EN_taint[i*WIDTH +: WIDTH];
                    // for (j = 0; j < WIDTH; j = j+1) begin
                    //     if (WR_EN[i*WIDTH+j]) begin
                    //         // use blocking assigment here, because verilator doesn't support non-blocking assignments in generate blocks
                    //         memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET][j] = 
                    //             WR_DATA_taint[i*WIDTH+j] | 
                    //             |WR_ADDR_taint[i*ABITS +: ABITS] | 
                    //             WR_EN_taint[i*WIDTH+j] /* & wt_en_diff[i*WIDTH+j] */;
                    //     end
                    // end
                    cell_new_taint = memory_taint[WR_ADDR[i*ABITS +: ABITS] - OFFSET];
                    if (cell_old_taint ^ cell_new_taint) begin
                        if (cell_new_taint)
                            taint_sum = taint_sum + 1;
                        else
                            taint_sum = taint_sum - 1;
                    end
                end
            end
        end
    endgenerate

endmodule
