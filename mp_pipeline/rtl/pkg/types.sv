/////////////////////////////////////////////////////////////
// Maybe merge what is in mp_verif/rtl/cpu/types.sv over here? //
/////////////////////////////////////////////////////////////

package rv32i_types;

typedef enum logic {
    rs1_out = 1'b0,
    pc_out  = 1'b1
} alu_m1_sel_t;

// more mux def here

typedef struct packed {
    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [63:0]      order;

    alu_m1_sel_t        alu_m1_sel;

    // what else?

} id_ex_stage_reg_t;

endpackage