library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pwm_generator is

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
end pwm_generator;

architecture rtl of pwm_generator is

	signal cnt_pwm				: unsigned(7 downto 0) := (others => '0');  -- to count until 100
	
begin

	process (clk_in, reset_in)
	begin
		if (reset_in = '1') then
			cnt_pwm <= (others => '0');
		elsif (rising_edge(clk_in)) then
			
			-- output the PWM signal
			if (cnt_pwm < duty_cycle_in) then
				pwm_out <= '1';
			else
				pwm_out <= '0';
			end if;
			
			-- increment PWM counter
			if (cnt_pwm < pwm_max_value_in-1) then
				cnt_pwm <= cnt_pwm + 1;
			else
				-- reset counter
				cnt_pwm <= (others => '0');
			end if;
				
		end if;
	end process;
	
	cnt_pwm_out <= cnt_pwm;

end rtl;