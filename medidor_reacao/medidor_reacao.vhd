-- medidor_reacao.vhd

library IEEE;
use IEEE.std_logic_1164.all;

entity medidor_reacao is
	port (
		clock, reset, medir, pulso: in std_logic;
		pronto, vai1, rco: out std_logic;
		medida, somador, pontuacao: out std_logic_vector(15 downto 0);
		estado: out std_logic_vector(3 downto 0)
	);
end medidor_reacao;

architecture medidor_reacao_arch of medidor_reacao is
	signal s_resetc, s_enablec, s_enable_r1, s_reset_r1, s_enable_r2, s_reset_r2: std_logic;
	signal s_rco1, s_rco2, s_rco3: std_logic;
	signal s_vai1, s_vai2, s_vai3: std_logic;
	signal s_contagem1, s_contagem2, s_contagem3, s_contagem4: std_logic_vector(3 downto 0);
	signal s_soma1, s_soma2, s_soma3, s_soma4: std_logic_vector(3 downto 0);
	signal s_r1, s_r2: std_logic_vector(15 downto 0);

	component controlador is
		port (
			clock, reset, liga, sinal: in std_logic;
			enablec, resetc, enable_r1, reset_r1, enable_r2, reset_r2, pronto: out std_logic;
        	estado: out std_logic_vector(3 downto 0)
		);
	end component;

	component V74x162 is
		port (
			CLK, CLR_L, LD_L, ENP, ENT: in std_logic;
			D:   in std_logic_vector(3 downto 0);
			Q:   out std_logic_vector(3 downto 0);
			RCO: out std_logic
		);
	end component;

	component registrador16b is
		port (
			clock, clr, enable: in std_logic;
        	D: in std_logic_vector(15 downto 0);
        	Q: out std_logic_vector (15 downto 0)
		);
	end component;

	component somador_decimal is
		port (
			A,B:    in  std_logic_vector(3 downto 0);
			vem_um: in  std_logic;
			S:      out std_logic_vector(3 downto 0);
			vai_um: out std_logic
		);
	end component;

	component bcd_to_segment7 is
		port (
			bcd: in std_logic_vector(3 downto 0);
			segment7: out std_logic_vector(6 downto 0)
		);
	end component;

begin
	s1:  controlador     port map (clock, reset, medir, pulso, s_enablec, s_resetc, s_enable_r1, s_reset_r1, s_enable_r2, s_reset_r2, pronto, estado);

	s2:  V74x162         port map (clock, not s_resetc, '1', s_enablec, s_enablec, "0000", s_contagem1, s_rco1);
	s3:  V74x162         port map (clock, not s_resetc, '1', s_enablec, s_rco1, "0000", s_contagem2, s_rco2);
	s4:  V74x162         port map (clock, not s_resetc, '1', s_enablec, s_rco2, "0000", s_contagem3, s_rco3);
	s5:  V74x162         port map (clock, not s_resetc, '1', s_enablec, s_rco3, "0000", s_contagem4, rco);

	s6:  registrador16b  port map (clock, s_reset_r1, s_enable_r1, s_contagem4 & s_contagem3 & s_contagem2 & s_contagem1, s_r1);
	s7:  registrador16b  port map (clock, s_reset_r2, s_enable_r2, s_soma4 & s_soma3 & s_soma2 & s_soma1, s_r2);

	s8:  somador_decimal port map (s_r1(3 downto 0), s_r2(3 downto 0), '0', s_soma1, s_vai1);
	s9:  somador_decimal port map (s_r1(7 downto 4), s_r2(7 downto 4), s_vai1, s_soma2, s_vai2);
	s10: somador_decimal port map (s_r1(11 downto 8), s_r2(11 downto 8), s_vai2, s_soma3, s_vai3);
	s11: somador_decimal port map (s_r1(15 downto 12), s_r2(15 downto 12), s_vai3, s_soma4, vai1);

	pontuacao <= s_r2;
	medida    <= s_r1;
	somador   <= s_soma4 & s_soma3 & s_soma2 & s_soma1;

end medidor_reacao_arch;
