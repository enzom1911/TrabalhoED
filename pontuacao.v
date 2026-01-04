
// Módulo para o cálculo da pontuação a partir da carta recebida seja pelo jogador ou pelo dealer 
module pontuacao(clock,reset,carta,endereco,pjogador,pdealer,pts_jogador,pts_dealer,cartaok);
	input clock,reset,pjogador,pdealer;
	input [3:0] carta; // A carta pode ter um valor entre 0 e 13, sendo que 11,12 e 13 representam JQK
	output reg [5:0] pts_jogador, pts_dealer;
	output reg cartaok;
	output reg [5:0] endereco;

	// Definição dos estados
	parameter inicio = 4'b0000,
				 ler_carta = 4'b0001,
				 espera = 4'b0010,
				 verifica_carta = 4'b0011,
				 soma = 4'b0100,
				 check = 4'b0101,
				 fim=4'b0110;

	reg [3:0] estado_atual, estado_futuro;
	reg temJQK_jog, temJQK_dealer, temAS_jog,temAS_dealer;

	reg as_contabilizado_jog, as_contabilizado_dealer; //Estava faltando essa linha e deu erro de compilação no ModelSim
	reg [3:0] valor; // Valor verdadeiro da carta
	reg check_jog, check_dealer;
	

	always @(*) begin
		if (carta >= 10) 
			valor = 10; // J, Q, K valem 10
		else if (carta == 1)
			valor = 1; // Ás começa valendo 1
		else
			valor = carta;
	end

				 
	// Always combinacional para definir o estado futuro
	always @(*) begin
		estado_futuro = estado_atual;
		case (estado_atual)
			inicio: begin
				if (pjogador || pdealer)
					estado_futuro = ler_carta;
			end
			ler_carta: begin
				estado_futuro = espera;
			end
			espera: begin
				estado_futuro = verifica_carta;
			end
			verifica_carta: begin
				estado_futuro = soma;
			end
			soma: begin
				estado_futuro = check;
			end
			check: begin
				estado_futuro = fim;
			end
			fim: begin
				if (!pjogador && !pdealer)
				estado_futuro = inicio;
			else
				estado_futuro = fim;
			end
		endcase
	end

	// Always Sequencial em que estado atual recebe estado futuro e a pontuação e as flags são atualizadas

	always @(posedge clock,posedge reset) begin
		if (reset) begin
			temAS_jog <= 0;
            temAS_dealer <= 0;
            as_contabilizado_jog <= 0;
            as_contabilizado_dealer <= 0;
            endereco <= 0;
            pts_jogador <= 0;
            pts_dealer <= 0;
            cartaok <= 0;
            estado_atual <= inicio;
		end
		else begin
			estado_atual <= estado_futuro;
			case (estado_atual)
                inicio: begin
                    cartaok <= 0;
                end

                verifica_carta: begin
                    if (pjogador && carta == 1) temAS_jog <= 1;
                    if (pdealer && carta == 1) temAS_dealer <= 1;
                end

                soma: begin
                    // Soma o valor base (Ás vale 1 aqui)
                    if (pjogador) pts_jogador <= pts_jogador + valor;
                    else if (pdealer) pts_dealer <= pts_dealer + valor;
                end

                check: begin
                    // Lógica CORRETA do Ás: Se tem Ás e somar 10 não estoura 21, some 10.
                    if (pjogador) begin
                        if (temAS_jog && !as_contabilizado_jog && (pts_jogador + 10 <= 21)) begin
                            pts_jogador <= pts_jogador + 10;
                            as_contabilizado_jog <= 1; // Marca que já usamos o bônus do Ás
                        end
                    end
                    else if (pdealer) begin // CORRIGIDO: pdealer em vez de pts_dealer
                        if (temAS_dealer && !as_contabilizado_dealer && (pts_dealer + 10 <= 21)) begin
                            pts_dealer <= pts_dealer + 10;
                            as_contabilizado_dealer <= 1;
                        end
                    end
                end

                fim: begin
                    cartaok <= 1;
                    // Incrementa endereço APENAS UMA VEZ ao entrar no estado FIM
                    if (estado_atual != fim) begin 
                         endereco <= endereco + 1;
                    end
                end
            endcase
        end    
    end
endmodule
