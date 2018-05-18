-- somador_1_bit
lIbrary ieee;
use ieee.std_logic_1164.all;

entity somador_1_bit is
	port (
		a, b: in  std_logic;
		cin:  in  std_logic;
		s:    out std_logic;
		cout: out std_logic
	);
end somador_1_bit;

architecture somador_1_bit_arch of somador_1_bit is
begin
	s    <= a xor b xor cin;
	cout <= (a and b) or (a and cin) or (b and cin);
end somador_1_bit_arch;
