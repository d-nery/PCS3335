-- registrador16b
--    registrador de 16 bits com enable e clear sincrono
--
-- baseado em Vreg16.vhd - Wakerly DDPP 4e

library IEEE;
use IEEE.std_logic_1164.all;

entity registrador16b is
	port (
		clock, clr, enable: in std_logic;
		D: in std_logic_vector(15 downto 0);
		Q: out std_logic_vector(15 downto 0)
	);
end registrador16b;

architecture registrador16b_arch of registrador16b is
begin
	process (clock) begin
		if rising_edge(clock) then
			if clr = '1'      then Q <= (others => '0');
			elsif enable ='1' then Q <= D;
			end if;
		end if;
	end process;
end registrador16b_arch;

