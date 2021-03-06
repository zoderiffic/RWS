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
        DAC_DATA_OUT_P : out STD_LOGIC_VECTOR (15 downto 0);    -- EVEN 0, 2, 4, etc
        DAC_DATA_OUT_N : out STD_LOGIC_VECTOR (15 downto 0);    -- ODD  1, 3, 5..

        --DAC CLK to control the timing of samples sent to DAC in as LVDS
        DAC_CLOCK_P : out STD_LOGIC;
        DAC_CLOCK_N : out STD_LOGIC;
    
        -- CONTROLS TO THE DAC
        CLK_FROM_DAC_P : IN STD_LOGIC;
        CLK_FROM_DAC_N : IN STD_LOGIC;
        SYNCP : out STD_LOGIC;
        SYNCN : out STD_LOGIC;
--        DCLKP : out STD_LOGIC;
--        DCLKN : out STD_LOGIC;
        -- CLOCKs
        CLK_200MHz_N    : in STD_LOGIC;
        CLK_200MHz_P    : in STD_LOGIC;

        -- ADC DATA COMING IN AS LVDS
        ADC_DATA_IN_B_P : in STD_LOGIC_VECTOR (11 downto 0); -- EVEN 0, 2, 4...
        ADC_DATA_IN_B_N : in STD_LOGIC_VECTOR (11 downto 0); -- ODD  1, 3, 5...
        ADC_DATA_IN_A_P : in STD_LOGIC_VECTOR (11 downto 0); -- EVEN 0, 2, 4...
        ADC_DATA_IN_A_N : in STD_LOGIC_VECTOR (11 downto 0); -- ODD 1, 3, 5...

        	-- ADC CLK coming in as LVDS
    	ADC_CLOCK_A_P : in STD_LOGIC; --250 MHz clock output from ADC 
    	ADC_CLOCK_A_N : in STD_LOGIC;
    	
        LED_0         : out STD_LOGIC;
        LED_1         : out STD_LOGIC;
        LED_2         : out STD_LOGIC;
        SW            : in  STD_LOGIC;
    	RESET 		  : in STD_LOGIC);


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
    signal place_holder     :   std_logic;

    signal dac_data_0_w		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_0
    signal dac_data_1_w		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_1
    signal dac_data_2_w		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_2 
    signal dac_data_3_w		:	std_logic_vector (15 downto 0);		-- DAC Data converted to 16bits from adc_data_3   
    --signal dac_clk			  : std_logic;							--NEED TO FIND OUT WHERE THIS COME'S FROM
    signal clk_200MHz     : std_logic;
    signal clk_250MHz     : std_logic;         
    signal clk_500MHz     : std_logic;    
    signal pll_lock       : std_logic;     
    signal sys_reset      : std_logic;
    signal clk_500mhz_180 : std_logic;
         
    signal adc_clk        : std_logic;

	component ADC_INTERFACE
		Port (
			--input from ADC
			ADC_DATA_IN_B_P	: in STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_IN_B_N	: in STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_IN_A_P : in STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_IN_A_N : in STD_LOGIC_VECTOR(11 downto 0);

			--clock input from ADC
			--ADC_CLOCK_A_P	: in STD_LOGIC;
			--ADC_CLOCK_A_N	: in STD_LOGIC;

			--Interface ADC output
			ADC_DATA_0	: out STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_1	: out STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_2	: out STD_LOGIC_VECTOR(11 downto 0);
			ADC_DATA_3	: out STD_LOGIC_VECTOR(11 downto 0);

			--clock output from interface
			SYS_CLK 	: in STD_LOGIC;
			RESET       : in STD_LOGIC
			);
		end component;

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


	component DAC_INTERFACE
		Port(
			--input from DSP block
			DAC_DATA_0	: in STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_1	: in STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_2	: in STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_3	: in STD_LOGIC_VECTOR(15 downto 0);

			--500MHz Clk to drive OSERDES DDR
			DAC_CLOCK_P	: out STD_LOGIC;
			DAC_CLOCK_N	: out STD_LOGIC;

			--DAC interface output
			DAC_DATA_OUT_P	: out STD_LOGIC_VECTOR(15 downto 0);
			DAC_DATA_OUT_N	: out STD_LOGIC_VECTOR(15 downto 0);
            SYNCP : out STD_LOGIC;
            SYNCN : out STD_LOGIC;

			--
			RESET           : in std_logic;
            
			--Clocks
			SYS_CLK  	: in STD_LOGIC; --sysclock
			DAC_CLK     : In STD_LOGIC;
			DAC_CLK_180 : in std_logic;
			FPGA_CLKP   : IN STD_LOGIC;
			FPGA_CLKN   : IN STD_LOGIC

			);
		end component;
		
