----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2025 09:09:51
-- Design Name: 
-- Module Name: i2c_master - Behavioral
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

entity i2c_master is
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
end i2c_master;

architecture Behavioral of i2c_master is

    signal addr_shift   :   std_logic_vector(7 downto 0)    := (others => '0');
    signal data_shift   :   std_logic_vector(7 downto 0)    := (others => '0');
    signal slva_shift   :   std_logic_vector(7 downto 0)    := (others => '0');
    signal count        :   integer range 0 to 8            := 0;
    
    signal div          :   integer                         := 0;
    signal dsclk        :   std_logic                       := '1';
    signal psclk        :   std_logic                       := '1';
    signal fedge,redge  :   std_logic                       := '0';
    signal sdrive       :   std_logic                       := '1';
    
    signal drive        :   std_logic                       := '1';
    signal sdo          :   std_logic                       := '1';
    
    type fsm is(idle,
                start,
                s_addr,
                rd_ack,
                rw_addr,
                rd_ack2,
                wr_data,
                rd_ack3,
                rd_data,
                wr_ack,
                stop,
                re_start);
    signal state        :   fsm     := idle;
    
begin
    
    process (clk, rst)
    begin
    
        if rst = '1' then
            div <= 0;
            
        elsif rising_edge(clk) then
        
                if div < 9 then
                    div <= div + 1; 
                     
                else
                    div <= 0;
                end if;
                
        end if;
        
    end process;

    
    process (clk,rst)is
    begin
        if rst = '1' then
            psclk   <=  '1';
                    
        elsif rising_edge (clk)  then
        
            if state = idle and sdio = '1' then
                psclk   <=  '1';
                
            elsif state = start and sdio = '1' then
                psclk   <=  '1';
                
            else
            
                if div < 5 then
                    psclk   <=  '1';
                    
                else
                    psclk   <=  '0';
                    
                end if;
                
            end if;
                
        end if;
        
    end process;
    
    process (clk)is
    begin
        
        if rising_edge (clk) then
            dsclk   <=  psclk;
            
        end if;
        
    end process;        
    
    fedge   <=  (dsclk and (not psclk));
    redge   <=  (psclk and (not dsclk));
    
    sdio    <=  sdo     when drive = '1'    else 'Z';
    sclk    <=  psclk   when sdrive = '1'   else 'Z';
    
    process (clk,rst) is
    begin
    
        if rst = '1' then
            addr_shift  <=  (others => '0');
            data_shift  <=  (others => '0');
            slva_shift  <=  (others => '0');
            data_out    <=  (others => '0');
            count       <=  0;
            drive       <=  '1';
            sdrive      <=  '1';
            sdo         <=  '1';
            state       <=  idle;
            
        elsif rising_edge (clk) then
        
            case state is
            
                when idle =>
                        
                        if enable = '1' then
                            addr_shift  <=  addr;
                            data_shift  <=  data_in;
                            slva_shift  <=  slv_addr & r_w;
                            count       <=  0;
                            state       <=  start;
                            
                        else
                            state   <=  idle;
                            
                        end if;
                
                when start =>
                
                        sdo     <=  '0';
                        state   <=  s_addr;
                        
                when s_addr =>
                
                        if fedge = '1' then
                            sdo     <=  slva_shift(7);
                            slva_shift  <=  slva_shift(6 downto 0) & '0';
                            
                            if count = 8 then
                                count   <=  0;
                                drive   <=  '0';
                                state   <=  rd_ack;
                            
                            else
                                count   <=  count + 1;
                            
                            end if;
                            
                        end if;
                
                when rd_ack =>
                
                        if redge = '1' then
                        
                            if sdio = '0' then
                            
                                drive   <=  '1';
                                count   <=  0;
                                state   <=  rw_addr;
                                
                            else
                                drive   <=  '1';
                                state   <=  stop;
                                
                            end if;
                            
                        end if;
                
                when rw_addr =>
                
                        drive   <=  '1';
                        
                        if fedge = '1' then
                            sdo         <=  addr_shift(7);
                            addr_shift  <=  addr_shift(6 downto 0) & '0';
                            
                            if count = 8 then
                                drive   <=  '0';
                                state   <=  rd_ack2;
                                
                            else
                                count   <=  count + 1;
                            
                            end if;
                        
                        end if;
                                    
                when rd_ack2 =>
                
                        if redge = '1' then
                        
                            if sdio = '0' then
                                
                                if r_w = '0' then
                                    drive   <=  '1';
                                    count   <=  0;
                                    state   <=  wr_data;
                                    
                                elsif r_w = '1' then
                                    drive   <=  '0';
                                    count   <=  8;
                                    state   <=  rd_data;
                                    
--                                elsif r_w = '0' then
--                                    if r_w = '1' then
--                                        drive   <=  '1';
--                                        count   <=  0;
--                                        state   <=  re_start;
--                                    end if;
                                
--                                elsif r_w = '1' then
--                                    if r_w = '0' then
--                                        drive   <=  '1';
--                                        count   <=  0;
--                                        state   <=  re_start;
--                                    end if;
                                
                                end if;
                            
                            else
                                state   <=  stop;
                                
                            end if;
                            
                        end if;
                
                when re_start =>
                    sdo <= '1';
                    if psclk = '1' then
                        sdo        <= '0';              -- repeated START
                        slva_shift <= slv_addr & r_w;  -- READ
                        count      <= 7;
                        state      <= s_addr;
                    end if;
                
                when wr_data =>
                
                        if fedge = '1' then
                            sdo     <=  data_shift(7);
                            data_shift  <=  data_shift(6 downto 0) & '0';
                            
                            if count = 8 then
                                count   <=  0;
                                drive   <=  '0';
                                state   <=  rd_ack3;
                                
                            else
                                count   <=  count + 1;
                            
                            end if;
                        
                        end if;
                
                when rd_ack3 =>
                
                        if redge = '1' then
                        
                            if sdio =  '0' then
                                drive   <=  '0';
                                state   <=  stop;
                            end if;
                        
                        end if;
                
                when rd_data =>
                
                        if redge = '1' then
                            data_shift  <=  data_shift(6 downto 0) & sdio;
                        
                        end if;
                        
                        if fedge = '1' then
                        
                            if count = 0 then
                                data_out    <=  data_shift;
                                drive       <=  '1';
                                sdo         <=  '0';
                                state       <=  wr_ack;
                            
                            else
                                count       <=  count - 1;
                            
                            end if;
                            
                        end if;
                
                when wr_ack =>
                
                        if fedge = '1' then
                            drive   <=  '0';
                            state   <=  stop;
                        end if;
                    
                when stop =>
                
                        if redge = '1' then
                            drive   <=  '1';
                            sdo     <=  '1';
                            state   <=  idle;
                            
                        end if;
                    
                when others =>
                
                        state   <=  idle;
                    
            end case;
            
        end if;
    
    end process;
    
end Behavioral;
