module baralho #(
    parameter SHUFFLE_LIMIT = 128 
)(
    input clock,
    input reset,
    input embaralhar_start,      // Vem do blackjack (estado embaralhar)
    input [5:0] ler_endereco,    // Vem do pontuacao (endereco)
    output reg [3:0] q,          // Valor da carta para o pontuacao
    output reg embaralhar_ok     // Avisa que terminou de misturar
);

    // Memória para 52 cartas
    reg [3:0] ram [0:51];
    
    // Controle do Embaralhamento
    reg [7:0] swap_counter;      
    wire [5:0] random_num;       
    reg [5:0] pos_A, pos_B;
    reg [1:0] state; 
    integer i;

    initial begin
        embaralhar_ok = 0;
        state = 0;
        swap_counter = 0;

        // Preenche a RAM com cartas válidas no tempo zero
        // Isso impede que saia "X" na primeira leitura
        for (i = 0; i < 52; i = i + 1) begin
            if ((i % 13) == 0) 
                ram[i] = 4'd1;         // Ás
            else if ((i % 13) < 10)
                ram[i] = (i % 13) + 1; // 2 a 10
            else
                ram[i] = 4'd11;        // J, Q, K
        end
    end     
    
    // Instancia o gerador de aleatoriedade
    lfsr RNG (
        .clock(clock),
        .reset(reset),
        .rnd_out(random_num)
    );

    parameter IDLE = 0, SWAP_GET_ADDR = 1, SWAP_DO = 2, FINISH = 3;

    reg [3:0] base_val; // Variável auxiliar para calcular o valor inicial

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // --- INICIALIZAÇÃO DA MEMÓRIA CONFORME SOLICITADO ---
            for (i = 0; i < 52; i = i + 1) begin
                // O operador % 13 gera 0..12.
                // 0 -> Ás (1)
                // 1..9 -> 2..10
                // 10, 11, 12 -> 11 (J, Q, K)
                
                if ((i % 13) == 0) 
                    ram[i] <= 4'd1;        // Ás
                else if ((i % 13) < 10)
                    ram[i] <= (i % 13) + 1; // 2 a 10
                else
                    ram[i] <= 4'd11;       // J, Q, K (Valete, Dama, Rei salvos como 11)
            end
            
            state <= IDLE;
            embaralhar_ok <= 0;
            swap_counter <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    embaralhar_ok <= 0;
                    if (embaralhar_start) begin
                        swap_counter <= SHUFFLE_LIMIT; // Define quantas trocas fará (quanto maior, mais misturado)
                        state <= SWAP_GET_ADDR;
                    end
                end

                SWAP_GET_ADDR: begin
                    // Busca dois endereços aleatórios válidos (<52)
                    if (random_num < 52) begin
                        pos_A <= random_num;
                        // Gera pos_B baseado em pos_A para garantir variação
                        pos_B <= (random_num + swap_counter) % 52; 
                        state <= SWAP_DO;
                    end
                end

                SWAP_DO: begin
                    // Realiza a troca (Swap) das cartas nas posições A e B
                    ram[pos_A] <= ram[pos_B];
                    ram[pos_B] <= ram[pos_A];
                    
                    if (swap_counter == 0)
                        state <= FINISH;
                    else begin
                        swap_counter <= swap_counter - 1;
                        state <= SWAP_GET_ADDR;
                    end
                end

                FINISH: begin
                    embaralhar_ok <= 1;
                    // Fica aqui até o próximo reset global
                end
            endcase
        end
    end

    // Leitura da Memória (Conectado ao módulo Pontuação)
    always @(*) begin
        if (ler_endereco < 52)
            q = ram[ler_endereco];
        else
            q = 4'd0; // Segurança para endereço inválido
    end

endmodule