COMPONENT ila_0
        
        PORT (
            clk : IN STD_LOGIC;
        
        
        
            probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
            probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
            probe2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            probe3 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
        END COMPONENT  ;
        
        component clk_wiz_0
        port
         (-- Clock in ports
          -- Clock out ports
          clk_250mhz          : out    std_logic;
          clk_500mhz          : out    std_logic;
          clk_500mhz_180          : out    std_logic;
          -- Status and control signals
          reset             : in     std_logic;
          locked            : out    std_logic;
          clk_in1_p         : in     std_logic;
          clk_in1_n         : in     std_logic
         );
        end component;

component blink_led is
    Port ( CLK : in STD_LOGIC;
           LED : OUT STD_LOGIC);
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
			RESET 		=> sys_reset,

			--clk
			SYS_CLK		=> clk_250Mhz,
			

			--DAC out
			DAC_DATA_0 	=> dac_data_0_w,
			DAC_DATA_1	=> dac_data_1_w,
			DAC_DATA_2	=> dac_data_2_w,
			DAC_DATA_3	=> dac_data_3_w
			);

	--ADC Interface instantiation
	ADC_Int_Block: ADC_INTERFACE
		Port map(
			--input from ADC
			ADC_DATA_IN_B_P	=> ADC_DATA_IN_B_P,
			ADC_DATA_IN_B_N	=> ADC_DATA_IN_B_N,
			ADC_DATA_IN_A_P => ADC_DATA_IN_A_P,
			ADC_DATA_IN_A_N => ADC_DATA_IN_A_N,

			--clock input from ADC
			--ADC_CLOCK_A_P	=> ADC_CLOCK_A_P,
			--ADC_CLOCK_A_N	=> ADC_CLOCK_A_N,

			--Interface ADC output
			ADC_DATA_0	=> adc_data_0,
			ADC_DATA_1	=> adc_data_1,
			ADC_DATA_2	=> adc_data_2,
			ADC_DATA_3	=> adc_data_3,

			--clock output from interface
			RESET       => sys_reset,
			SYS_CLK 	=> clk_250Mhz
			);

	--DAC Inteface instantiaion
	DAC_Int_Block: DAC_INTERFACE
		Port map (
			--input from DSP block
			DAC_DATA_0	=> dac_data_0_w,
			DAC_DATA_1	=> dac_data_1_w,
			DAC_DATA_2	=> dac_data_2_w,
			DAC_DATA_3	=> dac_data_3_w,

			--Ouput sample sync clk to DAC
			DAC_CLOCK_P	=> DAC_CLOCK_P,
			DAC_CLOCK_N	=> DAC_CLOCK_N,

			--DAC interface output
			DAC_DATA_OUT_P	=> DAC_DATA_OUT_P,
			DAC_DATA_OUT_N	=> DAC_DATA_OUT_N,
			RESET           => sys_reset, 
			SYNCP           => SYNCP,
            SYNCN           => SYNCN,

			--System Clock from ADC interface
			DAC_CLK_180     => clk_500Mhz_180,
			DAC_CLK         => clk_500Mhz,
			SYS_CLK	     	=> clk_250Mhz,
      FPGA_CLKP       => CLK_FROM_DAC_P,
      FPGA_CLKN       => CLK_FROM_DAC_N

			);


     CLK_200Mhz_Inst : IBUFGDS

   port map (
      O => clk_200MHz,   -- 1-bit output: Buffer output
      I => CLK_200MHz_P,   -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
      IB => CLK_200MHz_N  -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );
   
--   sys_clk_inst : sys_clk_250Mhz
--      port map ( 
--     -- Clock out ports  
--      sys_clk => place_holder,
--     -- Status and control signals                
--      reset => reset,
--      locked => open ,
--      -- Clock in ports
--      CLK_200MHz => CLK_200MHz
--    );
    
    
    
--    ADC Clock
clk_pll : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk_250mhz => clk_250Mhz,
   clk_500mhz => clk_500Mhz,
   clk_500mhz_180 => clk_500mhz_180,
  -- Status and control signals                
   reset => '0',
   locked => pll_lock,
   -- Clock in ports
   clk_in1_p => ADC_CLOCK_A_P,
   clk_in1_n => ADC_CLOCK_A_N
 );
                         --TO TEST
--  LED_2 <= RESET;
  sys_clk <= clk_250MHz;
                         
     led_adc_clk: blink_led
         port map (
              CLK => clk_250Mhz,
              LED => led_0
                );
     led_board_clk: blink_led
        port map (
           CLK => clk_500Mhz,
           LED => led_1
               );
               
               
               
chipscope_dac_data : ila_0
               PORT MAP (
                   clk => clk_250Mhz,
               
               
               
                   probe0 => dac_data_0_w, 
                   probe1 => dac_data_1_w, 
                   probe2 => dac_data_2_w,
                   probe3 => dac_data_3_w
               );


 sys_reset <= RESET or (not pll_lock);
 LED_2     <= pll_lock;
 
end Behavioral;
