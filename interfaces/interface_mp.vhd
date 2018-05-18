-- interface_mp.vhd
--   Faz a interface do medidor de reacao com
--   LEDs e botões. Implementa o modo:
--   - Multi Player: Ve qual o jogador mais rapido

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity interface_mp is
	port (
		clock, reset: in std_logic;
		iniciar: in std_logic;

		resposta_j1, resposta_j2: in std_logic;
		certo_j1, certo_j2, erro_j1, erro_j2: out std_logic;

		estimulo: out std_logic;

		pontos1, pontos2: out std_logic_vector(3 downto 0);

		estado: out std_logic_vector(3 downto 0)
	);
end interface_mp;

architecture interface_mp_arch of interface_mp is
	-- Estados da maquina
	type estado_t is ( INICIO, ESPERA, ESPERA_ESTIMULO, ESPERA_RESPOSTA, ERR1, ERR2, OK1, OK2 );

	signal e_reg, e_prox: estado_t := INICIO;

	-- Variaveis para contagem de quantos ciclos de clock passaram
	-- usadas para o delay aleatorio antes do estimulo
	signal counting: std_logic := '0';
	shared variable cycles: integer := 0;

	signal o_ready, o_valid: std_logic;
	signal o_data1: std_logic_vector(31 downto 0);
	signal o_data2: integer;

	signal count_to: integer := 5;

	signal pontos_j1, pontos_j2: std_logic_vector(3 downto 0) := (others => '0');

	-- Random Number Generator
	component rng_trivium is
		generic (
			num_bits:   integer range 1 to 64;
			init_key:   std_logic_vector(79 downto 0);
			init_iv:    std_logic_vector(79 downto 0)
		);

		port (
			clk:        in  std_logic;
			rst:        in  std_logic;
			reseed:     in  std_logic;
			newkey:     in  std_logic_vector(79 downto 0);
			newiv:      in  std_logic_vector(79 downto 0);
			out_ready:  in  std_logic;
			out_valid:  out std_logic;
			out_data:   out std_logic_vector(num_bits-1 downto 0)
		);
	end component;

begin
	s1: rng_trivium generic map (
		num_bits => 32,
		init_key => x"0053A6F94C9FF24598EB",
		init_iv  => x"0D74DB42A91077DE45AC"
	) port map (
		clk => clock,
		rst => reset,
		reseed => '0',
		newkey => (others => '0'),
		newiv  => (others => '0'),
		out_ready => o_ready,
		out_valid => o_valid,
		out_data  => o_data1
	);


	-- Ciclos de clock, processo ativado com mudança de clock ou do pino reset
	cycle: process (clock, reset) begin
		-- Se reset for 1, volta a maquina assincronamente para o estado inicial
		if reset = '1' then
			e_reg <= INICIO;
		-- Caso contrario coloca a maquina no proximo estado
		elsif rising_edge(clock) then
			e_reg <= e_prox;
			-- Se estiver contando (estado ESPERA_ESTIMULO) soma um na quantidade de ciclos
			-- caso contrario zera
			if counting = '1' then
				cycles := cycles + 1;
			else
				cycles := 0;
			end if;

			if e_reg = INICIO then
				pontos_j1 <= (others => '0');
				pontos_j2 <= (others => '0');
			elsif e_reg = OK1 and pontos_j1 < "1001" then
				pontos_j1 <= pontos_j1 + 1;
			elsif e_reg = ERR1 and pontos_j1 > "0000" then
				pontos_j1 <= pontos_j1 - 1;
			elsif e_reg = OK2 and pontos_j2 < "1001" then
				pontos_j2 <= pontos_j2 + 1;
			elsif e_reg = ERR2 and pontos_j2 > "0000" then
				pontos_j2 <= pontos_j2 - 1;
			end if;

		end if;
	end process; -- cycle

	-- Processo de mudança de estados, ativado sempre que o estado atual muda
	-- ou por mudança das entradas iniciar e resposta
	check_state: process (iniciar, resposta_j1, resposta_j2, e_reg) begin
		case e_reg is
			-- Estado inicial
			when INICIO =>
				if   iniciar = '1' then e_prox <= ESPERA;
				else                    e_prox <= INICIO;
				end if;
			when ESPERA =>
				if   iniciar = '1' then e_prox <= ESPERA_ESTIMULO;
				else                    e_prox <= ESPERA;
				end if;
			-- Espera estimulo
			when ESPERA_ESTIMULO =>
				if    resposta_j1 = '1'  then e_prox <= ERR1;              -- Gera erro se resposta for ativado nesse estado
				elsif resposta_j2 = '1'  then e_prox <= ERR2;              -- Gera erro se resposta for ativado nesse estado
				elsif cycles >= count_to then e_prox <= ESPERA_RESPOSTA;  -- Espera 10 ciclos de clock (há 2 ciclos de atraso devido as mudanças de estado)
				else                          e_prox <= ESPERA_ESTIMULO;  -- Mantem nesse estado caso nao tenha chegado nos 10 ciclos
				end if;
			-- Espera reação do ususario
			when ESPERA_RESPOSTA =>
				if    resposta_j1 = '1' then e_prox <= OK1;
				elsif resposta_j2 = '1' then e_prox <= OK2;
				else                         e_prox <= ESPERA_RESPOSTA;  -- Enquanto isso nao acontece, mantem nesse estado
				end if;
			when ERR1 =>
				e_prox <= ESPERA;
			when ERR2 =>
				e_prox <= ESPERA;
			when OK1 =>
				e_prox <= ESPERA;
			when OK2 =>
				e_prox <= ESPERA;
			when others =>
				e_prox <= INICIO; -- estado desconhecido, volta para o estado inicial
		end case;
	end process; -- check_state

	with e_reg select
		counting <= '1' when ESPERA_ESTIMULO, -- E necessario contar os ciclos de clock somente enquanto nao ha estimulo
				'0' when others;

	with e_reg select
		estimulo <= '1' when ESPERA_RESPOSTA, -- Acende o LED de estimulo enquanto o jogador nao aperta o botao
				'0' when others;

	with e_reg select
		estado <= "0000" when INICIO, -- E necessario contar os ciclos de clock somente enquanto nao ha estimulo
				"0001" when ESPERA,
				"0010" when ESPERA_ESTIMULO,
				"0011" when ESPERA_RESPOSTA,
				"0100" when ERR1,
				"0101" when ERR2,
				"0110" when OK1,
				"0111" when OK2,
				"1111" when others;

	with e_reg select
		count_to <= o_data2 when ESPERA | INICIO,
				count_to when others;

	with e_reg select
		erro_j1 <= '1' when ERR1,
				'0' when others;

	with e_reg select
		erro_j2 <= '1' when ERR2,
				'0' when others;

	with e_reg select
		certo_j1 <= '1' when OK1,
				'0' when others;

	with e_reg select
		certo_j2 <= '1' when OK2,
				'0' when others;

	-- Tempo de reacao varia de 7000 a 3000
	o_data2 <= ((to_integer(unsigned(o_data1)) mod 7000) + 3000) when o_valid = '1' else 3000;

	pontos1 <= pontos_j1;
	pontos2 <= pontos_j2;

end interface_mp_arch;
