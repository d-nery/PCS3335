library ieee;
use ieee.std_logic_1164.all;


entity bcd_to_segment7_4digits is
	port (
		bcd: in std_logic_vector(15 downto 0);
		segment7: out std_logic_vector(27 downto 0)
	);
end bcd_to_segment7_4digits;

architecture arch of bcd_to_segment7_4digits is

	component bcd_to_segment7 is
		port (
			bcd: in std_logic_vector(3 downto 0);
			segment7: out std_logic_vector(6 downto 0)
		);
	end component;

begin
	U1: bcd_to_segment7 port map (bcd(3 downto 0),   segment7(6  downto 0));
	U2: bcd_to_segment7 port map (bcd(7 downto 4),   segment7(13 downto 7));
	U3: bcd_to_segment7 port map (bcd(11 downto 8),  segment7(20 downto 14));
	U4: bcd_to_segment7 port map (bcd(15 downto 12), segment7(27 downto 21));

end arch;
