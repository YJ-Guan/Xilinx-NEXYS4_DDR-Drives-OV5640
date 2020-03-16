library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity top is
  Port ( 
  pclk:in std_logic;
  vsync:in std_logic;
  href:in std_logic;
  d:in std_logic_vector (7 downto 0 );
  i:in std_logic;
  rst_n:in std_logic;
  config_finished:out std_logic;
  sioc:out std_logic;
  siod:inout std_logic;
  reset:out std_logic;
  pwdn:out std_logic;
  xclk:out std_logic;
  vga_hsync:out std_logic;
  vga_vsync:out std_logic;
  vga_r:out std_logic_vector ( 3 downto 0);
  vga_g:out std_logic_vector( 3 downto 0);
  vga_b:out std_logic_vector( 3 downto 0);
  sys_clock: in std_logic
  );
end top;

architecture Behavioral of top is


component ov5640_vga is
    port ( 
        clk25       : in  STD_LOGIC;
        vga_red     : out STD_LOGIC_VECTOR(3 downto 0);
        vga_green   : out STD_LOGIC_VECTOR(3 downto 0);
        vga_blue    : out STD_LOGIC_VECTOR(3 downto 0);
        vga_hsync   : out STD_LOGIC;
        vga_vsync   : out STD_LOGIC;
        frame_addr  : out STD_LOGIC_VECTOR(17 downto 0);
        frame_pixel : in  STD_LOGIC_VECTOR(11 downto 0)
    );
end component;

component ov5640_capture is
    port (
        pclk  : in   std_logic;
        vsync : in   std_logic;
        href  : in   std_logic;
        d     : in   std_logic_vector ( 7 downto 0);
        addr  : out  std_logic_vector (17 downto 0);
        dout  : out  std_logic_vector (11 downto 0);
        we    : out  std_logic
    );
end component;

component clk_wiz_0 is
    port (
    clk_out1: out std_logic;
    clk_out2: out std_logic;
    clk_out3: out std_logic;
    clk_in1    :in std_logic;
    reset   :in std_logic
  );
  end component;
  
  component blk_mem_gen_0 IS
    PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
    end component;
    
    component power_on_delay is 
        port(
        clk_50M: in std_logic;
         camera1_rstn: out std_logic;
         camera_pwnd: out std_logic;
         initial_en: out std_logic;
         reset_n: in std_logic
        ); 
  END component;
  
     component reg_config is
     port(     
           clk_25M: in std_logic;
           camera_rstn: in std_logic;
           initial_en: in std_logic;
           reg_conf_done :out std_logic;
           i2c_sclk: out std_logic;
            i2c_sdat: inout std_logic
       );
    end component;
  
  signal clk_24m:std_logic;
  signal clk_25m:std_logic;
  signal clk_50m:std_logic;
  signal o_t:std_logic;
  signal we_t:std_logic_vector ( 0 downto 0);
  signal dout_t:std_logic_vector ( 11 downto 0 );
  signal addr_t:std_logic_vector (17 downto 0);
  signal frame_addr_t:std_logic_vector (17 downto 0);
  signal frame_pixel_t:std_logic_vector ( 11 downto 0 );
   signal reset_t:std_logic;
  signal initial_en_t:std_logic;
  signal rst_n_not:std_logic;
begin
    xclk<=clk_25m;
    reset<=reset_t;
    rst_n_not<=not(rst_n);
    bram:blk_mem_gen_0
    port map(
    clka    =>pclk,
    wea     =>we_t,
    dina    =>dout_t,
    addra   =>addr_t,
    addrb   =>frame_addr_t,
    clkb    =>clk_24m,
    doutb     =>frame_pixel_t
    );
    
    clk:clk_wiz_0
    port map(
    reset   =>rst_n_not,
    clk_out1    =>clk_24m,
    clk_out2    =>clk_25m,
    clk_out3    =>clk_50m,
    clk_in1     =>sys_clock
    );
    
    capture:ov5640_capture
    port map(
        pclk  =>    pclk,
        vsync =>    vsync,
        href  =>    href,
        d     =>    d,
        addr  =>    addr_t,
        dout  =>    dout_t,
        we    =>    we_t(0)
        );
        
         
      
     vga: ov5640_vga 
          port map( 
              clk25       =>clk_25m,
              vga_red     =>vga_r,
              vga_green  =>vga_g,
              vga_blue    =>vga_b ,
              vga_hsync   =>vga_hsync,
              vga_vsync   =>vga_vsync,
              frame_addr  =>frame_addr_t,
              frame_pixel =>frame_pixel_t
            );
      
          power:power_on_delay 
                port map(
                reset_n=>rst_n,
                clk_50M =>clk_25m,
                 camera1_rstn=>reset_t,
                 camera_pwnd=> pwdn,
                     initial_en=>initial_en_t
                ); 
      
           config:reg_config 
                port map(     
                      clk_25M   => clk_25m,
                      camera_rstn   =>reset_t,
                      initial_en    =>initial_en_t,
                      reg_conf_done =>config_finished,
                      i2c_sclk=>sioc,
                       i2c_sdat=>siod
                  );
end Behavioral;
