-- Gera Vai Um
-- Modulo para gerar o 'vai-um' e correcao posterior de 6
-- se necessario
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity gera_vai_um is
	port (
		soma:   in  std_logic_vector(3 downto 0);
		cout:   in  std_logic;
		vai_um: out std_logic
	);
end gera_vai_um;

architecture gera_vai_um_arch of gera_vai_um is
	-- Sinal que checa se recebeu um numero decimal de um digito
	signal x: std_logic;

	begin
		-- Se recebeu um digito maior que 9 deve gerar o vai um
		-- ou se cout for 1
		x      <= '1' when soma > 9 else '0';
		vai_um <= x or cout;
end gera_vai_um_arch;
