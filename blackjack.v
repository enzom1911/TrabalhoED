// módulo da máquina principal onde vamos definir os diferentes estados do jogo e a transição entre eles

module blackjack(
    input embaralhar_ok, clock, reset, hit, stay, cartaok,
    input [5:0] pts_jogador, pts_dealer,
    output reg pjogador, pdealer, player_hit, dealer_hit, player_stay, dealer_stay, win, lose, tie, embaralhar_start
);

    parameter inicio          = 5'b00000,
              embaralhar      = 5'b00001,
              carta1_jogador  = 5'b00010,
              wait1_jogador   = 5'b00011,
              carta1_dealer   = 5'b00100,
              wait1_dealer    = 5'b00101, 
              carta2_jogador  = 5'b00110,
              wait2_jogador   = 5'b00111,
              carta2_dealer   = 5'b01000,
              wait2_dealer    = 5'b01001,
              vez_jogador     = 5'b01010,
              hit_jogador     = 5'b01011, // Espera 2s mostrando o LED
              fetch_hit_jog   = 5'b01100, // NOVO: Busca a carta efetivamente
              wait_jogador    = 5'b01101, // Espera handshake baixar
              stay_jogador    = 5'b01110,
              vez_dealer      = 5'b01111,
              hit_dealer      = 5'b10000, // Espera 2s mostrando o LED
              fetch_hit_deal  = 5'b10001, // NOVO: Busca a carta efetivamente
              wait_dealer     = 5'b10010,
              stay_dealer     = 5'b10011,
              check           = 5'b10100,
              fim_jogo        = 5'b10101;
    
    reg [4:0] estado_atual, proximo_estado;
    
    // Temporizador: 2 segundos (100.000.000 ciclos @ 50MHz)
    reg [26:0] contador_tempo;
    reg ativar_timer;
    wire timer_done;
    
    assign timer_done = (contador_tempo >= 100000000); // 2 segundos
    
    always @(posedge clock, posedge reset) begin
        if (reset) begin
            estado_atual <= inicio;
            contador_tempo <= 0;
        end
        else begin
            estado_atual <= proximo_estado;
            
            if (ativar_timer) begin
                if (!timer_done)
                    contador_tempo <= contador_tempo + 1;
                else
                    contador_tempo <= 0; // Reseta ao terminar para o proximo uso
            end
            else begin
                contador_tempo <= 0;
            end
        end
    end
    
    always @(*) begin
        // Valores default
        proximo_estado = estado_atual;
        pjogador = 0;
        pdealer = 0;
        ativar_timer = 0;
        player_hit = 0;
        player_stay = 0;
        dealer_stay = 0;
        dealer_hit = 0;
        win = 0;
        lose = 0;
        tie = 0;
        
        case(estado_atual)
            inicio: begin
                proximo_estado = embaralhar;
            end
            embaralhar: begin
                embaralhar_start = 1;
                if (embaralhar_ok)
                    proximo_estado = carta1_jogador;
            end
            
            // --- Distribuição Inicial ---
            carta1_jogador: begin
                pjogador = 1;
                if (cartaok) proximo_estado = wait1_jogador;
            end
            wait1_jogador: begin
                if (!cartaok) proximo_estado = carta1_dealer;
            end
            carta1_dealer: begin
                pdealer = 1;
                if (cartaok) proximo_estado = wait1_dealer;
            end
            wait1_dealer: begin
                if (!cartaok) proximo_estado = carta2_jogador;
            end
            carta2_jogador: begin
                pjogador = 1;
                if (cartaok) proximo_estado = wait2_jogador;
            end
            wait2_jogador: begin
                if (!cartaok) proximo_estado = carta2_dealer;
            end
            carta2_dealer: begin
                pdealer = 1;
                if (cartaok) proximo_estado = wait2_dealer;
            end
            wait2_dealer: begin
                if (!cartaok) proximo_estado = vez_jogador;
            end
            
            // --- Vez do Jogador ---
            vez_jogador: begin
                if (pts_jogador > 21)
                    proximo_estado = fim_jogo;
                else if (pts_jogador == 21) // Blackjack natural ou chegou em 21
                    proximo_estado = vez_dealer;
                else begin
                    if (hit)
                        proximo_estado = hit_jogador;
                    else if (stay)
                        proximo_estado = stay_jogador;
                end
            end
            
            // Estado de Animação (LED aceso por 2s)
            hit_jogador: begin 
                player_hit = 1;
                ativar_timer = 1;
                if (timer_done)
                    proximo_estado = fetch_hit_jog;
            end
            
            // Estado de Busca na Memória
            fetch_hit_jog: begin
                pjogador = 1; // Solicita carta
                if (cartaok)
                    proximo_estado = wait_jogador;
            end
            
            wait_jogador: begin
                if (!cartaok)
                    proximo_estado = vez_jogador;
            end
            
            stay_jogador: begin
                player_stay = 1;
                ativar_timer = 1;
                if (timer_done) 
                    proximo_estado = vez_dealer;
            end
            
            // --- Vez do Dealer ---
            vez_dealer: begin
                if (pts_dealer > 21)
                    proximo_estado = fim_jogo;
                else if (pts_dealer >= 17)
                    proximo_estado = stay_dealer;
                else
                    proximo_estado = hit_dealer;
            end
            
            hit_dealer: begin
                dealer_hit = 1;
                ativar_timer = 1;
                if (timer_done)
                    proximo_estado = fetch_hit_deal;
            end

            fetch_hit_deal: begin
                pdealer = 1;
                if (cartaok)
                    proximo_estado = wait_dealer;
            end
            
            wait_dealer: begin
                if (!cartaok)
                    proximo_estado = vez_dealer;
            end
            
            stay_dealer: begin
                dealer_stay = 1;
                ativar_timer = 1;
                if (timer_done) 
                    proximo_estado = check;
            end
            
            check: proximo_estado = fim_jogo;
            
            // --- Fim de Jogo ---
            fim_jogo: begin
                if (pts_jogador > 21)
                    lose = 1;
                else if (pts_dealer > 21)
                    win = 1;
                else if (pts_jogador > pts_dealer)
                    win = 1;
                else if (pts_dealer > pts_jogador)
                    lose = 1;
                else
                    tie = 1;
            end
            
            default: proximo_estado = inicio;
        endcase
    end
endmodule