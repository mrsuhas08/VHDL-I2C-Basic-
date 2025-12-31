----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2025 15:17:10
-- Design Name: 
-- Module Name: i2c_slave - Behavioral
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
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_slave is
    Port(clk    :   in std_logic;
         rst    :   in std_logic;
         
         sclk   :   inout std_logic;
         sdio   :   inout std_logic);
end i2c_slave;

architecture Behavioral of i2c_slave is
    
    constant depth      :   integer                         := 2**8;
    constant address    :   std_logic_vector(6 downto 0)    := "1111111";
    
    signal addr_shift   :   std_logic_vector(7 downto 0)    := (others => '0');
    signal data_shift   :   std_logic_vector(7 downto 0)    := (others => '0');
    signal slva_shift   :   std_logic_vector(7 downto 0)    := (others => '0');
    signal count        :   integer range 0 to 9            := 0;
    
    signal dsclk        :   std_logic                       := '0';
    signal fedge,redge  :   std_logic                       := '0';
    signal sdrive       :   std_logic                       := '1';
    
    signal dsdio        :   std_logic                       := '0';
    signal drive        :   std_logic                       := '0';
    signal sdo          :   std_logic                       := '0';
    
    signal start_c      :   std_logic                       := '0';
    signal stop_c       :   std_logic                       := '0';
    
    type store is array (depth-1 downto 0) of std_logic_vector(7 downto 0);
    signal mem          :   store                           := (others => (others => '0'));
    signal reg_addr     :   std_logic_vector(7 downto 0)    := (others => '0');
    
    type fsm is(idle,
                s_addr,
                wr_ack,
                rw_addr,
                wr_ack2,
                wr_data,
                wr_ack3,
                rd_data,
                rd_ack);
    signal state        :   fsm     := idle;
    
begin
    process (clk) is
    begin
        if rising_edge(clk)then
            dsclk   <=  sclk;
            dsdio   <=  sdio;
        end if;
    end process;
    
    fedge   <=  (dsclk and (not sclk));
    redge   <=  (sclk and (not dsclk));
    
    sclk    <=  '0'     when    sdrive = '1'    else 'Z';
    sdio    <=  sdo     when    drive = '1'     else 'Z';
    
    start_c <= '1' when (sclk = '1' and dsdio = '1' and sdio = '0') else '0';
    stop_c  <= '1' when (sclk = '1' and dsdio = 'Z' and sdio = '1') else '0';

    
    process (clk,rst)is
    begin
        if rst = '1' then
            addr_shift  <=  (others => '0');
            data_shift  <=  (others => '0');
            slva_shift  <=  (others => '0');
            reg_addr    <=  (others => '0');
            count       <=  0;
            sdrive      <=  '0';
            drive       <=  '0';
            sdo         <=  '0';
            state       <=  idle;
        
        elsif rising_edge(clk) then
        
            if start_c = '1' then
                state       <= s_addr;
                count       <= 7;
                slva_shift  <= (others => '0');
                drive       <= '0';
            end if;
            
            if stop_c = '1' then
                state <= idle;
                drive <= '0';
            end if;

            case state is
            
                when idle =>
                    
                        sdo         <=  '1';
                        addr_shift  <=  (others => '0');
                        data_shift  <=  (others => '0');
                        slva_shift  <=  (others => '0');
                        reg_addr    <=  (others => '0');
                        count       <=  8;
                        drive       <=  '0';
                        sdrive      <=  '0';
                        
                when s_addr =>
                        
                        if redge = '1' then
                            slva_shift  <=  slva_shift(6 downto 0) & sdio;
                            
                        end if;
                        
                        if fedge = '1' then
                        
                            if count = 0 then
                                
                                if slva_shift(7 downto 1) = address then
                                    sdo     <=  '0';
                                    drive   <=  '1';
                                    state   <=  wr_ack;
                                    
                                else
                                    state   <=  idle;
                                    
                                end if;
                                
                            else
                                count   <=  count - 1;
                                
                            end if;
                            
                        end if;
                        
                when wr_ack =>
                
                        if fedge = '1' then
                            
                            if slva_shift(7 downto 1) = address then
                                drive   <=  '0';
                                count   <=  7;
                                state   <=  rw_addr;
                                
                            else
                                drive   <=  '0';
                                state   <=  idle;
                                
                            end if;
                            
                            
                        end if;
                
                when rw_addr =>
                
                        if redge = '1' then
                            addr_shift  <=  addr_shift(6 downto 0) & sdio;
                        
                        end if;
                        
                        if fedge = '1' then
                        
                            if count = 0 then
                                reg_addr    <=  addr_shift;
                                
                                if slva_shift(0) = '1' then
                                    data_shift  <=  mem(TO_INTEGER(unsigned(addr_shift)));
                                    drive       <=  '1';
                                    sdo         <=  '0';
                                    state       <=  wr_ack2;
                                    
                                elsif slva_shift(0) = '0' then
                                    data_shift  <=  (others => '0');
                                    drive       <=  '1';
                                    sdo         <=  '0';
                                    state       <=  wr_ack2;
                                    
                                end if;
                            
                            else
                                count   <=  count - 1;
                            
                            end if;
                            
                        end if;
                
                when wr_ack2 =>
                
                        if fedge = '1' then
                            
                            if slva_shift(0) = '0' then
                                count   <=  7;
                                drive   <=  '0';
                                state   <=  wr_data;
                            
                            elsif slva_shift(0) = '1' then
                                count   <=  8;
                                drive   <=  '1';
                                sdo     <=  data_shift(7);
                                state   <=  rd_data;
                            
                            end if;
                
                        end if;
                
                when wr_data =>
                
                        if redge = '1' then
                            data_shift  <=  data_shift(6 downto 0) & sdio;
                        
                        end if;
                        
                        if fedge = '1' then
                        
                            if count = 0 then
                                mem(TO_INTEGER(unsigned(reg_addr))) <=  data_shift;
                                count   <=  0;
                                drive   <= '1';
                                sdo     <=  '0';
                                state   <=  wr_ack3;
                            
                            else
                                count   <=  count - 1;
                            
                            end if;
                        
                        end if;
                
                when wr_ack3 =>
                
                        if fedge = '1' then
                            drive   <=  '0';
                            state   <=  idle;
                            
                        end if;
                
                when rd_data =>
                
                        if fedge = '1' then
                            sdo         <=  data_shift(6);
                            data_shift  <=  data_shift(6 downto 0) & '0';
                            
                            if count = 1 then
                                drive   <=  '0';
                                sdo     <=  '0';
                                state   <=  rd_ack;
                            
                            else
                                count   <=  count - 1;
                            
                            end if;
                                
                        end if;
                
                when rd_ack =>
                
                        if redge = '1' then
                        
                            if sdio = '0' then
                                sdo     <=  '1';
                                state   <=  idle;
                                
                            end if;
                            
                        end if;
                
                when others =>
                
                        state   <=  idle;
                
            end case;
        
        end if;
    
    end process;

end Behavioral;
