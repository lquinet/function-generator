library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_types.all;

entity frequency_reconfig is

--	generic 
--	(
--	);

	port 
	(	
		clk_100MHz_in			: in std_logic;
		clk_3125KHz_in		: in std_logic;
		clk_31250KHz_in	: in std_logic;
		reset_in				: in std_logic;
		wave_sel_in			: in wave_sel_type;
		is_wave_changed_in : in std_logic;
		cnt_pwm_in 			: in unsigned(7 downto 0);
		f_sig 					: in unsigned(19 downto 0) := x"0012C";
		
		clk_pwm_out			: out std_logic;
		lut_nb_pt_to_skip_out	: out unsigned(15 downto 0);
		pwm_max_value_out			: out unsigned(7 downto 0);
		reset_pwm_out				: out std_logic := '0';
		reset_lut_reader_out		: out std_logic := '0'
	);
end frequency_reconfig;

architecture rtl of frequency_reconfig is

	--signal f_sig 					: unsigned(19 downto 0) := x"0012C"; -- 300 Hz
	signal is_f_sig_changed		: std_logic := '0';
	signal div_out_sig			: unsigned(19 DOWNTO 0);
	signal clk_in_sel				: clk_in_sel_type := SEL_CLK_3125KHZ;
	signal cnt_triangle : unsigned(7 DOWNTO 0);

	
begin

	process (clk_100MHz_in, reset_in)
	begin
		if (reset_in = '1') then
		
		elsif(rising_edge(clk_100MHz_in)) then
			if (is_wave_changed_in = '1') then
				if (wave_sel_in = TRIANGLE) then 
					cnt_triangle <= unsigned(x"F4240")/f_sig;
				end if;
		end if;
	end process;
	
	lut_nb_pt_to_skip_out <= div_out_sig(15 downto 0);
	
	clk_pwm_out <= 	clk_3125KHz_in when clk_in_sel = SEL_CLK_3125KHZ else
						clk_31250KHz_in; -- when clk_in_sel = SEL_CLK_31250KHZ else


end rtl;