----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/14/2018 02:07:12 PM
-- Design Name: 
-- Module Name: top_wrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.vcomponents.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_wrapper is
    Port (
        -- DATA GOING GOING OUT TO THE DAC AS LVDS
        DAC_DATA_OUT_P      : out   STD_LOGIC_VECTOR (15 downto 0);    -- EVEN 0, 2, 4, etc
        DAC_DATA_OUT_N      : out   STD_LOGIC_VECTOR (15 downto 0);    -- ODD  1, 3, 5..

        --DAC CLK coming in as LVDS
        DAC_CLOCK_P         : in    STD_LOGIC;
        DAC_CLOCK_N         : in    STD_LOGIC;
    
        -- CONTROLS TO THE DAC
        FPGA_CLKP           : out   STD_LOGIC;
        FPGA_CLKN           : out   STD_LOGIC;
        SYNCP               : out   STD_LOGIC;
        SYNCN               : out   STD_LOGIC;
        DCLKP               : out   STD_LOGIC;
        DCLKN               : out   STD_LOGIC;

        -- ADC DATA COMING IN AS LVDS
        ADC_DATA_IN_B_P     : in    STD_LOGIC_VECTOR (11 downto 0); -- EVEN 0, 2, 4...
        ADC_DATA_IN_B_N     : in    STD_LOGIC_VECTOR (11 downto 0); -- ODD  1, 3, 5...
        ADC_DATA_IN_A_P     : in    STD_LOGIC_VECTOR (11 downto 0); -- EVEN 0, 2, 4...
        ADC_DATA_IN_A_N     : in    STD_LOGIC_VECTOR (11 downto 0);-- ODD 1, 3, 5...

        	-- ADC CLK coming in as LVDS
    	ADC_CLOCK_A_P       : in    STD_LOGIC; --250 MHz clock output from ADC 
    	ADC_CLOCK_A_N       : in    STD_LOGIC;
    	RESET 		        : in    STD_LOGIC);


end top_wrapper;

architecture Behavioral of top_wrapper is


    signal dac_data_out     :   std_logic_vector (15 downto 0);     -- FULL signal going towards the dac
    signal adc_data_in_a    :   std_logic_vector (11 downto 0);     -- ADC data_a after being converted from LVDS
    signal adc_data_in_b    :   std_logic_vector (11 downto 0);     -- ADC data_b after being converted from LVDS
    signal adc_data_0       :   std_logic_vector (11 downto 0);     -- ADC Data that comes in at the RISING  edge of the first instance of the 500 MHz clk
    signal adc_data_1       :   std_logic_vector (11 downto 0);     -- ADC Data that comes in at the FALLING edge of the first instance of the 500 MHz clk
    signal adc_data_2       :   std_logic_vector (11 downto 0);     -- ADC data that comes in at the RISING  edge of the second instance of the 500 MHz clk
    signal adc_data_3       :   std_logic_vector (11 downto 0);     -- ADC data that comes in at the FALLING edge of the second instance of the 500 MHz Clk
    signal sys_clk  		:	std_logic;							-- ADC clk after being converted from LVDS

    signal dac_data_0		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_0
    signal dac_data_1		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_1
    signal dac_data_2		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_2 
    signal dac_data_3		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_3   
    signal dac_clk			:	std_logic;							--NEED TO FIND OUT WHERE THIS COME'S FROM

    component DSP 
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
	end component;



