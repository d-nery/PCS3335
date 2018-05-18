-- Somador Decimal
--     Realiza a soma decimal de dois dígitos BCD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity somador_decimal is
	port (
		A, B:     in  std_logic_vector(3 downto 0);
		vem_um:   in  std_logic;
		S:        out std_logic_vector(3 downto 0);
		vai_um:   out std_logic
	);
end somador_decimal;

architecture somador_decimal_arch of somador_decimal is
	-- Sinais internos para os componentes
	signal s_soma:    std_logic_vector(3 downto 0);
	signal S1:        std_logic_vector(3 downto 0);
	signal s_cout:    std_logic;
	signal s_corrige: std_logic;

	component somador_4_bits_estrutural is
		port (
			A, B: in  std_logic_vector(3 downto 0);
			c0:   in  std_logic;
			S:    out std_logic_vector(3 downto 0);
			c4:   out std_logic
		);
	end component;

	component gera_vai_um is
		port (
			soma:   in  std_logic_vector(3 downto 0);
			cout:   in  std_logic;
			vai_um: out std_logic
		);
	end component;

	component soma6 is
		port (
			entrada: in std_logic_vector(3 downto 0);
			corrige: in  std_logic;
			saida:   out std_logic_vector(3 downto 0)
		);
	end component;

	begin
		step1: somador_4_bits_estrutural port map (
			A  => A,
			B  => B,
			c0 => vem_um,
			S  => s_soma,
			c4 => s_cout
		);

		step2: gera_vai_um port map (
			soma   => s_soma,
			cout   => s_cout,
			vai_um => s_corrige
		);

		step3: soma6 port map (
			entrada => s_soma,
			corrige => s_corrige,
			saida   => S1
		);

		S <= S1;
		vai_um <= s_corrige;

end somador_decimal_arch;
