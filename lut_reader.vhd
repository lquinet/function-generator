library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_types.all;

entity lut_reader is

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
		wave_sel_in					: in wave_sel_type;

		lut_duty_cycle_out	: out unsigned(7 DOWNTO 0)
	);
	
end lut_reader;

architecture rtl of lut_reader is

	signal address_rom 		: unsigned (15 DOWNTO 0);
	signal q_rom				: unsigned(7 DOWNTO 0);
	signal q_rom_sine				: unsigned(7 DOWNTO 0);
	signal q_rom_triangle				: unsigned(7 DOWNTO 0);
	signal curr_duty_cycle	: unsigned(7 DOWNTO 0) := x"64"; -- inital curr_duty_cycle is 100
	
	COMPONENT rom_sine IS
	PORT
	(
		address		: IN std_logic_vector (14 DOWNTO 0);
		clock		: IN std_logic  := '1';
		q		: OUT std_logic_vector (7 DOWNTO 0)
	);
	END COMPONENT rom_sine;
	
	COMPONENT rom_triangle IS
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END COMPONENT rom_triangle;
	
begin

	rom_sine_inst : rom_sine PORT MAP (
		address	 => std_logic_vector(address_rom(address_rom'LENGTH-2 downto 0)),
		clock	 => clk_100M_in,
		unsigned(q)	 => q_rom_sine
	);

	rom_triangle_inst : rom_triangle PORT MAP (
		address	 => std_logic_vector(address_rom(address_rom'LENGTH-2 downto 0)),
		clock	 => clk_100M_in,
		unsigned(q)	 => q_rom_triangle
	);	
	
	process (clk_lut_in, reset_in)
	begin
		if (reset_in = '1') then
			address_rom <= (others => '0');
			curr_duty_cycle	 <= x"64";
			
		elsif (rising_edge(clk_lut_in)) then
			-- Read and increment LUT at the beginning of PWM counter
			if (cnt_pwm_in = 0) then 	
			
				-- store next LUT value
				curr_duty_cycle <= q_rom;	 
	
				-- Increment rom_sine address
				if (address_rom + nb_pt_to_skip_in < LUT_LENGTH) then
					address_rom <= address_rom + nb_pt_to_skip_in;
				else
					address_rom <= (others => '0');
				end if;								
			end if;				
		end if;
	end process;

	q_rom <= q_rom_sine when wave_sel_in = SINE else
				q_rom_triangle;
	
	lut_duty_cycle_out <= curr_duty_cycle;
	
end rtl;