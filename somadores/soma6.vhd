-- Soma6
-- Faz a correção posterior de 6 na entrada se corrige = 1
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity soma6 is
	port (
		entrada: in  std_logic_vector(3 downto 0);
		corrige: in  std_logic;
		saida:   out std_logic_vector(3 downto 0)
	);
end soma6;

architecture soma6_arch of soma6 is
	begin
		-- Soma 6 na saida caso corrige seja 1
		saida <= entrada when corrige = '0' else entrada + 6;
end soma6_arch;