begin


	--DSP instantiation
	    DSP_Block : DSP 
	    	Port map(
	    		--ADC in
	    		ADC_DATA_0 	=> adc_data_0,
	    		ADC_DATA_1 	=> adc_data_1,
	    		ADC_DATA_2 	=> adc_data_2,
	    		ADC_DATA_3 	=> adc_data_3,

	    		--Control
	    		RESET 		=> RESET,

	    		--clk
	    		SYS_CLK		=> sys_clk,

	    		--DAC out
	    		DAC_DATA_0 	=> dac_data_0,
	    		DAC_DATA_1	=> dac_data_1,
	    		DAC_DATA_2	=> dac_data_2,
	    		DAC_DATA_3	=> dac_data_3
	    		);


    -- CONVERT DATA TO DAC
        OBUFDSloop : for i in 0 to 15 generate
        	OBUFDS_inst : OBUFDS
        	generic map (
        		IOSTANDARD      =>      "DEFAULT",                  -- Specify the output I/O standard
        		SLEW            =>      "SLOW")                     -- Specify the output slew rate
        	port map (
        		O               =>      DAC_DATA_OUT_P(i),          -- Diff_p output (connect directly to top-level port)
        		OB              =>      DAC_DATA_OUT_N(i),          -- Diff_n output (connect directly to top-level port)
        		I               =>      dac_data_out(i)            -- Buffer input		
        	);	
        end generate; 


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

        	--ADC Clock
        	IBUFDS_inst_ADCCLK : IBUFDS
	            generic map (
	                DIFF_TERM       =>      FALSE,                      -- Differential Termination
	                IBUF_LOW_PWR    =>      TRUE,                       -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
	                IOSTANDARD      =>      "DEFAULT")
	            port map (
	                O               =>      sys_clk,           			-- Buffer output
	                I               =>      ADC_CLOCK_A_P,         		-- Diff_p buffer input (connect directly to top-level port)
	                IB              =>      ADC_CLOCK_A_N          		-- Diff_n buffer input (connect directly to top-level port)
            	); 

			IDDRLoopA : for i in 0 to 11 generate
				IDDR_inst : IDDR
				generic map (
					DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE", "SAME_EDGE"
					-- or "SAME_EDGE_PIPELINED"
					INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
					INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
					SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
				port map (
					Q1 => adc_data_0(i), -- 1-bit output for positive edge of clock
					Q2 => adc_data_2(i), -- 1-bit output for negative edge of clock
					C => sys_clk, -- 1-bit clock input 
					CE => '1', -- 1-bit clock enable input 
					D => adc_data_in_a(i), -- 1-bit DDR data input
					R => '0', -- 1-bit reset 
					S => '0' -- 1-bit set 
				);
			end generate IDDRLoopA; 

			IDDRLoopB : for i in 0 to 11 generate
				IDDR_inst : IDDR
				generic map (
					DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE", "SAME_EDGE"
					-- or "SAME_EDGE_PIPELINED"
					INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
					INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
					SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
				port map (
					Q1 => adc_data_1(i), -- 1-bit output for positive edge of clock
					Q2 => adc_data_3(i), -- 1-bit output for negative edge of clock
					C => sys_clk, -- 1-bit clock input <--- we don't know this
					CE => '1', -- 1-bit clock enable input <--- don't know this either
					D => adc_data_in_b(i), -- 1-bit DDR data input
					R => '0', -- 1-bit reset <--- not defined yet
					S => '0' -- 1-bit set <--- not defined yet
				);
			end generate IDDRLoopB; 

			--DAC Clock
        	IBUFDS_inst_DACCLK : IBUFDS
	            generic map (
	                DIFF_TERM       =>      FALSE,                      -- Differential Termination
	                IBUF_LOW_PWR    =>      TRUE,                       -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
	                IOSTANDARD      =>      "DEFAULT")
	            port map (
	                O               =>      dac_clk,           			-- Buffer output
	                I               =>      DAC_CLOCK_P,         		-- Diff_p buffer input (connect directly to top-level port)
	                IB              =>      DAC_CLOCK_N          		-- Diff_n buffer input (connect directly to top-level port)
            	); 

            OSERDESloop : for i in 0 to 15 generate
				OSERDESE2_inst : OSERDESE2
					generic map (
						DATA_RATE_OQ => "SDR", -- DDR, SDR
						DATA_RATE_TQ => "DDR", -- DDR, BUF, SDR
						DATA_WIDTH => 4, -- Parallel data width (2-8,10,14)
						INIT_OQ => '0', -- Initial value of OQ output (1'b0,1'b1)
						INIT_TQ => '0', -- Initial value of TQ output (1'b0,1'b1)
						SERDES_MODE => "MASTER", -- MASTER, SLAVE
						SRVAL_OQ => '0', -- OQ output value when SR is used (1'b0,1'b1)
						SRVAL_TQ => '0', -- TQ output value when SR is used (1'b0,1'b1)
						TBYTE_CTL => "FALSE", -- Enable tristate byte operation (FALSE, TRUE)
						TBYTE_SRC => "FALSE", -- Tristate byte source (FALSE, TRUE)
						TRISTATE_WIDTH => 4 -- 3-state converter width (1,4)
					)
					port map (
						OFB => open, -- 1-bit output: Feedback path for data
						OQ => dac_data_out(i), -- 1-bit output: Data path output
						-- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
						SHIFTOUT1 => open,
						SHIFTOUT2 => open,
						TBYTEOUT => open, -- 1-bit output: Byte group tristate
						TFB => open, -- 1-bit output: 3-state control
						TQ => open, -- 1-bit output: 3-state control
						CLK => DAC_CLK, -- 1-bit input: High speed clock
						CLKDIV => sys_clk, -- 1-bit input: Divided clock
						-- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
						D1 => dac_data_0(i),
						D2 => dac_data_1(i),
						D3 => dac_data_2(i),
						D4 => dac_data_3(i),
						D5 => '1',
						D6 => '1',
						D7 => '1',
						D8 => '1',
						OCE => '1', -- 1-bit input: Output data clock enable
						RST => RESET, -- 1-bit input: Reset
						-- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
						SHIFTIN1 => '0',
						SHIFTIN2 => '0',
						-- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
						T1 => '0',
						T2 => '0',
						T3 => '0',
						T4 => '0',
						TBYTEIN => '0', -- 1-bit input: Byte group tristate
						TCE => '0' -- 1-bit input: 3-state clock enable
					);
					end generate OSERDESloop; 

end Behavioral;
