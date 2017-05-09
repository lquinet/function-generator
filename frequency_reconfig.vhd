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
		rx_uart_in			: in std_logic;
		
		tx_uart_out					: out std_logic;
		clk_pwm_out					: out std_logic;
		lut_nb_pt_to_skip_out	: out unsigned(15 downto 0);
		wave_sel_out				: out wave_sel_type;
		cnt_square_max_out	: out unsigned(31 downto 0);
		dataready_uart_out				: out std_logic;
		reset_pwm_out				: out std_logic := '0';
		reset_square_generator_out : out std_logic := '0';
		reset_lut_reader_out		: out std_logic := '0'
	);
end frequency_reconfig;

architecture rtl of frequency_reconfig is

	signal div_out_lut_nb_pt_to_skip			: unsigned(31 DOWNTO 0) := x"0000012C" ;
	signal div_out_cnt_square_max	: unsigned(31 downto 0);
	signal clk_in_sel				: clk_in_sel_type := SEL_CLK_3125KHZ;
	signal dataready_uart		: std_logic;
	signal command_uart 			: unsigned(7 downto 0);
	signal data_uart				: unsigned(31 downto 0);
	signal wave_sel_sig			: wave_sel_type;
	signal led_sig					: unsigned(7 downto 0);
	signal new_cmd_received		: std_logic := '0';
	signal f_sig					: unsigned(31 downto 0);
	signal test_cmd				: std_logic := '0';
	
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

	uart_inst : UART port map( 
		-- Module signals
		DATAREADY => dataready_uart,
		COMMAND	=> command_uart,
		DATA		=> data_uart,
	
		-- FPGA External signals
		RX		=> rx_uart_in,
		TX 	=> tx_uart_out,
		
		--- DEBUG
		LED	=> led_sig,
		
		-- System
		RST_N	=> '1',
		MCLK	=> clk_100MHz_in
	);

	process (new_cmd_received, reset_in)
	begin
		if (reset_in = '1') then
			null;
		elsif(rising_edge(new_cmd_received)) then
				
			case command_uart is
				
				-- sine command ('s')
				when x"73" =>
					wave_sel_sig <= SINE;
					test_cmd <= '0';
				-- triangle command ('t')
				when x"74" =>
					wave_sel_sig <= TRIANGLE;
					test_cmd <= '1';
				-- square command ('c')
				when x"63" =>
					wave_sel_sig <= SQUARE;
				-- frequency command ('f')
				when x"66" =>
					if(wave_sel_sig = SQUARE) then
						if(data_uart <= 100000000) then
							--cnt_square_max_out <= x"05F5E100"/data_uart;
							f_sig <= data_uart;
						end if;
					else
						-- change pwm clock and the number of points to skip depending of the signal frequency
						if (data_uart <= F_SIG_MAX_1HZ_RES) then
							--div_out_lut_nb_pt_to_skip <= data_uart;
							f_sig <= data_uart;
							clk_in_sel <= SEL_CLK_3125KHZ;	
						elsif (data_uart <= F_SIG_MAX_10HZ_RES) then
							--div_out_lut_nb_pt_to_skip <= data_uart/10;
							f_sig <= data_uart;
							clk_in_sel <= SEL_CLK_31250KHZ;
						end if;
					end if;
				-- stop command ('0')
				when x"30" => null;
					-- stop all components
					reset_pwm_out <= '1';
					reset_lut_reader_out <= '1';
					reset_square_generator_out <= '1';
				-- start command ('1')
				when x"31" => null;
					reset_pwm_out <= '0';
					reset_lut_reader_out <= '0';	
					reset_square_generator_out <= '0';
				when others => null;
			end case;
		end if;
	end process;
	
	
	-- Process to synchronise the rising edge of new_cmd_received with the 100Mhz clock
	process (clk_100MHz_in, reset_in)
	variable prevDataready : std_logic := '0';
	begin
		if(rising_edge(clk_100MHz_in)) then
			if (dataready_uart = '1' and prevDataready ='0') then
				new_cmd_received <= '1';
				prevDataready := '1';
			elsif (dataready_uart = '0') then
				new_cmd_received <= '0';
				prevDataready := '0';
			end if;
		end if;
	end process;
	
--	-- Process to reset pwm and lut_reader
--	process (clk_100MHz_in, reset_in)
--	variable prevDataready : std_logic := '0';
--	begin
--		if(rising_edge(clk_100MHz_in)) then
--			if (dataready_uart = '1' and reset_lut_reader_sig ='0' and reset_pwm_sig = '0') then
--				-- reset pwm and lut
--				reset_pwm_sig <= '1';
--				reset_lut_reader_sig <= '1';		
--			else
--				reset_pwm_sig <= '0';
--				reset_lut_reader_sig <= '0';
--			end if;
--		end if;
--	end process;
	
	
	-- Calculate the number of points to skip in LUT
	div_out_lut_nb_pt_to_skip <= 	f_sig when clk_in_sel = SEL_CLK_3125KHZ else
											f_sig/10;
	lut_nb_pt_to_skip_out <= div_out_lut_nb_pt_to_skip(15 downto 0);
	
	-- output the clock for pwm
	clk_pwm_out <= 	clk_3125KHz_in when clk_in_sel = SEL_CLK_3125KHZ else
							clk_31250KHz_in; -- when clk_in_sel = SEL_CLK_31250KHZ else

	-- Calculate the counter for square wave generator
	div_out_cnt_square_max <= x"05F5E100"/f_sig;
	cnt_square_max_out <= div_out_cnt_square_max;
	
	wave_sel_out <= wave_sel_sig;
	
	-- for debug
	dataready_uart_out <= test_cmd;
end rtl;