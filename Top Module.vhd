----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2025 17:21:59
-- Design Name: 
-- Module Name: i2c_top_module - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_top_module is
    Port(clk        :   in std_logic;
         rst        :   in std_logic;
         enable     :   in std_logic;
         r_w        :   in std_logic;
         slv_addr   :   in std_logic_vector(6 downto 0);
         addr       :   in std_logic_vector(7 downto 0);
         data_in    :   in std_logic_vector(7 downto 0);
         
         data_out   :   out std_logic_vector(7 downto 0));
end i2c_top_module;

architecture Behavioral of i2c_top_module is
    
    component i2c_master is
        Port(clk        :   in std_logic;
             rst        :   in std_logic;
             enable     :   in std_logic;
             r_w        :   in std_logic;
             slv_addr   :   in std_logic_vector(6 downto 0);
             addr       :   in std_logic_vector(7 downto 0);
             data_in    :   in std_logic_vector(7 downto 0);
             
             sdio       :   inout std_logic;
             sclk       :   inout std_logic;
             data_out   :   out std_logic_vector(7 downto 0));
    end component;
    
    component i2c_slave is
        Port(clk    :   in std_logic;
             rst    :   in std_logic;
             
             sclk   :   inout std_logic;
             sdio   :   inout std_logic);    
    end component;
    
    signal sclk     :   std_logic       := '0';
    signal sdio     :   std_logic       := '0';
    
begin

    master: i2c_master
            port map(clk        =>  clk,
                     rst        =>  rst,
                     enable     =>  enable,
                     r_w        =>  r_w,
                     slv_addr   =>  slv_addr,
                     addr       =>  addr,
                     data_in    =>  data_in,
                     
                     sdio       =>  sdio,
                     sclk       =>  sclk,
                     data_out   =>  data_out);
    
    slave:  i2c_slave
            port map(clk        =>  clk,
                     rst        =>  rst,
                     sclk       =>  sclk,
                     
                     sdio       =>  sdio);

end Behavioral;
