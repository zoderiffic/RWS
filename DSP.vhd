library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity DSP is
	Port (
			--ADC in
			ADC_DATA_0	: in STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_1	: in STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_2	: in STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_3	: in STD_LOGIC_VECTOR(11 downto 0);

			--Control
			RESET 		: in STD_LOGIC;

			--clk
			SYS_CLK		: in STD_LOGIC;

			--DAC out
			DAC_DATA_0 	: out STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_1	: out STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_2	: out STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_3	: out STD_LOGIC_VECTOR(15 downto 0)
			);
	end DSP;


architecture Behavioral of DSP is
	signal sig_0 	: std_logic_vector(15 downto 0);
	signal sig_1 	: std_logic_vector(15 downto 0);
	signal sig_2 	: std_logic_vector(15 downto 0);
	signal sig_3 	: std_logic_vector(15 downto 0);


begin

	process(RESET, SYS_CLK)
		begin
			if RESET = '1' then
				sig_0 <= X"0000";
				sig_1 <= X"0000";
				sig_2 <= X"0000";
				sig_3 <= X"0000";				
			else 
				if rising_edge(SYS_CLK) then
					sig_0(15 downto 4)	<= (not(ADC_DATA_0));
					sig_0(3 downto 0)	<= x"0";

					sig_1(15 downto 4)	<= not(ADC_DATA_1);
					sig_1(3 downto 0)	<= x"0";					

					sig_2(15 downto 4)	<= NOT(ADC_DATA_2);
					sig_2(3 downto 0)	<= x"0";					

					sig_3(15 downto 4)	<= not(ADC_DATA_3);
					sig_3(3 downto 0)	<= x"0";	
				end if;
			end if;
		end process;
        DAC_DATA_0 	 <= sig_0;
        DAC_DATA_1   <= sig_1;
        DAC_DATA_2  <= sig_2;
        DAC_DATA_3 <= sig_3;
		
	end Behavioral;			






	
	
	
