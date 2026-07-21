module decode_rename
(
    input   logic                           clk,
    input   logic                           rst,

    input   logic                           valid,
    input   logic   [31:0]                  inst,
    input   logic   [31:0]                  pc,
    input   logic   [63:0]                  order,
    input   logic                           free_flag,
    input   logic   [5:0]                   pr_addr_free,

    output  rv32im_types::decoded_inst_t    decoded,
    output  logic                           rename_stall
);

    import rv32im_types::*;

    phys_reg_t      register_allocation_table [0:31];
    phys_reg_t      free_list [0:31];
    logic   [4:0]   free_head;
    logic   [4:0]   free_tail;
    logic   [5:0]   free_count;

    logic   [6:0]   opcode;
    logic   [2:0]   funct3;
    logic   [6:0]   funct7;
    logic   [4:0]   rs1;
    logic   [4:0]   rs2;
    logic   [4:0]   rd;

    logic   [31:0]  i_imm;
    logic   [31:0]  s_imm;
    logic   [31:0]  b_imm;
    logic   [31:0]  u_imm;
    logic   [31:0]  j_imm;

    logic           writes_rd;
    logic           alloc_needed;
    logic           free_valid;
    logic           alloc_fire;
    logic           deq_free;
    logic           enq_free;
    phys_reg_t      new_prd;

    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];

    assign i_imm = {{20{inst[31]}}, inst[31:20]};
    assign s_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign b_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    assign u_imm = {inst[31:12], 12'b0};
    assign j_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

    always_comb begin
        unique case (opcode)
        op_b_lui,
        op_b_auipc,
        op_b_jal,
        op_b_jalr,
        op_b_load,
        op_b_imm,
        op_b_reg: writes_rd = (rd != 5'b00000);
        default: writes_rd = 1'b0;
        endcase
    end

    assign alloc_needed = valid && writes_rd;
    assign free_valid = free_flag && pr_addr_free[5];
    assign rename_stall = alloc_needed && (free_count == 6'd0) && !free_valid;
    assign alloc_fire = alloc_needed && !rename_stall;
    assign deq_free = alloc_fire && (free_count != 6'd0);
    assign enq_free = free_valid && !(alloc_fire && (free_count == 6'd0)) &&
                      ((free_count != 6'd32) || deq_free);
    assign new_prd = (free_count != 6'd0) ? free_list[free_head] : pr_addr_free;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer idx = 0; idx < 32; idx++) begin
                register_allocation_table[idx] <= phys_reg_t'(idx);
                free_list[idx] <= phys_reg_t'(idx + 32);
            end
            free_head <= 5'd0;
            free_tail <= 5'd0;
            free_count <= 6'd32;
        end else begin
            if (alloc_fire) begin
                register_allocation_table[rd] <= new_prd;
            end

            if (enq_free) begin
                free_list[free_tail] <= pr_addr_free;
            end

            if (deq_free) begin
                free_head <= free_head + 5'd1;
            end

            if (enq_free) begin
                free_tail <= free_tail + 5'd1;
            end

            unique case ({enq_free, deq_free})
            2'b10: free_count <= free_count + 6'd1;
            2'b01: free_count <= free_count - 6'd1;
            default: free_count <= free_count;
            endcase
        end
    end

    always_comb begin
        decoded = '0;

        decoded.valid = valid && !rename_stall;
        decoded.pc = pc;
        decoded.order = order;
        decoded.opcode = rv32i_opcode'(opcode);
        decoded.funct3 = funct3;
        decoded.funct7 = funct7;
        decoded.prs1 = register_allocation_table[rs1];
        decoded.prs2 = register_allocation_table[rs2];
        decoded.prd = alloc_fire ? new_prd : register_allocation_table[rd];

        if (valid && !rename_stall) begin
            unique case (opcode)
            op_b_lui,
            op_b_auipc: begin
                decoded.imm = u_imm;
            end
            op_b_jal: begin
                decoded.imm = j_imm;
            end
            op_b_jalr: begin
                decoded.imm = i_imm;
            end
            op_b_br: begin
                decoded.imm = b_imm;
            end
            op_b_load: begin
                decoded.imm = i_imm;
            end
            op_b_store: begin
                decoded.imm = s_imm;
            end
            op_b_imm: begin
                decoded.imm = i_imm;
            end
            default: begin
            end
            endcase
        end
    end

endmodule : decode_rename
