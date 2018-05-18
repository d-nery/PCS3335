-- registrador4b
--    registrador de 4 bits com enable e clear sincrono
--
-- baseado em Vreg16.vhd - Wakerly DDPP 4e

library IEEE;
use IEEE.std_logic_1164.all;

entity registrador4b is
	port (
		clock, clr, enable: in std_logic;
		D: in std_logic_vector(3 downto 0);
		Q: out std_logic_vector(3 downto 0)
	);
end registrador4b;

architecture registrador4b_arch of registrador4b is
begin
	process (clock) begin
		if rising_edge(clock) then
			if clr = '1'      then Q <= (others => '0');
			elsif enable ='1' then Q <= D;
			end if;
		end if;
	end process;
end registrador4b_arch;

