-- interface_sp.vhd
--   Faz a interface do medidor de reacao com
--   LEDs e botões. Implementa o modo:
--   - Single Player: Conta o tempo de reacao de um jogador ao estimulo

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity interface_sp is
	port (
		clock, reset, iniciar, resposta: in  std_logic;
		ligado, estimulo, pulso, erro:   out std_logic;

		-- Vai1
		-- checa se o medidor de reacao de overflow
		ovf: in std_logic;
		-- Sinaliza para o controle que vai para a proxima rodada
		proximo: out std_logic;
		-- Estado atual
		estado: out std_logic_vector(3 downto 0)
	);
end interface_sp;

architecture behaviour of interface_sp is
	-- Estados da máquina
	type estado_t is ( INICIO, ESPERA_ESTIMULO, ESPERA_RESPOSTA, ERR, SALVA_PONTOS );

	-- Sinais internos e variaveis de contagem de ciclos
	signal e_reg, e_prox: estado_t := INICIO;
	signal counting: std_logic := '0';
	shared variable cycles: integer := 0;

	signal o_ready, o_valid: std_logic;
	signal o_data1: std_logic_vector(31 downto 0);
	signal o_data2: integer;

	signal count_to: integer := 11000;
	-- signal s_num_jogado: std_logic_vector := "0000";

	-- Random Number Generator
	component rng_trivium is
		generic (
			num_bits:  integer range 1 to 64;
			init_key:  std_logic_vector(79 downto 0);
			init_iv:   std_logic_vector(79 downto 0)
		);

		port (
			clk:       in  std_logic;
			rst:       in  std_logic;
			reseed:    in  std_logic;
			newkey:    in  std_logic_vector(79 downto 0);
			newiv:     in  std_logic_vector(79 downto 0);
			out_ready: in  std_logic;
			out_valid: out std_logic;
			out_data:  out std_logic_vector(num_bits-1 downto 0)
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
		end if;
	end process; -- cycle

	-- Processo de mudança de estados, ativado sempre que o estado atual muda
	-- ou por mudança das entradas iniciar e resposta
	check_state: process (iniciar, resposta, e_reg) begin
		case e_reg is
			-- Estado inicial
			when INICIO =>
				if iniciar = '1'  then e_prox <= ESPERA_ESTIMULO;
				else                   e_prox <= INICIO;
				end if;
			-- Espera estimulo
			when ESPERA_ESTIMULO =>
				if resposta = '1'        then e_prox <= ERR;              -- Gera erro se resposta for ativado nesse estado
				elsif cycles >= count_to then e_prox <= ESPERA_RESPOSTA;  -- Espera numero aleatorio de ciclos de clock
				else                          e_prox <= ESPERA_ESTIMULO;  -- Mantem nesse estado caso nao tenha chegado nos ciclos
				end if;
			-- Espera reação do usuario
			when ESPERA_RESPOSTA =>
				if ovf = '1'         then e_prox <= ERR;              -- Demorou muito para reagir, perdeu
				elsif resposta = '1' then e_prox <= SALVA_PONTOS;     -- Quando o usuario apertar o botão, muda para o salvamento de pontos
				else                      e_prox <= ESPERA_RESPOSTA;  -- Enquanto isso nao acontece, mantem nesse estado
				end if;
			when ERR =>
				e_prox <= ERR; -- Perdeu, necessario reset
			when SALVA_PONTOS =>
				if ovf = '1'         then e_prox <= ERR;
				elsif iniciar = '1'  then e_prox <= ESPERA_ESTIMULO; -- Esta salvando os pontos, espera o botao de inicio ser pressionado para contar novamente
				else                      e_prox <= SALVA_PONTOS;
				end if;
			when others =>
				e_prox <= INICIO; -- estado desconhecido, volta para o estado inicial
		end case;
	end process; -- check_state

	-- Pinos sao modificados de acordo com o estado atual
	with e_reg select
		proximo <= '1' when SALVA_PONTOS,
				'0' when others;

	with e_reg select
		counting <= '1' when ESPERA_ESTIMULO, -- E necessario contar os ciclos de clock somente enquanto nao ha estimulo
				'0' when others;

	with e_reg select
		estimulo <= '1' when ESPERA_RESPOSTA, -- Acende o LED de estimulo enquanto o jogador nao aperta o botao
				'0' when others;

	with e_reg select
		pulso <= not resposta when ESPERA_RESPOSTA, -- Manda pulso pro medidor de tempo de reação enqauanto resposta
				'0' when others;                    -- não e ativado, para de enviar assincronamente

	with e_reg select
		ligado <= '0' when INICIO, -- A maquina esta ligada em qualquer estado que nao o inicial
				'1' when others;

	with e_reg select
		erro  <= '1' when ERR,       -- Acende o led de erro enquanto estiver nesse estado
				'0' when others;

	with e_reg select
		count_to <= o_data2 when SALVA_PONTOS | INICIO,
				count_to when others;


	with e_reg select -- Mostra o estado em que a maquina se encontra
		estado <=
				"0000" when INICIO,
				"0001" when ESPERA_ESTIMULO,
				"0010" when ESPERA_RESPOSTA,
				"0011" when ERR,
				"0100" when SALVA_PONTOS,
				"1111" when others;

	-- Tempo de reacao varia de 3000 a 10000
	o_data2 <= ((to_integer(unsigned(o_data1)) mod 7000) + 3000) when o_valid = '1' else 3000;

end behaviour;
