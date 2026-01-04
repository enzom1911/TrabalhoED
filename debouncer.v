// debouncer.v
module debouncer(clock,reset,botao_in,out);
	input clock,reset,botao_in;
	output reg out;
	
	// Clock da placa = 50MHz, Periodo de 20ns, se fizermos o sinal se manter por 10ms, precisaremos de 500.000 ciclos
	// Na simulação, este valor será sobrescrito para algo pequeno (ex: 5)
	parameter limit_timer = 20'd500000;
	reg [19:0] contador;
	reg sync_0,sync_1;
	reg estado_estavel;
	reg estado_antigo;
	
	always @(posedge clock) begin
		sync_0 <= botao_in;
		sync_1 <= sync_0;
	end
	
	always @(posedge clock, posedge reset) begin
		if (reset) begin
			contador <= 0;
			estado_estavel <= 0;
		end
		else begin
			if (sync_1 != estado_estavel) begin
				if (contador >= limit_timer) begin
					estado_estavel <= sync_1;
					contador <= 0;
				end
				else begin
					contador <= contador +1;
				end
			end
			else begin 
				contador <= 0;
			end
		end
	end
	
	always @(posedge clock, posedge reset) begin
		if (reset) begin 
			out <=0;
			estado_antigo <=0;
		end
		else begin
			estado_antigo <= estado_estavel;
			if (estado_estavel == 1 && estado_antigo == 0)
				out <= 1;
			else 
				out <= 0;
		end
	end
endmodule
		
			
		
	
	
	

