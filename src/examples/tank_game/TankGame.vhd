library IEEE;

use IEEE.std_logic_1164.all;
use WORK.TankGameConstants.all;

entity TankGame is
	port(
			CLOCK_50 										: in std_logic;
			RESET_N											: in std_logic;
			
			-- KEYBOARD
			KEYBOARD_CLK, KEYBOARD_DATA				: in std_logic;
	
			-- LCD
			LCD_DATA_BUS									: inout std_logic_vector(7 downto 0);
			LCD_E, LCD_ON, LCD_RS, LCD_RESET_LED	: out std_logic;
			LCD_SEC_LED										: out std_logic;
			LCD_RW											: buffer std_logic;
	
			--VGA 
			VGA_RED, VGA_GREEN, VGA_BLUE 					: out std_logic_vector(9 downto 0); 
			HORIZ_SYNC, VERT_SYNC, VGA_BLANK, VGA_CLK		: out std_logic

		);
end entity TankGame;

architecture structural of TankGame is

component pixelGenerator is
	port(
			clk, ROM_clk, rst_n, video_on, eof 				: in std_logic;
			pixel_row, pixel_column						    : in std_logic_vector(9 downto 0);
			
			tanks : in Sprites;
			bullets : in Sprites;
			
			red_out, green_out, blue_out					: out std_logic_vector(9 downto 0)
		);
end component pixelGenerator;

component VGA_SYNC is
	port(
			clock_50Mhz										: in std_logic;
			horiz_sync_out, vert_sync_out, 
			video_on, pixel_clock, eof						: out std_logic;												
			pixel_row, pixel_column						    : out std_logic_vector(9 downto 0)
		);
end component VGA_SYNC;

component ps2 is
	port( 	keyboard_clk, keyboard_data, clock_50MHz ,
			reset : in std_logic;--, read : in std_logic;
			scan_code : out std_logic_vector( 7 downto 0 );
			scan_readyo : out std_logic;
			hist3 : out std_logic_vector(7 downto 0);
			hist2 : out std_logic_vector(7 downto 0);
			hist1 : out std_logic_vector(7 downto 0);
			hist0 : out std_logic_vector(7 downto 0)
		);
end component ps2;

component de2lcd is
	PORT(reset, clk_50Mhz				: IN	STD_LOGIC;
		 LCD_RS, LCD_E, LCD_ON, RESET_LED, SEC_LED		: OUT	STD_LOGIC;
		 LCD_RW						: BUFFER STD_LOGIC;
		 DATA_BUS				: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		 SCORE_A					: IN INTEGER;
		 SCORE_B					: IN INTEGER;
		 MSG_SELECT : IN STD_LOGIC_VECTOR(1 downto 0));
end component de2lcd;
	
-- Signals for ps2 keyboard
signal ps2_scan_code, ps2_break : std_logic_vector(7 downto 0);
signal ps2_scan_readyo : std_logic;
signal msg_select : std_logic_vector(1 downto 0) := "00";

--Signals for VGA sync
signal pixel_row_int 										: std_logic_vector(9 downto 0);
signal pixel_column_int 									: std_logic_vector(9 downto 0);
signal video_on_int											: std_logic;
signal VGA_clk_int											: std_logic;
signal eof														: std_logic;

-- Game signals
signal tanks : Sprites;							-- Bottom tank is the 0 index
signal bullets : Sprites;						-- Bottom tank is the 0 index
signal scores : Scores;							-- Bottom tank is the 0 index
signal tank_speeds : Speeds;					-- Bottom tank is the 0 index
signal bullet_speeds : Speeds;				-- Bottom tank is the 0 index
signal GState : GameState := INIT;
signal bullet_init_pos : Positions;
signal bullet_visibility : Visibility := ('0','0');

begin

