----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2018 08:16:40 PM
-- Design Name: 
-- Module Name: adc_dac_interface_tb - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adc_dac_interface_tb is
--  Port ( );
end adc_dac_interface_tb;

architecture Behavioral of adc_dac_interface_tb is


    component top_wrapper
        port (
    -- DATA GOING GOING OUT TO THE DAC AS LVDS
        DAC_DATA_OUT_P :    out     STD_LOGIC_VECTOR (15 downto 0);    -- EVEN 0, 2, 4, etc
        DAC_DATA_OUT_N :    out     STD_LOGIC_VECTOR (15 downto 0);    -- ODD  1, 3, 5..
    
    
        -- CONTROLS TO THE DAC
        
              --DAC CLK coming in as LVDS
        DAC_CLOCK_P :       in      STD_LOGIC;
        DAC_CLOCK_N :       in      STD_LOGIC;
           	-- ADC CLK coming in as LVDS
        ADC_CLOCK_A_P:      in      STD_LOGIC; --250 MHz clock output from ADC 
        ADC_CLOCK_A_N  :    in      STD_LOGIC;
        RESET          :    in      STD_LOGIC;
 
  

        FPGA_CLKP :         out     STD_LOGIC;
        FPGA_CLKN :         out     STD_LOGIC;
        SYNCP :             out     STD_LOGIC;
        SYNCN :             out     STD_LOGIC;
        DCLKP :             out     STD_LOGIC;
        DCLKN :             out     STD_LOGIC;

        -- ADC DATA COMING IN AS LVDS
        ADC_DATA_IN_B_P :   in      STD_LOGIC_VECTOR (11 downto 0); -- EVEN 0, 2, 4, etc
        ADC_DATA_IN_B_N :   in      STD_LOGIC_VECTOR (11 downto 0); -- ODD  1, 3, 5..
        ADC_DATA_IN_A_P :   in      STD_LOGIC_VECTOR (11 downto 0); -- EV
        ADC_DATA_IN_A_N :   in      STD_LOGIC_VECTOR (11 downto 0));
    end component;
    
    
    signal clk_1GHz_p       :       std_logic := '0';
    signal clk_500MHz_p     :       std_logic := '0';
    signal clk_250Mhz_p     :       std_logic := '0';
    signal clk_1GHz_n       :       std_logic;
    signal clk_500MHz_n     :       std_logic;
    signal clk_250Mhz_n     :       std_logic;
    signal adc_data_a_p     :       std_logic_vector(11 downto 0);
    signal adc_data_a_n     :       std_logic_vector(11 downto 0);
    signal adc_data_b_p     :       std_logic_vector(11 downto 0);
    signal adc_data_b_n     :       std_logic_vector(11 downto 0);   
    signal dac_data_out_p   :       std_logic_vector(15 downto 0);
    signal dac_data_out_n   :       std_logic_vector(15 downto 0);
    signal reset            :       std_logic;
    signal adc_data_a_q     :       std_logic_vector(11 downto 0);
    signal adc_data_b_q     :       std_logic_vector(11 downto 0);

begin
reset <= '1', '0' after 10 ns;
    
    -- Simulated clocks.
    clk_500MHz_p  <= not clk_500MHz_p after 1 ns;
    clk_250Mhz_p  <= not clk_250MHz_p after 2 ns;
    clk_1GHz_p    <= not clk_1Ghz_p after 0.5 ns;

    tb_unit : top_wrapper 
    port map( 
        -- DATA GOING GOING OUT TO THE DAC AS LVDS
        DAC_DATA_OUT_P => dac_data_out_p,
        DAC_DATA_OUT_N => dac_data_out_n,  
        FPGA_CLKP  => open,
        FPGA_CLKN => open, 
        SYNCP => open, 
        SYNCN => open,
        DCLKP => open,
        DCLKN => open,
        --DAC CLK input
        DAC_CLOCK_P     => clk_1GHz_p,
        DAC_CLOCK_N     => clk_1GHz_n,
        -- ADC CLK input
        ADC_CLOCK_A_P  => clk_250MHz_p,
        ADC_CLOCK_A_N  => clk_250MHz_n,
        RESET          => reset, 
        -- ADC DATA COM
        ADC_DATA_IN_B_P => adc_data_b_p,
        ADC_DATA_IN_B_N => adc_data_b_n,
        ADC_DATA_IN_A_P => adc_data_a_p,
        ADC_DATA_IN_A_N => adc_data_a_n
        );
        
        --Counter for the datas going in;
        counter_data: process(clk_500MHz_p,reset)
        begin
              if Reset='1' then
                 adc_data_a_p <= (others => '0');
                 adc_data_b_p <= x"001";
              elsif(rising_edge(clk_500MHz_p)) then
                 adc_data_a_p <= adc_data_a_q;
                 adc_data_b_p <= adc_data_b_q;
                
              end if;
        end process;
        
        -- Combinational logics
        --Create negative LVDS Signals
        adc_data_a_n  <= not adc_data_a_p;
        adc_data_b_n  <= not adc_data_b_p;
        clk_1GHz_n    <= not clk_1GHz_p;     
        clk_500MHz_n  <= not clk_500MHz_p; 
        clk_250Mhz_n  <= not clk_250Mhz_p; 
        --ADC data a/b queued up with the next value;
        adc_data_a_q  <= adc_data_a_p + 2;
        adc_data_b_q  <= adc_data_b_p + 2;
        
        


end Behavioral;

