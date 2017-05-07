library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package my_types is
type clk_in_sel_type is (SEL_CLK_3125KHZ, SEL_CLK_31250KHZ, SEL_CLK_100MHZ);
type wave_sel_type is (SINE, TRIANGLE, SQUARE);
end package my_types;