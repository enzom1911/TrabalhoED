module main (
    input CLOCK_50,        // Clock da placa DE2-115
    input [3:0] KEY,       // Botões (KEY[0]=Reset, KEY[1]=Hit, KEY[2]=Stay)
    output [17:0] LEDR,    // LEDs vermelhos (Status)
    output [6:0] HEX0, HEX1, // Display Jogador (Unidade, Dezena)
    output [6:0] HEX4, HEX5  // Display Banca (Unidade, Dezena)
);

    // Fios de conexão interna
    wire reset_clean, hit_clean, stay_clean;
    wire w_embaralhar_ok, w_embaralhar_start;
    wire w_pjogador, w_pdealer;
    wire w_cartaok;
    wire [5:0] w_pts_jogador, w_pts_dealer;
    wire [5:0] w_endereco;
    wire [3:0] w_carta_valor;
    
    // Sinais de BCD para Display
    wire [3:0] jog_uni, jog_dez, deal_uni, deal_dez;
    wire [6:0] disp_jog_uni, disp_jog_dez, disp_deal_uni, disp_deal_dez;

    // 1. Tratamento dos Botões (Debounce)
    // A lógica é invertida nas chaves da DE2-115 (0 = apertado), então invertemos na entrada (~KEY)
    debouncer db_rst  (.clock(CLOCK_50), .reset(1'b0), .botao_in(~KEY[0]), .out(reset_clean));
    debouncer db_hit  (.clock(CLOCK_50), .reset(reset_clean), .botao_in(~KEY[1]), .out(hit_clean));
    debouncer db_stay (.clock(CLOCK_50), .reset(reset_clean), .botao_in(~KEY[2]), .out(stay_clean));

    // 2. Máquina de Estados (Blackjack)
    blackjack FSM (
        .clock(CLOCK_50),
        .reset(reset_clean),
        .hit(hit_clean),
        .stay(stay_clean),
        .embaralhar_ok(w_embaralhar_ok),
        .cartaok(w_cartaok),
        .pts_jogador(w_pts_jogador),
        .pts_dealer(w_pts_dealer),
        // Saídas de controle
        .embaralhar_start(w_embaralhar_start),
        .pjogador(w_pjogador),
        .pdealer(w_pdealer),
        // Saídas de Status (LEDs)
        .player_hit(LEDR[0]),
        .player_stay(LEDR[1]),
        .dealer_hit(LEDR[2]),
        .dealer_stay(LEDR[3]),
        .win(LEDR[17]),
        .lose(LEDR[16]),
        .tie(LEDR[15])
    );

    // 3. Memória (Baralho) 
    baralho MEMORIA (
        .clock(CLOCK_50),
        .reset(reset_clean),
        .embaralhar_start(w_embaralhar_start),
        .ler_endereco(w_endereco),
        .q(w_carta_valor),
        .embaralhar_ok(w_embaralhar_ok)
    );

    // 4. Pontuação e Controle de Endereço 
    pontuacao SCORE (
        .clock(CLOCK_50),
        .reset(reset_clean),
        .carta(w_carta_valor),
        .pjogador(w_pjogador),
        .pdealer(w_pdealer),
        .endereco(w_endereco),
        .pts_jogador(w_pts_jogador),
        .pts_dealer(w_pts_dealer),
        .cartaok(w_cartaok)
    );

    //  5. Displays (Conversão Bin -> BCD -> 7Seg) 
    
    // Jogador
    bin2BCD bcd_jog (.binary(w_pts_jogador), .Dezenas(jog_dez), .Unidades(jog_uni));
    driver7seg seg_jog_u (.b(jog_uni), .d(HEX0));
    driver7seg seg_jog_d (.b(jog_dez), .d(HEX1));

    // Banca 
    bin2BCD bcd_deal (.binary(w_pts_dealer), .Dezenas(deal_dez), .Unidades(deal_uni));
    driver7seg seg_deal_u (.b(deal_uni), .d(HEX4));
    driver7seg seg_deal_d (.b(deal_dez), .d(HEX5));

endmodule