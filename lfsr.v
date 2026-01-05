module lfsr (
    input clock,
    input reset,
    output [5:0] rnd_out // Gera números para acessar as 52 posições
);

    reg [15:0] lfsr_reg;
    // Polinômio para gerar a sequência pseudoaleatória
    
    initial begin
        lfsr_reg = 16'hACE1; // Valor inicial não-zero
    end
    
    wire feedback = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];

    always @(posedge clock or posedge reset) begin
        if (reset)
            lfsr_reg <= 16'hACE1; //
        else
            lfsr_reg <= {lfsr_reg[14:0], feedback};

    end

    // Usamos bits centrais para evitar padrões repetitivos nos bits baixos
    assign rnd_out = lfsr_reg [10:5];

endmodule