-- 

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity function_generator is

	generic 
	(
		DATA_WIDTH : natural :=0; 
		ADDR_WIDTH : natural :=0;
		PWM_MAX_VALUE : natural :=100;
		LUT_LENGTH : unsigned(15 downto 0) := x"7FFF" -- to reprensent 32768 points
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

	signal address_rom 		: unsigned (14 DOWNTO 0);
	signal q_rom				: unsigned(7 DOWNTO 0);
	signal next_duty_cycle	: unsigned(7 DOWNTO 0) := x"64";
	signal curr_duty_cycle	: unsigned(7 DOWNTO 0) := x"64";
	signal cnt_PWM				: unsigned(7 downto 0) := (others => '0');
	signal clk_100M			: std_logic;
	signal locked_pll			: std_logic;
	signal pwm_sig : std_logic;
	--	signal clk_pwm			: std_logic;
	--	signal duty_cycle_pwm			: std_logic;
	-- signal q						: std_logic_vector(7 DOWNTO 0);
	
	COMPONENT rom IS
		PORT
		(
			address		: IN std_logic_vector (14 DOWNTO 0);
			clock		: IN std_logic  := '1';
			q		: OUT std_logic_vector (7 DOWNTO 0)
		);
	END COMPONENT rom;
	
	component pll is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component pll;

begin

	rom_inst : rom PORT MAP (
		address	 => std_logic_vector(address_rom),
		clock	 => clk_100M,
		unsigned(q)	 => q_rom
	);
	
--	pll_inst : pll port map(
--		refclk   => clk_50M_in,
--		rst      => '0',
--		outclk_0 => clk_100M,
--		locked	=> locked_pll
--	);
	
	process (clk_100M, reset_in)
	begin
		if (reset_in = '1') then
			cnt_PWM <= (others => '0');
			address_rom <= (others => '0');
			next_duty_cycle	 <= x"64";
			curr_duty_cycle	 <= x"64";
			
		elsif (rising_edge(clk_100M)) then
		
			-- store next LUT value at the end of PWM counter
			if (cnt_PWM = PWM_MAX_VALUE-2) then
				-- store next LUT value
				next_duty_cycle <= q_rom;
				curr_duty_cycle <= next_duty_cycle;	 
			end if;
			
			-- Increment rom address at the beginning of the PWM counter
			if (cnt_PWM = 0) then 
				if (address_rom < LUT_LENGTH) then
					address_rom <= address_rom +1;
				else
					address_rom <= (others => '0');
				end if;
			end if;
			
			-- output the PWM signal
			if (cnt_PWM < curr_duty_cycle) then
				pwm_out <= '1';
				--pwm_sig <= not pwm_sig;
			else
				pwm_out <= '0';
				--pwm_sig <= not pwm_sig;
			end if;
			
			-- increment PWM counter
			if (cnt_PWM < PWM_MAX_VALUE-1) then
				cnt_PWM <= cnt_PWM + 1;
			else
				-- reset counter
				cnt_PWM <= (others => '0');
			end if;
				
		end if;
	end process;
	
	testclk100_out <= clk_100M;
	testclk50_out <= clk_50M_in;
	
	--pwm_out <= pwm_sig;
	clk_100M <= clk_50M_in;
	--q_rom <= unsigned(q);
end rtl;