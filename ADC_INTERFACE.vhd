library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.vcomponents.all;

entity ADC_INTERFACE is
	Port(

		--input from ADC
		ADC_DATA_IN_B_P	: in STD_LOGIC_VECTOR(11 downto 0);
		ADC_DATA_IN_B_N	: in STD_LOGIC_VECTOR(11 downto 0);
		ADC_DATA_IN_A_P : in STD_LOGIC_VECTOR(11 downto 0);
		ADC_DATA_IN_A_N : in STD_LOGIC_VECTOR(11 downto 0);

		--clock input from ADC
--		ADC_CLOCK_A_P	: in STD_LOGIC;
--		ADC_CLOCK_A_N	: in STD_LOGIC;

		--Interface ADC outside
		ADC_DATA_0	: out STD_LOGIC_VECTOR(11 downto 0);
		ADC_DATA_1	: out STD_LOGIC_VECTOR(11 downto 0);
		ADC_DATA_2	: out STD_LOGIC_VECTOR(11 downto 0);
		ADC_DATA_3	: out STD_LOGIC_VECTOR(11 downto 0);

		--clock output from interface
		RESET       : IN STD_LOGIC;
		SYS_CLK 	: IN STD_LOGIC
		);
	end ADC_INTERFACE;


architecture Behavioral of ADC_INTERFACE is

	signal adc_data_in_a 	: std_logic_vector(11 downto 0);
	signal adc_data_in_b 	: std_logic_vector(11 downto 0);
	signal adc_clk_w        : std_logic;
	signal adc_data_0_w     : std_logic_vector(11 downto 0);
	signal adc_data_1_w     : std_logic_vector(11 downto 0);
	signal adc_data_2_w     : std_logic_vector(11 downto 0);
	signal adc_data_3_w     : std_logic_vector(11 downto 0);

begin


	process(RESET, SYS_CLK)
    begin
        if RESET = '1' then
            ADC_DATA_0 <= X"000";
            ADC_DATA_1 <= X"000";
            ADC_DATA_2 <= X"000";
            ADC_DATA_3 <= X"000";                
        else 
            if rising_edge(SYS_CLK) then
                --INVERT DATA because our input data ports are crossed
                ADC_DATA_0(10 downto 0) <= not (adc_data_0_w(10 downto 0));
                ADC_DATA_1(10 downto 0) <= not (adc_data_1_w(10 downto 0));
                ADC_DATA_2(10 downto 0) <= not (adc_data_2_w(10 downto 0));
                ADC_DATA_3(10 downto 0) <= not (adc_data_3_w(10 downto 0));
                ADC_DATA_3(11) <=   adc_data_3_w(11);
                ADC_DATA_2(11) <=   adc_data_2_w(11);
                ADC_DATA_1(11) <=   adc_data_1_w(11);
                ADC_DATA_0(11) <=   adc_data_0_w(11);



                
            end if;
        end if;
    end process;
            


			-- CONVERT ADC LVDS DATA 
	        IBUFDSloop_A : for i in 0 to 11 generate
	                  -- CHANNEL A 
	          IBUFDS_inst_A : IBUFDS
	                generic map (
	                    DIFF_TERM       =>      FALSE,                      -- Differential Termination
	                    IBUF_LOW_PWR    =>      TRUE,                       -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
	                    IOSTANDARD      =>      "DEFAULT")
	                port map (
	                    O               =>      adc_data_in_a(i),           -- Buffer output
	                    I               =>      ADC_DATA_IN_A_P(i),          -- Diff_p buffer input (connect directly to top-level port)
	                    IB              =>      ADC_DATA_IN_A_N(i)          -- Diff_n buffer input (connect directly to top-level port)
	                    );  
	        end generate IBUFDSloop_A;

	            -- CHANNEL B
	            IBUFDS_B: for i in 0 to 11 generate
		    		IBUFDS_inst_B : IBUFDS
		            generic map (
		                DIFF_TERM       =>      FALSE,                      -- Differential Termination
		                IBUF_LOW_PWR    =>      TRUE,                       -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
		                IOSTANDARD      =>      "DEFAULT")
		            port map (
		                O               =>      adc_data_in_b(i),           -- Buffer output
		                I               =>      ADC_DATA_IN_B_P(i),         -- Diff_p buffer input (connect directly to top-level port)
		                IB              =>      ADC_DATA_IN_B_N(i)          -- Diff_n buffer input (connect directly to top-level port)
		            );  
	        	end generate IBUFDS_B; 

--	        	--ADC Clock
--	        	IBUFDS_inst_ADCCLK : IBUFDS
--		            generic map (
--		                DIFF_TERM       =>      FALSE,                      -- Differential Termination
--		                IBUF_LOW_PWR    =>      TRUE,                       -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
--		                IOSTANDARD      =>      "DEFAULT")
--		            port map (
--		                O               =>      adc_clk_w,           			-- Buffer output
--		                I               =>      ADC_CLOCK_A_P,         		-- Diff_p buffer input (connect directly to top-level port)
--		                IB              =>      ADC_CLOCK_A_N          		-- Diff_n buffer input (connect directly to top-level port)
--	            	); 

				IDDRLoopA : for i in 0 to 11 generate
					IDDR_inst : IDDR
					generic map (
						DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", "SAME_EDGE"
						-- or "SAME_EDGE_PIPELINED"
						INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
						INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
						SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
					port map (
						Q1 => adc_data_1_w(i), -- 1-bit output for positive edge of clock
						Q2 => adc_data_3_w(i), -- 1-bit output for negative edge of clock
						C => SYS_CLK, -- 1-bit clock input 
						CE => '1', -- 1-bit clock enable input 
						D => adc_data_in_a(i), -- 1-bit DDR data input
						R => '0', -- 1-bit reset 
						S => '0' -- 1-bit set 
					);
				end generate IDDRLoopA; 

				IDDRLoopB : for i in 0 to 11 generate
					IDDR_inst : IDDR
					generic map (
						DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", "SAME_EDGE"
						-- or "SAME_EDGE_PIPELINED"
						INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
						INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
						SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
					port map (
						Q1 => ADC_DATA_0_w(i), -- 1-bit output for positive edge of clock
						Q2 => ADC_DATA_2_w(i), -- 1-bit output for negative edge of clock
						C => SYS_CLK, -- 1-bit clock input <--- we don't know this
						CE => '1', -- 1-bit clock enable input <--- don't know this either
						D => adc_data_in_b(i), -- 1-bit DDR data input
						R => '0', -- 1-bit reset <--- not defined yet
						S => '0' -- 1-bit set <--- not defined yet
					);
				end generate IDDRLoopB; 
				


	end Behavioral;

	
