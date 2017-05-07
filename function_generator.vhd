-- 

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_types.all;

entity function_generator is

	generic 
	(
		--DATA_WIDTH : natural :=0; 
		--ADDR_WIDTH : natural :=0;
		PWM_MAX_VALUE : natural :=100;
		LUT_LENGTH 		: unsigned(15 downto 0) := x"7A12"; -- 31250 points
		PWM_OUT_FREQ : unsigned(19 downto 0) := x"07A12"; -- 31250 Hz (f_sig <= 625Hz)
		-- PWM_OUT_FREQ : unsigned(19 downto 0) := x"4C4B4" -- 312500 Hz
		F_SIG_MAX_1HZ_RES : natural :=625;
		F_SIG_MAX_10HZ_RES : natural :=9765;
		F_SIG_MAX : natural := 31250
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
	signal clk_pwm				: std_logic;
	signal cnt_pwm_sig			: unsigned(7 downto 0);
	signal lut_nb_pt_to_skip	: unsigned(15 downto 0); 
	signal locked_pll				: std_logic;
	signal lut_duty_cycle_sig	: unsigned(7 DOWNTO 0);
	signal reset_pwm				: std_logic := '0';
	signal reset_lut_reader		: std_logic := '0';
	
	-- for simu
	signal address_rom 		: unsigned (15 DOWNTO 0);
	signal q_rom				: unsigned(7 DOWNTO 0);
	signal next_duty_cycle	: unsigned(7 DOWNTO 0); 
	
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
			clk_lut_in					: in std_logic;
			reset_in					: in std_logic;
			cnt_pwm_in 				: in unsigned(7 downto 0);
			nb_pt_to_skip_in			: in unsigned(15 downto 0); -- to count until 1000 0000
			address_rom_out 			: out unsigned (15 DOWNTO 0);
			q_rom_out						: out unsigned(7 DOWNTO 0);
			lut_duty_cycle_out	: out unsigned(7 DOWNTO 0)
		);
	end component lut_reader;

	component pwm_generator is
--	generic 
--	(
--		--PWM_MAX_VALUE : natural :=100
--	);

	port 
	(	
		clk_in 				: in std_logic;
		reset_in				: in std_logic;
		duty_cycle_in		: in unsigned(7 downto 0);
		pwm_max_value_in	: in unsigned(7 downto 0);
		
		cnt_pwm_out			: out unsigned(7 downto 0); 
		pwm_out 				: out std_logic
	);
	end component pwm_generator;	

	component frequency_reconfig is
		generic 
		(
			F_SIG_MAX_1HZ_RES : natural;
			F_SIG_MAX_10HZ_RES : natural;
			F_SIG_MAX : natural
		);

		port 
		(	
			clk_100MHz_in			: in std_logic;
			clk_3125KHz_in		: in std_logic;
			clk_31250KHz_in	: in std_logic;
			reset_in				: in std_logic;
			
			clk_pwm_out				: out std_logic;
			lut_nb_pt_to_skip_out	: out unsigned(15 downto 0);
			reset_pwm_out				: out std_logic;
			reset_lut_reader_out		: out std_logic
		);
	end component frequency_reconfig;	
	
	
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
		clk_lut_in => clk_pwm,
		reset_in => reset_lut_reader,
		cnt_pwm_in => cnt_pwm_sig,
		nb_pt_to_skip_in => lut_nb_pt_to_skip,
		
		address_rom_out => address_rom,
		q_rom_out => q_rom,
		lut_duty_cycle_out => lut_duty_cycle_sig
	);	
	
	pwm_generator_inst : pwm_generator 
--	generic map (
--		PWM_MAX_VALUE => PWM_MAX_VALUE
--	) 
	port map (	
		clk_in => clk_pwm,
		reset_in	=> reset_pwm,
		lut_duty_cycle_in	=> lut_duty_cycle_sig,
		pwm_max_value_in => x"64",
		
		cnt_pwm_out => cnt_pwm_sig,
		pwm_out => pwm_out
	);
	
	frequency_reconfig_inst : frequency_reconfig generic map (
			F_SIG_MAX_1HZ_RES => F_SIG_MAX_1HZ_RES,
			F_SIG_MAX_10HZ_RES => F_SIG_MAX_10HZ_RES,
			F_SIG_MAX => F_SIG_MAX
	) port map (	
			clk_100MHz_in => clk_100MHz,
			clk_3125KHz_in => clk_3125KHz,
			clk_31250KHz_in => clk_31250KHz,
			reset_in => '0',
			
			clk_pwm_out => clk_pwm,
			lut_nb_pt_to_skip_out => lut_nb_pt_to_skip,
			reset_pwm_out => reset_pwm,
			reset_lut_reader_out => reset_lut_reader
	);	
	
	testclk100_out <= clk_100MHz;
	testclk50_out <= clk_50M_in;

end rtl;