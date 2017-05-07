-- 

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity function_generator is

	generic 
	(
		--DATA_WIDTH : natural :=0; 
		--ADDR_WIDTH : natural :=0;
		PWM_MAX_VALUE : natural :=100;
		LUT_LENGTH 		: unsigned(15 downto 0) := x"7A12"; -- 31250 points
		PWM_OUT_FREQ : unsigned(19 downto 0) := x"07A12" -- 31250 Hz (f_sig <= 625Hz)
		-- PWM_OUT_FREQ : unsigned(19 downto 0) := x"4C4B4" -- 312500 Hz
	);

	port 
	(	
		clk_50M_in 	: in std_logic;
		reset_in		: in std_logic := '0';
		pwm_out : out std_logic := '1';
		testclk50_out : out std_logic;
		testclk100_out : out std_logic
		--		address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		--		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);

end function_generator;

architecture rtl of function_generator is

	signal clk_100MHz				: std_logic;
	signal clk_31250KHz			: std_logic;
	signal clk_3125KHz			: std_logic;
	signal clk_in_pwm				: std_logic;
	signal clk_in_sel				: std_logic := '0'; -- 0 for 3125KHz clock and 1 for 31250KHz clock
	signal cnt_pwm_sig			: unsigned(7 downto 0);
	signal lut_nb_pt_to_skip	: unsigned(15 downto 0); 
	signal locked_pll				: std_logic;
	signal f_sig 					: unsigned(19 downto 0) := x"0012C";
	signal is_f_sig_changed		: std_logic := '0';
	signal div_out_sig				: unsigned(35 DOWNTO 0);
	signal lut_duty_cycle_sig	: unsigned(7 DOWNTO 0);
	signal reset_pwm				: std_logic := '0';
	signal reset_lut_reader		: std_logic := '0';
	
	component pll is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- 100 MHz output clock
			outclk_1 : out std_logic;        -- 31.25 MHz output clock
			outclk_2 : out std_logic;        -- 3.125 MHz output clock
			locked   : out std_logic         --  locked.export
		);
	end component pll;
	
	component lut_reader is
		generic 
		(
			LUT_LENGTH : unsigned(15 downto 0); -- to reprensent 32768 points
			PWM_MAX_VALUE : natural
		);

		port 
		(	
			clk_100M_in 			: in std_logic;
			reset_in					: in std_logic;
			cnt_pwm_in 				: in unsigned(7 downto 0);
			nb_pt_to_skip			: in unsigned(15 downto 0); -- to count until 1000 0000
			lut_duty_cycle_out	: out unsigned(7 DOWNTO 0)
		);
	end component lut_reader;

	component pwm_generator is
		generic 
		(
			PWM_MAX_VALUE : natural
		);

		port 
		(	
			clk_in 				: in std_logic;
			reset_in				: in std_logic;
			lut_duty_cycle_in	: in unsigned(7 DOWNTO 0);
			cnt_pwm_out			: out unsigned(7 downto 0); 
			pwm_out 				: out std_logic
		);
	end component pwm_generator;	
	
begin
	
	pll_inst : pll port map(
		refclk   => clk_50M_in,
		rst      => '0',
		outclk_0 => clk_100MHz,
		outclk_1 => clk_31250KHz,
		outclk_2 => clk_3125KHz,
		locked	=> locked_pll
	);

	lut_reader_inst : lut_reader generic map (
		LUT_LENGTH => LUT_LENGTH,
		PWM_MAX_VALUE => PWM_MAX_VALUE
	) port map (	
		clk_100M_in => clk_100MHz,
		reset_in => reset_lut_reader,
		cnt_pwm_in => cnt_pwm_sig,
		nb_pt_to_skip => lut_nb_pt_to_skip,
		lut_duty_cycle_out => lut_duty_cycle_sig
	);	
	
	pwm_generator_inst : pwm_generator generic map (
		PWM_MAX_VALUE => PWM_MAX_VALUE
	) port map (	
		clk_in => clk_in_pwm,
		reset_in	=> reset_pwm,
		lut_duty_cycle_in	=> lut_duty_cycle_sig,
		cnt_pwm_out => cnt_pwm_sig,
		pwm_out => pwm_out
	);
	
	process (is_f_sig_changed, reset_in)
	begin
		if (reset_in = '1') then
		
		elsif(rising_edge(is_f_sig_changed)) then
			
			if (is_f_sig_changed = '1') then
				reset_pwm <= '1';
				reset_lut_reader <= '1';
			else 
				reset_pwm <= '0';
				reset_lut_reader <= '0';
			end if;
			
			
		end if;
	end process;
	
	--div_out_sig <= (LUT_LENGTH * f_sig)/PWM_OUT_FREQ ; -- lut_nb_pt_to_skip <= ((LUT_LENGTH * ("0000" & f_sig))/PWM_OUT_FREQ);
	--lut_nb_pt_to_skip <= div_out_sig(15 downto 0);
	lut_nb_pt_to_skip <= f_sig(15 downto 0);
	
	clk_in_pwm <= 	clk_3125KHz when clk_in_sel = '0' else
						clk_31250KHz;
	
	testclk100_out <= clk_100MHz;
	testclk50_out <= clk_50M_in;
	
	--pwm_out <= pwm_sig;
	--clk_100M <= clk_50M_in;
	--q_rom <= unsigned(q);
end rtl;