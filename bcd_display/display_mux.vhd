-- display_mux.vhd
--     Alterna entre as entradas quando btn e apertado

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity display_mux is
	port (
		-- Botao que alterna entre as entradas
		btn:      in  std_logic;

		-- Entrada dos 6 digitos
		entrada1: in  std_logic_vector(41 downto 0);
		entrada2: in  std_logic_vector(41 downto 0);
		entrada3: in  std_logic_vector(41 downto 0);
		entrada4: in  std_logic_vector(41 downto 0);

		-- Saida 6 displays
		-- HEX0: 6 downto 0
		-- HEX1: 13 downto 7
		-- HEX2: 20 downto 14
		-- HEX3: 27 downto 21
		-- HEX4: 34 downto 28
		-- HEX5: 41 downto 32
		saida_d: out std_logic_vector(41 downto 0)
	);
end display_mux;

architecture display_mux_arch of display_mux is
	signal selecao_display: std_logic_vector(1 downto 0) := "00";

begin
	process (btn) begin
		if btn = '1' then
			selecao_display <= selecao_display + 1;
		end if;
	end process;

	with selecao_display select
		saida_d <=
			entrada1 when "00",
			entrada2 when "01",
			entrada3 when "10",
			entrada4 when "11",
			(others => '1') when others;

end display_mux_arch;
