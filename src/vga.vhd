library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Module Generates Video Sync Signals for Video Montor Interface
-- RGB and Sync outputs tie directly to monitor conector pins

entity vga is
	port(
			clk, reset										             : in std_logic;
			pixel                            : in std_logic_vector(23 downto 0);
			
			pixel_clock_out				              : out std_logic;												
			pixel_row, pixel_col						       : out std_logic_vector(9 downto 0);
			horiz_sync_out, vert_sync_out    : out std_logic; 
			vga_blank                        : out std_logic;
			red, green, blue                 : out std_logic_vector(7 downto 0)
		);					    		
end entity vga;

architecture behavioral of vga is
	signal horiz_sync, vert_sync, pixel_clock : std_logic := '0';
	signal video_on, video_on_v, video_on_h : std_logic := '0';
	signal h_count, v_count : std_logic_vector(9 DOWNTO 0) := (others => '0');

-- Horizontal Timing Constants  
	constant H_pixels_across : natural := 640;
	constant H_sync_low      : natural := 664;
	constant H_sync_high     : natural := 760;
	constant H_end_count     :	natural := 800;

-- Vertical Timing Constants
	constant V_pixels_down :	natural := 480;
	constant V_sync_low    : natural := 491;
	constant V_sync_high   :	natural := 493;
	constant V_end_count   :	natural := 525;

begin

-- divide 50MHz to 25Mhz for 640x480 resolution
clock_divide : process(clk) is
begin
	if (rising_edge(clk)) then
		pixel_clock <= not pixel_clock;
	end if;
end process clock_divide;		

-- video_on is high only when RGB pixel data is being displayed
-- used to blank color signals at screen edges during retrace
video_on <= video_on_H and video_on_V;

pixel_clock_out <= pixel_clock;
vga_blank <= video_on;

red <= pixel(23 downto 16);
green <= pixel(15 downto 8);
blue <= pixel(7 downto 0);

