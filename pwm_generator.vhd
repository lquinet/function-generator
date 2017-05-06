-- 

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pwm_generator is

	port 
	(
		clk_in	: in std_logic; -- 100MHz clock
		reset_in	: in std_logic;
		table_in	: in unsigned(15 downto 0);
		
		pwm_out	: out std_logic
	);

end pwm_generator;

architecture rtl of pwm_generator is

	constant SIGNAL_FREQ 	: natural := 1000; -- 1kHz
	constant PWM_FREQ 		: natural:= 10000000; -- 100ns period
	constant NUM_PT_TABLE 	: natural:= 10; -- = FPGA clock/PWM period = 10 points in the table period
	constant NUM_DC_LATCH 	: natural:= 500; -- = PWM_FREQ/(NUM_PT_TABLE*2*SIGNAL_FREQ) = 500 pwm perdiod that we must latch before changing the duty cycle value
	
	constant PWM_MAX_VALUE	: unsigned(8 downto 0) := x"64";	-- max value = 100
	
	signal counter : unsigned(8 downto 0) := (others => '0');
	
--	COMPONENT rom IS
--		PORT
--		(
--			address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
--			clock		: IN STD_LOGIC  := '1';
--			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
--		);
--	END COMPONENT rom;
	
begin

--	rom_inst : rom PORT MAP (
--		address	 => address_sig,
--		clock	 => clock_sig,
--		q	 => q_sig
--	);
	
--	process (clk_in, reset_in)
--	--variable cnt:  := 0;
--	begin
--		if (reset_in = '1') then
--			cnt := 0;
--			--<register_variable> <= '0';
--		elsif (rising_edge(clk_in)) then
--			if (counter = PWM_MAX_VALUE) then
--				address_sig 	<= 
--				next_duty_cycle <= 
--				curr_duty_cycle <= next_duty_cycle;
--		end if;
--	end process;

end rtl;