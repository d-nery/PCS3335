-- v74x162.vhd
--     componente similar ao contador integrado 74162
-- LabDig - 2017
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity V74x162 is
    port (
        CLK, CLR_L, LD_L, ENP, ENT: in STD_LOGIC;
        D: in STD_LOGIC_VECTOR (3 downto 0);
        Q: out STD_LOGIC_VECTOR (3 downto 0);
        RCO: out STD_LOGIC
    );
end V74x162;

architecture V74x162_arch of V74x162 is
  signal IQ: UNSIGNED (3 downto 0);
begin
process (CLK, ENT, IQ)
  begin
    if CLK'event and CLK='1' then
      if CLR_L='0' then IQ <= (others => '0');
      elsif LD_L='0' then IQ <= unsigned(D);
      elsif (ENT and ENP)='1' then
        if IQ >= 9 then IQ<=(others => '0');
        else IQ <= IQ + 1;
		end if;
      end if;
    end if;
    if (IQ=9) and (ENT='1') then RCO <= '1';
    else RCO <= '0';
    end if;
    Q <= std_logic_vector(IQ);
  end process;
end V74x162_arch;