process(pixel_clock)
begin
	--WAIT UNTIL(pixel_clock_int'EVENT) AND (pixel_clock_int='1');
	if rising_edge(pixel_clock) then

    --Generate Horizontal and Vertical Timing Signals for Video Signal
    -- H_count counts pixels (#pixels across + extra time for sync signals)
    -- 
    --  Horiz_sync  ------------------------------------__________--------
    --  H_count     0                 #pixels            sync low      end
    
	  if (h_count = H_end_count) then
	    h_count <= "0000000000";
	  else
	    h_count <= h_count + 1;
	  end if;

    --Generate Horizontal Sync Signal using H_count
	  if (h_count <= H_sync_high) and (h_count >= H_sync_low) then
 	    horiz_sync <= '0';
	  else
 	  	 horiz_sync <= '1';
	  end if;

    --V_count counts rows of pixels (#pixel rows down + extra time for V sync signal)
    --  
    --  Vert_sync      -----------------------------------------------_______------------
    --  V_count         0                        last pixel row      V sync low       end
	  
	  if (v_count >= V_end_count) and (h_count >= H_sync_low) then
   		 v_count <= "0000000000";
		elsif (h_count = H_sync_low) then
   		 v_count <= v_count + 1;
 		end if;

    -- Generate Vertical Sync Signal using V_count
	  if (v_count <= V_sync_high) and (v_count >= V_sync_low) then
    		vert_sync <= '0';
	  else
  		  vert_sync <= '1';
	  end if;

    -- Generate Video on Screen Signals for Pixel Data
    -- Video on = 1 indicates pixel are being displayed
    -- Video on = 0 retrace - user logic can update pixel
    -- memory without needing to read memory for display
    
	  if (h_count < H_pixels_across) then
   	 	video_on_h <= '1';
   		 pixel_col <= h_count;
	  else
	   	video_on_h <= '0';
	  end if;

	  if (v_count <= V_pixels_down) then
    		video_on_v <= '1';
   	 	pixel_row <= v_count;
	  else
   	 	video_on_v <= '0';
	  end if;

-- Put all video signals through DFFs to elminate any small timing delays that cause a blurry image
	  horiz_sync_out <= horiz_sync;
	  vert_sync_out <= vert_sync;
	  
	end if;

end process;
end architecture behavioral;



--
-- Common Video Modes - pixel clock and sync counter values
--
--  Mode       Refresh  Hor. Sync    Pixel clock  Interlaced?  VESA?
--  ------------------------------------------------------------
--  640x480     60Hz      31.5khz     25.175Mhz       No         No
--  640x480     63Hz      32.8khz     28.322Mhz       No         No
--  640x480     70Hz      36.5khz     31.5Mhz         No         No
--  640x480     72Hz      37.9khz     31.5Mhz         No        Yes
--  800x600     56Hz      35.1khz     36.0Mhz         No        Yes
--  800x600     56Hz      35.4khz     36.0Mhz         No         No
--  800x600     60Hz      37.9khz     40.0Mhz         No        Yes
--  800x600     60Hz      37.9khz     40.0Mhz         No         No
--  800x600     72Hz      48.0khz     50.0Mhz         No        Yes
--  1024x768    60Hz      48.4khz     65.0Mhz         No        Yes
--  1024x768    60Hz      48.4khz     62.0Mhz         No         No
--  1024x768    70Hz      56.5khz     75.0Mhz         No        Yes
--  1024x768    70Hz      56.25khz    72.0Mhz         No         No
--  1024x768    76Hz      62.5khz     85.0Mhz         No         No
--  1280x1024   59Hz      63.6khz    110.0Mhz         No         No
--  1280x1024   61Hz      64.24khz   110.0Mhz         No         No
--  1280x1024   74Hz      78.85khz   135.0Mhz         No         No
--
-- Pixel clock within 5% works on most monitors.
-- Faster clocks produce higher refresh rates at the same resolution on
-- most new monitors up to the maximum rate.
-- Some older monitors may not support higher refresh rates
-- or may only sync at specific refresh rates - VESA modes most common.
-- Pixel clock within 5% works on most old monitors.
-- Refresh rates below 60Hz will have some flicker.
-- Bad values such as very high refresh rates may damage some monitors
-- that do not support faster refreseh rates - check monitor specs.
--
-- Small adjustments to the sync low count ranges can be used to move
-- video image left, right (H), down or up (V) on the monitor
--
--
-- 640x480@60Hz Non-Interlaced mode
-- Horizontal Sync = 31.5kHz
-- Timing: H=(0.95us, 3.81us, 1.59us), V=(0.35ms, 0.064ms, 1.02ms)
--
--	          clock     horizontal timing         vertical timing      flags
--             Mhz    pix.col low  high end    pix.rows low  high end
--640x480    25.175     640  664   760  800        480  491   493  525
--                              <->                        <->    
--  sync pulses: Horiz----------___------   Vert-----------___-------
--
-- Alternate 640x480@60Hz Non-Interlaced mode
-- Horizontal Sync = 31.5kHz
-- Timing: H=(1.27us, 3.81us, 1.27us) V=(0.32ms, 0.06ms, 1.05ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      25.175  640  672  768  800    480  490  492  525
--
--
-- 640x480@63Hz Non-Interlaced mode (non-standard)
-- Horizontal Sync = 32.8kHz
-- Timing: H=(1.41us, 1.41us, 5.08us) V=(0.24ms, 0.092ms, 0.92ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      28.322  640  680  720  864    480  488  491  521
--
--
-- 640x480@70Hz Non-Interlaced mode (non-standard)
-- Horizontal Sync = 36.5kHz
-- Timing: H=(1.27us, 1.27us, 4.57us) V=(0.22ms, 0.082ms, 0.82ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      31.5    640  680  720  864    480  488  491  521
--
--
-- VESA 640x480@72Hz Non-Interlaced mode
-- Horizontal Sync = 37.9kHz
-- Timing: H=(0.76us, 1.27us, 4.06us) V=(0.24ms, 0.079ms, 0.74ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      31.5    640  664  704  832    480  489  492  520
--
--
-- VESA 800x600@56Hz Non-Interlaced mode
-- Horizontal Sync = 35.1kHz
-- Timing: H=(0.67us, 2.00us, 3.56us) V=(0.03ms, 0.063ms, 0.70ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      36      800  824  896 1024    600  601  603  625
--
--
-- Alternate 800x600@56Hz Non-Interlaced mode
-- Horizontal Sync = 35.4kHz
-- Timing: H=(0.89us, 4.00us, 1.11us) V=(0.11ms, 0.057ms, 0.79ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      36      800  832  976 1016    600  604  606  634
--
--
-- VESA 800x600@60Hz Non-Interlaced mode
-- Horizontal Sync = 37.9kHz
-- Timing: H=(1.00us, 3.20us, 2.20us) V=(0.03ms, 0.106ms, 0.61ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      40      800  840  968 1056    600  601  605  628 +hsync +vsync
--
--
-- Alternate 800x600@60Hz Non-Interlaced mode
-- Horizontal Sync = 37.9kHz
-- Timing: H=(1.20us, 3.80us, 1.40us) V=(0.13ms, 0.053ms, 0.69ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      40      800 848 1000 1056     600  605  607  633
--
--
-- VESA 800x600@72Hz Non-Interlaced mode
-- Horizontal Sync = 48kHz
-- Timing: H=(1.12us, 2.40us, 1.28us) V=(0.77ms, 0.13ms, 0.48ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      50      800  856  976 1040    600  637  643  666  +hsync +vsync
--
--
-- VESA 1024x768@60Hz Non-Interlaced mode
-- Horizontal Sync = 48.4kHz
-- Timing: H=(0.12us, 2.22us, 2.58us) V=(0.06ms, 0.12ms, 0.60ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     65     1024 1032 1176 1344    768  771  777  806 -hsync -vsync
--
--
-- 1024x768@60Hz Non-Interlaced mode (non-standard dot-clock)
-- Horizontal Sync = 48.4kHz
-- Timing: H=(0.65us, 2.84us, 0.65us) V=(0.12ms, 0.041ms, 0.66ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     62     1024 1064 1240 1280   768  774  776  808
--
--
-- VESA 1024x768@70Hz Non-Interlaced mode
-- Horizontal Sync=56.5kHz
-- Timing: H=(0.32us, 1.81us, 1.92us) V=(0.05ms, 0.14ms, 0.51ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     75     1024 1048 1184 1328    768  771  777  806 -hsync -vsync
--
--
-- 1024x768@70Hz Non-Interlaced mode (non-standard dot-clock)
-- Horizontal Sync=56.25kHz
-- Timing: H=(0.44us, 1.89us, 1.22us) V=(0.036ms, 0.11ms, 0.53ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     72     1024 1056 1192 1280    768  770  776  806   -hsync -vsync
--
--
-- 1024x768@76Hz Non-Interlaced mode
-- Horizontal Sync=62.5kHz
-- Timing: H=(0.09us, 1.41us, 2.45us) V=(0.09ms, 0.048ms, 0.62ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     85     1024 1032 1152 1360    768  784  787  823
--
--
-- 1280x1024@59Hz Non-Interlaced mode (non-standard)
-- Horizontal Sync=63.6kHz
-- Timing: H=(0.36us, 1.45us, 2.25us) V=(0.08ms, 0.11ms, 0.65ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1280x1024   110     1280 1320 1480 1728   1024 1029 1036 1077
--
--
-- 1280x1024@61Hz, Non-Interlaced mode
-- Horizontal Sync=64.25kHz
-- Timing: H=(0.44us, 1.67us, 1.82us) V=(0.02ms, 0.05ms, 0.41ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1280x1024   110     1280 1328 1512 1712   1024 1025 1028 1054
--
--
-- 1280x1024@74Hz, Non-Interlaced mode
-- Horizontal Sync=78.85kHz
-- Timing: H=(0.24us, 1.07us, 1.90us) V=(0.04ms, 0.04ms, 0.43ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1280x1024   135     1280 1312 1456 1712   1024 1027 1030 1064
--
--	VGA female connector: 15 pin small "D" connector
--                   _________________________
--                   \   5   4   3   2   1   /
--                    \   10  X   8   7   6 /
--                     \ 15  14  13 12  11 /
--                      \_________________/
--   Signal Name    Pin Number   Notes
--   -----------------------------------------------------------------------
--   RED video          1        Analog signal, around 0.7 volt, peak-to-peak  75 ohm 
--   GREEN video        2        Analog signal, sround 0.7 volt, peak-to-peak  75 ohm 
--   BLUE video         3        Analog signal, around 0.7 volt, peak-to-peak  75 ohm
--   Monitor ID #2      4        
--   Digital Ground     5        Ground for the video system.
--   RED ground         6  \     The RGB color video signals each have a separate
--   GREEN ground       7  |     ground connection.  
--   BLUE ground        8  /      
--   KEY                9        (X = Not present)
--   SYNC ground       10        TTL return for the SYNC lines.
--   Monitor ID #0     11        
--   Monitor ID #1     12        
--   Horizontal Sync   13        Digital levels (0 to 5 volts, TTL output)
--   Vertical Sync     14        Digital levels (0 to 5 volts, TTL output)
--   Not Connected     15        (Not used)
--
