
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
	reg [3:0] valor; // Valor verdadeiro da carta
	reg check_jog, check_dealer;
	

	always @(*) begin
		if (carta >= 10) 
			valor = 10;
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
				estado_futuro = fim;
			end
		endcase
	end

	// Always Sequencial em que estado atual recebe estado futuro e a pontuação e as flags são atualizadas

	always @(posedge clock,posedge reset) begin
		if (reset) begin
			temJQK_jog <= 0;
			temJQK_dealer <= 0; 
			temAS_jog <= 0;
			temAS_dealer <= 0;
			endereco <= 0;
			pts_jogador <=0;
			pts_dealer <=0;
			cartaok <=0;
			check_jog <= 0;
			check_dealer <= 0;
		end
		else begin
			estado_atual <= estado_futuro;
			case (estado_atual)
				inicio: begin
					cartaok <= 0;
				end
				verifica_carta: begin
					if (pjogador) begin
						if (carta == 1)
							temAS_jog <= 1;
						else if (carta >=11 && carta <=13)
							temJQK_jog <= 1;
					end
					else if (pdealer) begin
						if (carta == 1) 
							temAS_dealer <= 1;
						else if (carta >=11 && carta <=13)
							temJQK_dealer <= 1;
					end
				end
				soma: begin
					if (pjogador)
						pts_jogador <= pts_jogador + valor;
					else if (pdealer)
						pts_dealer <= pts_dealer + valor;
				end
				check: begin
					if (pjogador) begin
						if (temAS_jog && temJQK_jog && !check_jog)
							pts_jogador <= pts_jogador + 10;
							check_jog <=1;
					end
					else if (pts_dealer) begin
						if (temAS_dealer && temJQK_dealer && !check_dealer)
							pts_dealer <= pts_dealer + 10;
							check_dealer <=1;
					end
				end
				fim: begin
					cartaok <= 1;
					endereco <= endereco + 1;
				end
			endcase
		end	
	end
endmodule



