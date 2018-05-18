-- controle.vhd
--    Maquina de estados que controla o modo single player
--    Controla a interface e o medidor de reacao

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity controle is
	port (
		clock, reset: in std_logic;
		start: in std_logic;

		num_jogada: out std_logic_vector(3 downto 0);

		proximo: in std_logic;
		iniciar: out std_logic;
		reset_int: out std_logic;
		erro: in std_logic;

		pronto: in std_logic;
		reset_med: out std_logic
	);
end controle;

architecture controle_arch of controle is
	type estado_t is ( INICIO, ESPERA, INICIA_JOGO, JOGO, ERR, SALVA, PROX_JOGADA, GG_EZ );

	signal e_reg, e_prox: estado_t := INICIO;
	signal s_n_jogadas: unsigned(3 downto 0) := "0001";

begin

	cycle: process (clock, reset) begin
		-- Se reset for 1, volta a maquina assincronamente para o estado inicial
		if reset = '1' then
			e_reg <= INICIO;
			s_n_jogadas <= "0001";
		-- Caso contrario coloca a maquina no proximo estado
		elsif rising_edge(clock) then
			e_reg <= e_prox;

			-- Incrementa o numero da jogada atual (somente uma vez)
			-- Volta para 0 quando chega em 5
			if e_reg = PROX_JOGADA then
				-- jogada = (jogada + 1) % 5
				s_n_jogadas <= ((s_n_jogadas + 1) mod 5);
			elsif e_reg = INICIO then
				s_n_jogadas <= "0001";
			end if;
		end if;
	end process; -- cycle

	check_state: process (start, erro, e_reg, proximo) begin
		case e_reg is
			when INICIO =>
				if start = '1'  then e_prox <= ESPERA; -- Espera o botao de inicio
				else                 e_prox <= INICIO;
				end if;
			when ESPERA =>
				if start = '1'  then e_prox <= INICIA_JOGO; -- Espera o botao de inicio
				else                 e_prox <= ESPERA;
				end if;
			when INICIA_JOGO =>
				e_prox <= JOGO;
			when JOGO =>
				if erro = '1'         then e_prox <= ERR;
				elsif s_n_jogadas = 0 then e_prox <= GG_EZ; -- Ja realizou todas as jogadas, vai pro estado de fim de jogo
				elsif proximo = '1'   then e_prox <= SALVA;
				else 				       e_prox <= JOGO;
				end if;
			when ERR =>
				e_prox <= ERR; -- Perdeu, tem que apertar o reset
			when SALVA =>
				if erro = '1'      then e_prox <= ERR;
				elsif pronto = '1' then e_prox <= PROX_JOGADA;
				else                    e_prox <= SALVA;
				end if;
			when GG_EZ =>
				if start = '1' then e_prox <= INICIO; -- Espera o botao de inicio para comecar novamente
				else                e_prox <= GG_EZ;
				end if;
			when PROX_JOGADA =>
				e_prox <= ESPERA; -- Dura um clock, para incrementar o numero de jogadas
			when others =>
				e_prox <= INICIO; -- estado desconhecido, volta para o estado inicial
		end case;
	end process; -- check_state

	with e_reg select
		iniciar <= '1' when INICIA_JOGO, -- Inicio fica em alto por um pulso de clock para iniciar a interface
				'0' when others;

	with e_reg select
		reset_int <= '1' when INICIO, -- Reseta a interface e o medidor quando em inicio
				'0' when others;

	with e_reg select
		reset_med <= '1' when INICIO,
				'0' when others;

	num_jogada <= std_logic_vector(s_n_jogadas);
end controle_arch;
