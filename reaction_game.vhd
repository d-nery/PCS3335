-- reaction_game.vhd
--   Entidade principal
--       Faz as ligacoes entre os diferentes modulos do jogo

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity reaction_game is
	port (
		-- sinal de clock e reset
		clock, reset: in std_logic;

		-- Botoes dos jogadores
		resposta_j1, resposta_j2: in std_logic;
		-- Outros botoes
		-- start -> iniciar
		-- selecao_display -> seleciona a saida do display
		start, selecao_display: in std_logic;

		-- Game type switch
		switch: in std_logic;
		-- Game type LED
		-- Acende ou apaga de acordo com o modo de jogo selecionado
		type_led: out std_logic;

		-- LEDs jogadores
		-- Sao iguais no modo single player
		erro_j1, erro_j2, acerto_j1, acerto_j2: out std_logic;
		-- LEDs jogo
		ligado, estimulo: out std_logic;

		-- Numero da jogada atual
		num_jogada:    out std_logic_vector(3 downto 0);

		-- 6 displays
		saida_display: out std_logic_vector(41 downto 0);

		-- saida de debug do pulso
		pulso: out std_logic
	);
end reaction_game;

architecture reaction_game_arch of reaction_game is
	-- numero atual da jogada
	signal n_jogada: std_logic_vector(3 downto 0);
	signal n_jogada_7: std_logic_vector(6 downto 0);

	-- sinais internos
	signal s_proximo: std_logic;
	signal s_init_sp: std_logic;
	signal s_reset_sp: std_logic;
	signal s_reset_med: std_logic;
	signal s_pronto: std_logic;
	signal s_rco: std_logic;
	signal s_vai1: std_logic;

	signal estimulo_mp, estimulo_sp: std_logic;
	signal pontos_j1_mp, pontos_j2_mp: std_logic_vector(3 downto 0);
	signal err_sp, err1_mp, err2_mp: std_logic;

	signal pulso_sp: std_logic;

	signal pontos: std_logic_vector(15 downto 0);
	signal ultima_medida: std_logic_vector(15 downto 0);

	signal pontos_7: std_logic_vector(41 downto 0) := (others => '1');
	signal ultima_medida_7: std_logic_vector(41 downto 0) := (others => '1');

	signal pontos_mp_7: std_logic_vector(41 downto 0) := (others => '1');

	component interface_mp is
		port (
			clock, reset: in std_logic;
			iniciar: in std_logic;
			resposta_j1, resposta_j2: in std_logic;
			certo_j1, certo_j2, erro_j1, erro_j2: out std_logic;
			estimulo: out std_logic;
			pontos1, pontos2: out std_logic_vector(3 downto 0);
			estado: out std_logic_vector(3 downto 0)
		);
	end component;

	component interface_sp is
		port (
			clock, reset, iniciar, resposta: in  std_logic;
			ligado, estimulo, pulso, erro:   out std_logic;
			ovf: in std_logic;

			proximo: out std_logic;
			estado: out std_logic_vector(3 downto 0)
		);
	end component;

	component medidor_reacao is
		port (
			clock, reset, medir, pulso: in std_logic;
			pronto, vai1, rco: out std_logic;
			medida, somador, pontuacao: out std_logic_vector(15 downto 0);
			estado: out std_logic_vector(3 downto 0)
		);
	end component;

	component display_mux is
		port (
			btn:      in  std_logic;
			entrada1: in  std_logic_vector(41 downto 0);
			entrada2: in  std_logic_vector(41 downto 0);
			entrada3: in  std_logic_vector(41 downto 0);
			entrada4: in  std_logic_vector(41 downto 0);
			saida_d:  out std_logic_vector(41 downto 0)
		);
	end component;

	component controle is
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
	end component;

	component bcd_to_segment7 is
		port (
			bcd: in std_logic_vector(3 downto 0);
			segment7: out std_logic_vector(6 downto 0)
		);
	end component;

	component bcd_to_segment7_4digits is
		port (
			bcd: in std_logic_vector(15 downto 0);
			segment7: out std_logic_vector(27 downto 0)
		);
	end component;

begin
	U0: controle port map (
		clock => clock,
		reset => reset,
		start => start,

		num_jogada => n_jogada,

		proximo   => s_proximo,
		iniciar   => s_init_sp,
		reset_int => s_reset_sp,
		erro      => err_sp,

		pronto    => s_pronto,
		reset_med => s_reset_med
	);

	U1: interface_mp port map (
		clock       => clock,
		reset       => reset or switch,
		iniciar     => start,
		resposta_j1 => resposta_j1,
		resposta_j2 => resposta_j2,
		certo_j1    => acerto_j1,
		certo_j2    => acerto_j2,
		erro_j1     => err1_mp,
		erro_j2     => err2_mp,
		estimulo    => estimulo_mp,
		pontos1     => pontos_j1_mp,
		pontos2     => pontos_j2_mp,
		estado      => open
	);

	U2: interface_sp port map (
		clock    => clock,
		reset    => reset or (not switch) or s_reset_sp,
		iniciar  => s_init_sp,
		resposta => resposta_j1 or resposta_j2,
 		ligado   => ligado,
		ovf      => s_rco or s_vai1,
		estimulo => estimulo_sp,
		pulso    => pulso_sp,
		erro     => err_sp,
		proximo  => s_proximo,
		estado   => open
	);

	U3: medidor_reacao port map (
		clock     => clock,
		reset     => reset or (not switch) or s_reset_med,
		medir     => '1',
		pulso     => pulso_sp,
		pronto    => s_pronto,
		vai1      => s_vai1,
		rco       => s_rco,
		medida    => ultima_medida,
		somador   => open,
		pontuacao => pontos,
		estado    => open
	);

	U4: display_mux port map (
		btn      => selecao_display,
		entrada1 => pontos_7,
		entrada2 => ultima_medida_7,
		entrada3 => pontos_mp_7,
		entrada4 => (others => '1'),
		saida_d  => saida_display
	);

	U5: bcd_to_segment7_4digits port map (pontos, pontos_7(27 downto 0));
	U6: bcd_to_segment7_4digits port map (ultima_medida, ultima_medida_7(27 downto 0));

	U9: bcd_to_segment7 port map (n_jogada, pontos_7(41 downto 35));
	U7: bcd_to_segment7 port map (pontos_j1_mp, pontos_mp_7(41 downto 35));
	U8: bcd_to_segment7 port map (pontos_j2_mp, pontos_mp_7(6 downto 0));

	estimulo <= estimulo_mp or estimulo_sp;
	type_led <= switch;
	pulso    <= pulso_sp;

	erro_j1 <= err_sp or err1_mp;
	erro_j2 <= err_sp or err2_mp;

end reaction_game_arch;
