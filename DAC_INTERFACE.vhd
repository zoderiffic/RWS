library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.vcomponents.all;

entity DAC_INTERFACE is
	Port(

		--input from DSP block
		DAC_DATA_0	: in STD_LOGIC_VECTOR(15 downto 0);
		DAC_DATA_1	: in STD_LOGIC_VECTOR(15 downto 0);
		DAC_DATA_2	: in STD_LOGIC_VECTOR(15 downto 0);
		DAC_DATA_3	: in STD_LOGIC_VECTOR(15 downto 0);

		--input clk from DAC
		DAC_CLOCK_P	: OUT STD_LOGIC;
		DAC_CLOCK_N	: OUT STD_LOGIC;

		--DAC interface output
		DAC_DATA_OUT_P	: out STD_LOGIC_VECTOR(15 downto 0);
		DAC_DATA_OUT_N	: out STD_LOGIC_VECTOR(15 downto 0);
        SYNCP : out STD_LOGIC;
        SYNCN : out STD_LOGIC;
		--
		RESET           : in  STD_LOGIC;

		--System Clock from ADC interface
        SYS_CLK 	    : in STD_LOGIC; --sysclock
        FPGA_CLKP       : IN STD_LOGIC;
        FPGA_CLKN       : IN STD_LOGIC
		);
	end DAC_INTERFACE;

architecture Behavioral of DAC_INTERFACE is
	
	signal dac_clk 		: STD_LOGIC;
	signal clk1_ghz     : STD_LOGIC;
	signal dac_data_out : STD_LOGIC_VECTOR(15 downto 0);
	signal sync         : STD_LOGIC;
	
	component pll_250HZz_to_500MHz
    port
     (-- Clock in ports
      -- Clock out ports
      DAC_CLK          : out    std_logic;
      -- Status and control signals
      RESET             : in     std_logic;
      LOCKED            : out    std_logic;
      SYS_CLK           : in     std_logic
     );
    end component;


	begin



	process(RESET, SYS_CLK)
		begin
			if RESET = '1' then
		      sync <= '0';
			else 
				if rising_edge(SYS_CLK) then
                sync <= '1';
				end if;
			end if;
		end process;
                pll_250MHz_to_500MHz : pll_250HZz_to_500MHz -- 500 MHz to drive oserdes with the DAC CLK
                       port map ( 
                      -- Clock out ports  
                       DAC_CLK => dac_clk,
                      -- Status and control signals                
                       RESET => reset,
                       LOCKED => open,
                       -- Clock in ports
                       SYS_CLK => SYS_CLK
                     );
				--DAC Clo
	        	OBUFDS_inst_DACCLK : OBUFDS
		            generic map (
                    -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
		                IOSTANDARD      =>      "DEFAULT")
		            port map (
		                I               =>      dac_clk,           			-- Buffer output
		                O               =>      DAC_CLOCK_P,         		-- Diff_p buffer input (connect directly to top-level port)
		                OB              =>      DAC_CLOCK_N          		-- Diff_n buffer input (connect directly to top-level port)
	            	); 
                  	IBUFDS_inst_FPGA_CLK : IBUFDS -- 1 GHZ Clk
                  	  generic map (
                  	     DIFF_TERM => FALSE, -- Differential Termination 
                  	     IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
                  	     IOSTANDARD => "DEFAULT")
                  	  port map (
                  	     O => clk1_ghz,  -- Buffer output
                  	     I => FPGA_CLKP,  -- Diff_p buffer input (connect directly to top-level port)
                  	     IB => FPGA_CLKN -- Diff_n buffer input (connect directly to top-level port)
                  	  );
	            	

	            OSERDESloop : for i in 0 to 15 generate
					OSERDESE2_inst : OSERDESE2
						generic map (
							DATA_RATE_OQ => "DDR", -- DDR, SDR
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
							CLK => dac_clk, -- 1-bit input: High speed clock
							CLKDIV => SYS_CLK, -- 1-bit input: Divided clock
							-- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
							D1 => DAC_DATA_1(i),
							D2 => DAC_DATA_3(i),
							D3 => DAC_DATA_0(i),
							D4 => DAC_DATA_2(i),
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

			-- CONVERT DATA DAC TO Differential DATA
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
		        end generate OBUFDSloop; 
		        
                ObUFDS_SYNC : OBUFDS
                generic map (
                    IOSTANDARD      =>      "DEFAULT",                  -- Specify the output I/O standard
                    SLEW            =>      "SLOW")                     -- Specify the output slew rate
                port map (
                    O               =>      SYNCP,          -- Diff_p output (connect directly to top-level port)
                    OB              =>      SYNCN,         -- Diff_n output (connect directly to top-level port)
                    I               =>      sync           -- Buffer input    
                    );

		end Behavioral;