--------------------------------------------------------------------------------------------
	
	ps2_keyboard : ps2
		port map(KEYBOARD_CLK, KEYBOARD_DATA, CLOCK_50, RESET_N, ps2_scan_code, ps2_scan_readyo, open, open, ps2_break, open);

	de2lcd_display : de2lcd
		port map(RESET_N, CLOCK_50, LCD_RS, LCD_E, LCD_ON, LCD_RESET_LED, LCD_SEC_LED, LCD_RW, LCD_DATA_BUS, scores(0), scores(1), msg_select);
	
	videoGen : pixelGenerator
		port map(CLOCK_50, VGA_clk_int, RESET_N, video_on_int, eof, pixel_row_int, pixel_column_int, tanks, bullets, VGA_RED, VGA_GREEN, VGA_BLUE);
		
	
	state_updates: process(CLOCK_50, RESET_N) is
		variable motion_counter : integer := 0;
	begin
		if(RESET_N = '0') then
			GState <= INIT;
		elsif(rising_edge(CLOCK_50)) then
			if(GState = INIT) then
				-- Bottom Tank Initialization
				tanks(0).tlx <= 270;
				tanks(0).tly <= 240 - tank_cy_offset - 12;
				tanks(0).w <= tank_width;
				tanks(0).h <= tank_height;
				tanks(0).color <= color_red;
				tanks(0).visible <= '1';
				
				-- Top Tank Initialization
				tanks(1).tlx <= 270;
				tanks(1).tly <= 240 + tank_cy_offset - 12;
				tanks(1).w <= tank_width;
				tanks(1).h <= tank_height;
				tanks(1).color <= color_magenta;
				tanks(1).visible <= '1';
				
				-- Botom Bullet Initialization
				bullets(0).tlx <= 0;
				bullets(0).tly <= 0;
				bullets(0).w <= bullet_width;
				bullets(0).h <= bullet_height;
				bullets(0).color <= color_black;
				bullets(0).visible <= '0';
				
				-- Top Bullet Initialization
				bullets(1).tlx <= 0;
				bullets(1).tly <= 0;
				bullets(1).w <= bullet_width;
				bullets(1).h <= bullet_height;
				bullets(1).color <= color_black;
				bullets(1).visible <= '0';
				
				-- Reset the scores
				scores(0) <= 0;
				scores(1) <= 0;
				
				-- Reset the message
				msg_select <= "01";
				
				GState <= COMBAT;
			elsif(GState = COMBAT) then
				if(motion_counter = motion_cmax) then
					motion_counter := 0;
					
					-- Check Boundary Conditions
					if(tanks(0).tlx + tank_speeds(0) < 0) then
						tanks(0).tlx <= 0;
					elsif(tanks(0).tlx + tank_speeds(0) + tanks(0).w > SCREEN_WIDTH) then
						tanks(0).tlx <= SCREEN_WIDTH - tanks(0).w;
					else
						tanks(0).tlx <= tanks(0).tlx + tank_speeds(0);
					end if;
					
					if(tanks(1).tlx + tank_speeds(1) < 0) then
						tanks(1).tlx <= 0;
					elsif(tanks(1).tlx + tank_speeds(1) + tanks(1).w > SCREEN_WIDTH) then
						tanks(1).tlx <= SCREEN_WIDTH - tanks(1).w;
					else
						tanks(1).tlx <= tanks(1).tlx + tank_speeds(1);
					end if;
					
					if(bullet_visibility(0) = '1') then
						bullets(0).visible <= '1';
					end if;
					
					if(bullet_visibility(1) = '1') then
						bullets(1).visible <= '1';
					end if;
					
					-- Bullet Update with Collision Detection
					if(bullets(0).visible = '1') then
						if(tanks(1).tlx < bullets(0).tlx + bullets(0).w and bullets(0).tlx < tanks(1).tlx + tanks(1).w  and tanks(1).tly < bullets(0).tly + bullets(0).h and bullets(0).tly < tanks(1).tly + tanks(1).h) then -- collision(tanks(1),bullets(0))) then
							bullets(0).visible <= '0';
							scores(0) <= scores(0) + 1;
							if(scores(0) = 2) then
								GState <= OVER;
								-- msg_select <= "10";
							end if;
							bullets(0).tly <= tanks(0).tly + bullet_height + 50;
						elsif(bullets(0).tly + bullet_speed < 0) then
							bullets(0).visible <= '0';
							bullets(0).tly <= tanks(0).tly + bullet_height + 50;
						elsif(bullets(0).tly + bullet_speed > SCREEN_HEIGHT) then
							bullets(0).visible <= '0';
							bullets(0).tly <= tanks(0).tly + bullet_height + 1;
						else
							bullets(0).tly <= bullets(0).tly + bullet_speed;
							bullets(0).tlx <= bullet_init_pos(0);
						end if;
					else
						bullets(0).tly <= tanks(0).tly + bullet_height + 1;
					end if;
					
					if(bullets(1).visible = '1') then
						if(tanks(0).tlx < bullets(1).tlx + bullets(1).w and bullets(1).tlx < tanks(0).tlx + tanks(0).w  and tanks(0).tly < bullets(1).tly + bullets(1).h and bullets(1).tly < tanks(0).tly + tanks(0).h) then --(tanks(0),bullets(1))) then
							bullets(1).visible <= '0';
							scores(1) <= scores(1) + 1;
							if(scores(1) = 2) then
								GState <= OVER;
								-- msg_select <= "10";
							end if;
							bullets(1).tly <= tanks(1).tly + bullet_height;
						elsif(bullets(1).tly + bullet_speed < 0) then
							bullets(1).visible <= '0';
							bullets(1).tly <= tanks(1).tly - bullet_height - 1;
						elsif(bullets(1).tly + bullet_speed > SCREEN_HEIGHT) then
							bullets(1).visible <= '0';
							bullets(1).tly <= tanks(1).tly - bullet_height - 1;
						else
							bullets(1).tly <= bullets(1).tly - bullet_speed;
							bullets(1).tlx <= bullet_init_pos(1);
						end if;
					else
						bullets(1).tly <= tanks(1).tly - bullet_height - 1;
					end if;
					
				else
					motion_counter := motion_counter + 1;
				end if;
			elsif(GState = OVER) then
				if(scores(0) > scores(1)) then
					tanks(1).visible <= '0';
				else
					tanks(0).visible <= '0';
				end if;
				msg_select <= "10";
			else
				GState <= INIT;
			end if;
		end if;
	end process;
	
	-- This process is in charge of checking what messages should be displayed on the screen
	-- lcd_messages: process is
	-- 
	-- begin
	-- 
	-- end process;
	
	-- This process is in charge of checking for collisions and changing state accordingly (score updates)
	-- collision_detector: process is
	-- 
	-- begin
	-- 	wait;
	-- end process;
	
	-- This process is in charge of reading characters and changing state
	
	keyboard_scanner: process(ps2_scan_readyo, ps2_scan_code, ps2_break, GState) is
		variable p1_left_counter : integer := 0;
		variable p1_right_counter : integer := 0;
		variable p2_left_counter : integer := 0;
		variable p2_right_counter : integer := 0;
	begin
		if(GState = INIT) then
			tank_speeds(0) <= 0;
			tank_speeds(1) <= 0;
			bullet_visibility(0) <= '0';
			bullet_visibility(0) <= '0';
		elsif(GState = COMBAT) then
			if(ps2_scan_readyo'EVENT and ps2_scan_readyo = '1') then
				if(ps2_break /= X"F0" and ps2_scan_code /= X"F0") then
					-- Make Conditions
					if(ps2_scan_code = P1_left) then
						p1_right_counter := 0;
						if(p1_left_counter < 3) then
							tank_speeds(0) <= -tank_speed;
							p1_left_counter := p1_left_counter + 1;
						elsif(p1_left_counter < 6) then
							tank_speeds(0) <= -tank_speed-tank_speed;
							p1_left_counter := p1_left_counter + 1;
						else
							tank_speeds(0) <= -tank_speed-tank_speed-tank_speed;
						end if;
					elsif(ps2_scan_code = P1_right) then
						p1_left_counter := 0;
						if(p1_right_counter < 3) then
							tank_speeds(0) <= tank_speed;
							p1_right_counter := p1_right_counter + 1;
						elsif(p1_right_counter < 6) then
							tank_speeds(0) <= tank_speed+tank_speed;
							p1_right_counter := p1_right_counter + 1;
						else
							tank_speeds(0) <= tank_speed+tank_speed+tank_speed;
						end if;
					elsif(ps2_scan_code = P1_fire) then
						if(bullets(0).visible = '0' and bullet_visibility(0) = '0') then
							bullet_init_pos(0) <= tanks(0).tlx + tank_width/2;
							bullet_visibility(0) <= '1';
						end if;
					elsif(ps2_scan_code = P2_left) then
						p2_right_counter := 0;
						if(p2_left_counter < 3) then
							tank_speeds(1) <= -tank_speed;
							p2_left_counter := p2_left_counter + 1;
						elsif(p2_left_counter < 6) then
							tank_speeds(1) <= -tank_speed-tank_speed;
							p2_left_counter := p2_left_counter + 1;
						else
							tank_speeds(1) <= -tank_speed-tank_speed-tank_speed;
						end if;
					elsif(ps2_scan_code = P2_right) then
						p2_left_counter := 0;
						if(p2_right_counter < 3) then
							tank_speeds(1) <= tank_speed;
							p2_right_counter := p2_right_counter + 1;
						elsif(p2_right_counter < 6) then
							tank_speeds(1) <= tank_speed+tank_speed;
							p2_right_counter := p2_right_counter + 1;
						else
							tank_speeds(1) <= tank_speed+tank_speed+tank_speed;
						end if;
					elsif(ps2_scan_code = P2_fire) then
						if(bullets(1).visible = '0' and bullet_visibility(1) = '0') then
							bullet_init_pos(1) <= tanks(1).tlx + tank_width/2;
							bullet_visibility(1) <= '1';
						end if;
					else
						-- Do Nothing
						bullet_visibility(0) <= '0';
						bullet_visibility(1) <= '0';
					end if;
				else 
					bullet_visibility(0) <= '0';
					bullet_visibility(1) <= '0';
				end if;
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------------------
--This section should not be modified in your design.  This section handles the VGA timing signals
--and outputs the current row and column.  You will need to redesign the pixelGenerator to choose
--the color value to output based on the current position.

	videoSync : VGA_SYNC
		port map(CLOCK_50, HORIZ_SYNC, VERT_SYNC, video_on_int, VGA_clk_int, eof, pixel_row_int, pixel_column_int);

	VGA_BLANK <= video_on_int;

	VGA_CLK <= VGA_clk_int;

--------------------------------------------------------------------------------------------	

end architecture structural;