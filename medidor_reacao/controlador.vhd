-- controlador.vhd
--     adaptacao de medidor_fsm.vhd
library IEEE;
use IEEE.std_logic_1164.all;

entity controlador is
	port (
		clock, reset, liga, sinal: in STD_LOGIC;
        enablec, resetc, enable_r1, reset_r1, enable_r2, reset_r2, pronto: out STD_LOGIC;
        estado: out STD_LOGIC_VECTOR(3 downto 0)
	);
end controlador;

architecture controlador_arch of controlador is
	type tipo_Estado is (INICIAL, LIGADO, CONTA, R1, R2, ESPERA, FIM);
	signal Ereg, Eprox: tipo_Estado;
begin

	process (clock, reset)
	begin
		if reset = '1' then
			Ereg <= INICIAL;
		elsif clock'event and clock = '1' then
			Ereg <= Eprox;
		end if;
	end process;

	process (LIGA, SINAL, Ereg)
	begin
		case Ereg is
			when INICIAL =>	if LIGA = '0' then 	Eprox <= INICIAL;
                            else				Eprox <= LIGADO;
							end if;
			when LIGADO => 	if SINAL = '0' then 	Eprox <= LIGADO;
							else					Eprox <= CONTA;
							end if;
			when CONTA  => 	if SINAL = '1' then 	Eprox <= CONTA;
							else					Eprox <= R1;
							end if;
			when R1 =>  	Eprox <= R2;
			when R2 =>  	Eprox <= FIM;
			when FIM =>     Eprox <= ESPERA;
			when ESPERA =>  if LIGA = '0' then      Eprox <= INICIAL;
                            elsif SINAL = '0' then 	Eprox <= ESPERA;
							else                    Eprox <= CONTA;
							end if;

			when others =>	Eprox <= INICIAL;
		end case;
	end process;

	-- sinais de controle ativos em alto
	with Ereg select
		enablec <= 	'1' when CONTA,
					'0' when others;

	with Ereg select
		resetc  <=  '1' when INICIAL | ESPERA,
					'0' when others;

	with Ereg select
		enable_r1 <= '1' when R1,
					 '0' when others;

	with Ereg select
		reset_r1  <= '1' when INICIAL,
					 '0' when others;

	with Ereg select
		enable_r2 <= '1' when R2,
					 '0' when others;

	-- Ver quando e necessario resetar o registrador 2
	with Ereg select
		reset_r2  <= '1' when INICIAL,
					 '0' when others;

    with Ereg select
        pronto <= '1' when FIM,
                  '0' when others;

    with Ereg select
		estado  <= 	"0000" when INICIAL,
		            "0001" when LIGADO,
					"0010" when CONTA,
					"0100" when R1,
					"1000" when R2,
					"1001" when FIM,
					"1010" when ESPERA,
					"1111" when others;
end controlador_arch;
