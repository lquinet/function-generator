library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_types.all;

entity frequency_reconfig is

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
		
		clk_pwm_out			: out std_logic;
		lut_nb_pt_to_skip_out	: out unsigned(15 downto 0);
		reset_pwm_out				: out std_logic := '0';
		reset_lut_reader_out		: out std_logic := '0'
	);
end frequency_reconfig;

architecture rtl of frequency_reconfig is

	signal f_sig 					: unsigned(19 downto 0) := x"0012C"; -- 300 Hz
	signal is_f_sig_changed		: std_logic := '0';
	signal div_out_sig			: unsigned(19 DOWNTO 0);
	signal clk_in_sel				: clk_in_sel_type := SEL_CLK_3125KHZ;
	signal command_sig 				: unsigned(7 downto 0);

	COMPONENT UART IS PORT 
		(	 
			-- Module signals
			DATAREADY	: out std_logic;
			COMMAND		: out unsigned(7 downto 0);
			DATA			: out unsigned(31 downto 0);
		
			-- FPGA External signals
			RX				: in std_logic;
			TX				: out std_logic;
			
			--- DEBUG
			LED 		: out unsigned(7 downto 0);
			
			-- System
			RST_N			: in std_logic;
			MCLK			: in std_logic
		);
	END COMPONENT;
	
begin

	process (clk_100MHz_in, reset_in)
	begin
		if (reset_in = '1') then
		
		elsif(rising_edge(clk_100MHz_in)) then
			
			if (is_f_sig_changed = '1') then
				-- reset pwm and lut
				reset_pwm_out <= '1';
				reset_lut_reader_out <= '1';
				
				-- sine command ('s')
				if (command_sig = x"73") then
					-- change pwm clock and the number of points to skip depending of the signal frequency
					if (f_sig <= F_SIG_MAX_1HZ_RES) then
						div_out_sig <= f_sig;
						clk_in_sel <= SEL_CLK_3125KHZ;
						
					elsif (f_sig <= F_SIG_MAX_10HZ_RES) then
						div_out_sig <= f_sig/10;
						clk_in_sel <= SEL_CLK_31250KHZ;
					end if;
				-- triangle command ('t')
				elsif (command_sig = x"74") then
				
				-- square command ('c')
				elsif (command_sig = x"63") then
				end if;
			else 
				reset_pwm_out <= '0';
				reset_lut_reader_out <= '0';
			end if;
			
		end if;
	end process;
	
	lut_nb_pt_to_skip_out <= div_out_sig(15 downto 0);
	
	clk_pwm_out <= 	clk_3125KHz_in when clk_in_sel = SEL_CLK_3125KHZ else
						clk_31250KHz_in; -- when clk_in_sel = SEL_CLK_31250KHZ else


end rtl;