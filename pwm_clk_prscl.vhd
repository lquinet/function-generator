 library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pwm_clk_prscl is

	generic 
	(
		DATA_WIDTH : natural :=0; 
		ADDR_WIDTH : natural :=0;
		PWM_MAX_VALUE : natural :=100
	);

	port 
	(	
		clk_100M_in			: in std_logic;
		clk_31M_in			: in std_logic;
		reset_in				: in std_logic;
		pwm_clk_prscl_sel	: in std_logic; -- 0 for 320 ns clock and 1 for 32ns clock
		pwm_clk_prscl_out	: out std_logic
	);
end pwm_clk_prscl;

architecture rtl of pwm_clk_prscl is

	signal cnt_clk				: unsigned(7 downto 0) := (others => '0');  -- to count until 100 
begin

	process (clk_100M_in, reset_in)
	begin
		if (reset_in = '1') then
			cnt_clk <= (others => '0');
		elsif (rising_edge(clk_in)) then
			
			-- increment PWM counter
			if (cnt_pwm < PWM_MAX_VALUE-1) then
				cnt_pwm <= cnt_pwm + 1;
			else
				-- reset counter
				cnt_pwm <= (others => '0');
			end if;
				
		end if;
	end process;
	
	cnt_pwm_out <= cnt_pwm;

end rtl;