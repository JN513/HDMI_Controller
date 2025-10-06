// -----------------------------------------------------------------------------
// TMDS Encoder - Codifica 8 bits de entrada em 10 bits de saída (HDMI/DVI)
// Baseado na especificação original Silicon Image (TMDS 8b/10b).
// -----------------------------------------------------------------------------
module tmds_encoder (
    input  logic         clk,          // clock
    input  logic  [7:0]  din,          // dado de 8 bits (por canal)
    input  logic         c0,           // controle de sincronismo horizontal
    input  logic         c1,           // controle de sincronismo vertical
    input  logic         de,           // data enable (1 = pixel ativo)
    output logic [9:0]   dout          // saída codificada TMDS
);

    // -------------------------------------------------------------------------
    // Variáveis internas
    // -------------------------------------------------------------------------
    logic [3:0] n1_din;          // quantidade de bits '1' na entrada
    logic [8:0] q_m;             // resultado da primeira etapa (8b → 9b)
    logic [4:0] n1_qm;           // quantidade de bits '1' em q_m
    logic signed [4:0] disparity; // disparidade acumulada
    logic use_xnor;              // modo XOR/XNOR
    logic [9:0] q_out;           // saída temporária

    // -------------------------------------------------------------------------
    // Contagem de bits '1' na entrada
    // -------------------------------------------------------------------------
    always_comb begin
        n1_din = din[0] + din[1] + din[2] + din[3] +
                 din[4] + din[5] + din[6] + din[7];
    end

    // -------------------------------------------------------------------------
    // Etapa 1: Minimização de transições (gera q_m[7:0], q_m[8])
    // -------------------------------------------------------------------------
    always_comb begin
        q_m[0] = din[0];
        for (int i = 1; i < 8; i++) begin
            if ((n1_din > 4) || ((n1_din == 4) && (din[0] == 0)))
                q_m[i] = q_m[i-1] ~^ din[i]; // XNOR
            else
                q_m[i] = q_m[i-1] ^ din[i];  // XOR
        end
        use_xnor = (n1_din > 4) || ((n1_din == 4) && (din[0] == 0));
        q_m[8] = use_xnor;
    end

    // -------------------------------------------------------------------------
    // Etapa 2: Balanceamento DC (gera Q[9:0])
    // -------------------------------------------------------------------------
    always_comb begin
        n1_qm = q_m[0] + q_m[1] + q_m[2] + q_m[3] +
                q_m[4] + q_m[5] + q_m[6] + q_m[7];
        logic signed [4:0] diff = n1_qm - (8 - n1_qm);

        q_out = 10'b0;
        if (!de) begin
            // Durante blanking, transmite códigos de controle
            case ({c1, c0})
                2'b00: q_out = 10'b1101010100;
                2'b01: q_out = 10'b0010101011;
                2'b10: q_out = 10'b0101010100;
                2'b11: q_out = 10'b1010101011;
            endcase
        end
        else begin
            // Modo ativo (dados de pixel)
            if ((disparity == 0) || (n1_qm == 4)) begin
                q_out[9]   = ~q_m[8];
                q_out[8]   =  q_m[8];
                q_out[7:0] = (q_m[8]) ? ~q_m[7:0] : q_m[7:0];
                disparity  = disparity + (q_m[8] ? (8 - 2*n1_qm) : (2*n1_qm - 8));
            end
            else if (((disparity > 0) && (n1_qm > 4)) ||
                     ((disparity < 0) && (n1_qm < 4))) begin
                q_out[9]   = 1'b1;
                q_out[8]   = q_m[8];
                q_out[7:0] = ~q_m[7:0];
                disparity  = disparity - diff;
            end
            else begin
                q_out[9]   = 1'b0;
                q_out[8]   = q_m[8];
                q_out[7:0] = q_m[7:0];
                disparity  = disparity + diff;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Saída registrada (sincronizada com clock)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk)
        dout <= q_out;

endmodule
