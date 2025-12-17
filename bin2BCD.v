/* Conversor de binário para BCD
	bin2BCD.v
	*/

module bin2BCD(binary,Dezenas,Unidades);
	input [5:0] binary;
	output reg [3:0] Dezenas,Unidades; 
	integer i;
	always @* begin
		Dezenas = 4'b0000;
		Unidades = 4'b0000;
		// For inicia em 7 pois o primeiro bit a entrar no processo de conversão é o MSB(bit mais significativo) do dado a ser convertido
		for (i=5;i>=0;i=i-1) begin 
			// Caso cada casa for maior ou igual a cinco, soma+3
			if (Dezenas >= 5) Dezenas = Dezenas + 3;
			if (Unidades >= 5) Unidades = Unidades + 3;
			Dezenas = Dezenas << 1;
			Dezenas[0] = Unidades[3]; // O LSB agora é o MSB das Unidades
			Unidades = Unidades << 1;
			Unidades[0] = binary[i]; // O LSB agora é o bit da vez
		end
	end
endmodule
