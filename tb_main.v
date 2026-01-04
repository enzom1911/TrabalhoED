`timescale 1ns / 1ps

module tb_main;

    // Inputs
    reg CLOCK_50;
    reg [3:0] KEY; // KEY[0]=Reset, KEY[1]=Hit, KEY[2]=Stay

    // Outputs
    wire [17:0] LEDR;
    wire [6:0] HEX0, HEX1, HEX4, HEX5;

    // Instancia o Módulo Main
    // Sobrescrever os valores para simulação
    main #(
        .SIM_DEBOUNCE_TIMER(20'd5),    // Debounce precisa de apenas 5 ciclos
        .SIM_GAME_TIMER(27'd10)        // Timer do jogo espera apenas 10 ciclos
    )uut(
        .CLOCK_50(CLOCK_50), 
        .KEY(KEY), 
        .LEDR(LEDR), 
        .HEX0(HEX0), 
        .HEX1(HEX1), 
        .HEX4(HEX4), 
        .HEX5(HEX5)
    );

    // Geração de Clock (50MHz -> Periodo = 20ns)
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // Teste
    initial begin
        // Inicialização
        KEY = 4'b1111; // Botões soltos (Lógica negativa na DE2-115, 1 = solto)
        
        // 1. Reset do sistema
        #100;
        KEY[0] = 0; // Pressiona Reset
        #300; // Espera tempo suficiente para o debounce 
        KEY[0] = 1; // Solta Reset
        #100;
        
        // O sistema deve entrar no estado de embaralhar e distribuir cartas automaticamente.
        // A redução no Timer torna esse procedimento visível no waveform.

        // 2. Simular um HIT (Pedir carta)
        #2000; // Espera as cartas iniciais serem distribuídas
        KEY[1] = 0; // Pressiona Hit
        #100;
        KEY[1] = 1; // Solta Hit
        
        // 3. Simular um STAY (Parar)
        #2000;
        KEY[2] = 0; // Pressiona Stay
        #100;
        KEY[2] = 1; // Solta Stay

        // Espera fim do jogo
        #5000;
        $stop;
    end
endmodule