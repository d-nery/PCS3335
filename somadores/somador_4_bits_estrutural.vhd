-- somador_4_bits_estrutural
library ieee;
use ieee.std_logic_1164.all;

entity somador_4_bits_estrutural is
	port(
		A, B: in  std_logic_vector(3 downto 0);
		c0:   in  std_logic;
		S:    out std_logic_vector(3 downto 0);
		c4:   out std_logic
	);
end somador_4_bits_estrutural;

architecture s4b_estrutural_arch of somador_4_bits_estrutural is
	signal vai_um: std_logic_vector(0 to 2);

	component somador_1_bit is
		port (
			a, b: in  std_logic;
			cin:  in  std_logic;
			s:    out std_logic;
			cout: out std_logic
		);
	end component;

begin
	S1: somador_1_bit port map (
		a    => A(0),
		b    => B(0),
		cin  => c0,
		s    => S(0),
		cout => vai_um(0)
	);

	S2: somador_1_bit port map (
		a    => A(1),
		b    => B(1),
		cin  => vai_um(0),
		s    => S(1),
		cout => vai_um(1)
	);

	S3: somador_1_bit port map (
		a    => A(2),
		b    => B(2),
		cin  => vai_um(1),
		s    => S(2),
		cout => vai_um(2)
	);

	S4: somador_1_bit port map (
		a    => A(3),
		b    => B(3),
		cin  => vai_um(2),
		s    => S(3),
		cout => c4
	);

end s4b_estrutural_arch;
