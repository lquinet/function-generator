library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_types.all;

entity square_generator is

--	generic 
--	(
--	);

	port 
	(	
		clk_100MHz_in		: in std_logic;
		reset_in				: in std_logic;
		wave_sel_in			: in wave_sel_type;
		counter_max_value_in	: in unsigned(31 downto 0);
		
		square_wave_out	: out std_logic
	);
end square_generator;

architecture rtl of square_generator is

	signal cnt_square : unsigned(31 downto 0) := (others => '0');
	signal cnt_half_max_value : unsigned(31 downto 0);
	
begin

	process (clk_100MHz_in, reset_in)
	begin
		if (reset_in = '1') then
			cnt_square <= (others => '0');
		elsif(rising_edge(clk_100MHz_in)) then
			-- increment PWM counter
			if (cnt_square < counter_max_value_in-1) then
				cnt_square <= cnt_square + 1;
				
				-- change edge of the signal at the middle of a period
				if (cnt_square = cnt_half_max_value -1) then
					square_wave_out <= '0';
				end if;
			else
				-- reset counter
				cnt_square <= (others => '0');
				square_wave_out <= '1';
			end if;
		end if;
	end process;

	cnt_half_max_value <= counter_max_value_in/2;
	
end rtl;