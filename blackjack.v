// módulo da máquina principal onde vamos definir os diferentes estados do jogo e a transição entre eles

module blackjack(embaralhar_ok,clock,reset,hit,stay,cartaok,pts_jogador,pts_dealer,pjogador,pdealer,player_hit,player_stay,dealer_hit,dealer_stay,win,lose,tie);
	input clock,reset,hit,stay,cartaok,embaralhar_ok;
	input [5:0] pts_jogador,pts_dealer;
	output reg pjogador,pdealer,player_hit,dealer_hit,player_stay,dealer_stay,win,lose,tie;
	parameter inicio = 5'b00000,
				 embaralhar =5'b00001,
				 carta1_jogador = 5'b00010,
				 wait1_jogador = 5'b00011,
				 carta1_dealer = 5'b00100,
				 wait1_dealer = 5'b00101, 
				 carta2_jogador = 5'b00110,
				 wait2_jogador = 5'b00111,
				 carta2_dealer = 5'b01000,
				 wait2_dealer = 5'b01001,
				 vez_jogador = 5'b01010,
				 hit_jogador = 5'b01011,
				 wait_jogador = 5'b01100,
				 stay_jogador = 5'b01101,
				 vez_dealer = 5'b01110,
				 hit_dealer = 5'b01111,
				 wait_dealer = 5'b10000,
				 stay_dealer = 5'b10001,
				 check = 5'b10010,
				 fim_jogo= 5'b10011;
	
	reg [4:0] estado_atual,proximo_estado;
	
	// Temporizador: Precisamos que as saídas que indicam as ações do jogador ou do dealer durem 2 seg
	// Clock da placa = 50MHZ, então um pulso de clock dura 2x10^-8 s
	// Então precisamos manter o sinal por 10^8 pulsos, que pra representar requer 27 bits
	reg [26:0] contador_tempo;
	reg ativar_timer;
	assign timer = (contador_tempo >= 100000000);
	
	always@(posedge clock, posedge reset) begin
		if (reset) begin
			estado_atual <= inicio;
			contador_tempo <=0;
		end
		else begin
			estado_atual <= proximo_estado;
			if (ativar_timer) begin
				if (!timer)
					contador_tempo <= contador_tempo + 1;
				else
					contador_tempo<=0;
			end
			else begin
				contador_tempo <=0;
			end
		end
	end
	
	always@(*) begin
		//Valores default
		proximo_estado = estado_atual;
		pjogador = 0;
		pdealer = 0;
		ativar_timer = 0;
		player_hit = 0;
		player_stay = 0;
		dealer_stay =0;
		dealer_hit = 0;
		win=0;
		lose=0;
		tie=0;
		
		case(estado_atual)
			inicio: begin
				proximo_estado = embaralhar;
			end
			embaralhar:begin
				if (embaralhar_ok)
					proximo_estado = carta1_jogador;
			end
			carta1_jogador: begin
				pjogador = 1;
				if (cartaok)
					proximo_estado = wait1_jogador;
			end
			wait1_jogador: begin
				if (!cartaok)
					proximo_estado = carta1_dealer;
			end
			carta1_dealer: begin
				pdealer = 1;
				if (cartaok)
					proximo_estado = wait1_dealer;
			end
			wait1_dealer: begin
				if (!cartaok) 
					proximo_estado = carta2_jogador;
			end
			carta2_jogador: begin
				pjogador=1;
				if (cartaok)
					proximo_estado = wait2_jogador;
			end
			wait2_jogador: begin
				if (!cartaok)
					proximo_estado = carta2_dealer;
			end
			carta2_dealer:begin
				pdealer=1;
				if(cartaok)
					proximo_estado = wait2_dealer;
			end
			wait2_dealer:begin
				if (!cartaok)
					proximo_estado = vez_jogador;
			end
			
			vez_jogador:begin
				if (pts_jogador > 21)
					proximo_estado = fim_jogo;
				else if (pts_jogador == 21)
					proximo_estado = vez_dealer;
				else begin
					if (hit)
						proximo_estado = hit_jogador;
					else if (stay)
						proximo_estado = stay_jogador;
				end
			end
			
			hit_jogador: begin 
				player_hit = 1;
				ativar_timer=1;
				if (timer) begin
					pjogador= 1;
					if (cartaok)
						proximo_estado = wait_jogador;
				end
			end
			
			wait_jogador: begin
				if(!cartaok)
					proximo_estado = vez_jogador;
			end
			
			stay_jogador:begin
				player_stay =1;
				ativar_timer=1;
				if (timer) 
					proximo_estado = vez_dealer;
			end
			
			vez_dealer: begin
				if (pts_dealer>21)
					proximo_estado = fim_jogo;
				else if (pts_dealer >= 17)
					proximo_estado = stay_dealer;
				else
					proximo_estado = hit_dealer;
			end
			
			hit_dealer: begin
				dealer_hit = 1;
				ativar_timer = 1;
				if (timer) begin
					pdealer =1;
					if (cartaok)
						proximo_estado = wait_dealer;
				end
			end
			
			wait_dealer: begin
				if(!cartaok)
					proximo_estado = vez_dealer;
			end
			
			stay_dealer: begin
				dealer_stay =1;
				ativar_timer=1;
				if (timer) 
					proximo_estado = check;
			end
			
			check: proximo_estado = fim_jogo;
			
			fim_jogo: begin
				if (pts_jogador>21)
					lose =1;
				else if (pts_dealer>21)
					win=1;
				else if (pts_jogador > pts_dealer)
					win=1;
				else if (pts_dealer >pts_jogador)
					lose = 1;
				else
					tie =1;
			end
			default: proximo_estado =inicio;
		endcase
	end
endmodule
