# VHDL Pokémon Battle Demo
*(For educational purposes only)*

**Made by Seongjun An and Matthew Suh**

## Project Overview
Our project recreates a simplified version of a Pokémon battle using VHDL and runs on a Nexys A7-100T FPGA board. The project is displayed on a monitor using a VGA to HDMI adapter plugged directly into the FPGA. The player is able to create a team of 3 Pokémon, choosing from 6 available Pokémon. The player then battles against a CPU trainer that also has a team of 3 Pokémon. The demo ends when the player defeats all of the CPU's Pokémon or when all of their Pokémon are defeated.

### Pokémon Selection Screen
![](/Media/pokeSelect.png)

### Controls
- BTNU: Move cursor up
- BTND: Move cursor down
- BTNL: Move cursor left
- BTNR: Move cursor right
- BTNC: Select/Attack

## Required Hardware/Software
- Digilent Nexys A7-100T FPGA Board
- Micro USB Cable
- VGA to HDMI Adapter
- HDMI Cable
- TV or Monitor with an HDMI input
- AMD Vivado™ Design Suite

## Visuals/Diagrams
### Video
[Full video of demo](https://youtu.be/rZIYxnwkLVs)

### Battle
![](/Media/battle.gif)

### Modules
![](/Media/diagram.png)

### FSM
![](/Media/fsm.png)

## Running the Project
1. Download the `.vhd` and `.xdc` files inside the folder **VHDL files**
2. Open Vivado and create a new RTL project
3. Add the `.vhd` files you just downloaded as sources
   - `pokemon.vhd` `vga_sync.vhd` `clk_wiz_0.vhd` `clk_wiz_0_clk_wiz.vhd` `alphabet.vhd`
   - `Intro.vhd` `chooseTeam.vhd` `battle.vhd` `Outro.vhd` `opponent.vhd`
   - `pikachu.vhd` `giratina.vhd` `empoleon.vhd` `garchomp.vhd` `torterra.vhd` `bidoof.vhd`
4. Add `pokemon.xdc` as a constraint file
5. Plug the Nexys A7 board into your computer
6. Connect the board to a monitor
7. Run Synthesis
8. Run Implementation
9. Generate Bitstream
10. Open Hardware Manager and Program the Device

## Inputs and Outputs
### pokemon.vhd
```vhdl
entity pokemon is
    port (
        clk_in      : in  std_logic;
        -- buttons
        btnu        : in  std_logic;
        btnd        : in  std_logic;
        btnl        : in  std_logic;
        btnr        : in  std_logic;
        btnc        : in  std_logic;
        -- VGA
        VGA_hsync   : out std_logic;
        VGA_vsync   : out std_logic;
        VGA_red     : out std_logic_vector(3 downto 0);
        VGA_green   : out std_logic_vector(3 downto 0);
        VGA_blue    : out std_logic_vector(3 downto 0)
    );
end entity pokemon;
```
**Inputs**
- `clk_in`: System clock (100 MHz)
- `btnu` `btnd` `btnl` `btnr` `btnc`: Buttons for navigation and selection/attack

**Outputs**
- `VGA_hsync` `VGA_vsync`: Horizontal and vertical signals for the display
- `VGA_red` `VGA_green` `VGA_blue`: Red, green, and blue color channels for VGA output

---

### Intro.vhd
```vhdl
entity Intro is
    port (
        clk        : in  std_logic;
        pixel_row  : in  std_logic_vector(10 downto 0);
        pixel_col  : in  std_logic_vector(10 downto 0);
        btnc       : in  std_logic;
        red        : out std_logic_vector(3 downto 0);
        green      : out std_logic_vector(3 downto 0);
        blue       : out std_logic_vector(3 downto 0);
        done       : out std_logic
    );
end entity;
```
**Inputs**
- `clk`: Pixel clock (25 MHz)
- `pixel_row` `pixel_col`: Vertical and horizontal pixel positioning on the display
- `btnc`: Button for advancing to the next screen

**Outputs**
- `red` `green` `blue`: Red, green, and blue color channels for VGA output
- `done`: Tells the program to advance to the next screen

---

### chooseTeam.vhd
```vhdl
entity chooseTeam is
    port (
        clk        : in  std_logic;
        pixel_row  : in  std_logic_vector(10 downto 0);
        pixel_col  : in  std_logic_vector(10 downto 0);
        btnu       : in  std_logic;
        btnd       : in  std_logic;
        btnl       : in  std_logic;
        btnr       : in  std_logic;
        btnc       : in  std_logic;
        red        : out std_logic_vector(3 downto 0);
        green      : out std_logic_vector(3 downto 0);
        blue       : out std_logic_vector(3 downto 0);
        team_p0    : out std_logic_vector(2 downto 0);
        team_p1    : out std_logic_vector(2 downto 0);
        team_p2    : out std_logic_vector(2 downto 0);
        done       : out std_logic
    );
end entity chooseTeam;
```
**Inputs**
- `clk`: Pixel clock (25 MHz) 
- `pixel_row` `pixel_col`: Vertical and horizontal pixel positioning on the display
- `btnu` `btnd` `btnl` `btnr` `btnc`: Buttons for navigation and selection

**Outputs**
- `red` `green` `blue`: Red, green, and blue color channels for VGA output
- `team_p0`: ID of the first Pokémon selected by the player  
- `team_p1`: ID of the second Pokémon selected by the player  
- `team_p2`: ID of the third Pokémon selected by the player  
- `done`: Tells the program to advance to the next screen

---

### battle.vhd
```vhdl
entity battle is
    port (
        clk         : in  std_logic;
        active      : in  std_logic;
        pixel_row   : in  std_logic_vector(10 downto 0);
        pixel_col   : in  std_logic_vector(10 downto 0);
        player_p0   : in  std_logic_vector(2 downto 0);
        player_p1   : in  std_logic_vector(2 downto 0);
        player_p2   : in  std_logic_vector(2 downto 0);
        enemy_p0    : in  std_logic_vector(2 downto 0);
        enemy_p1    : in  std_logic_vector(2 downto 0);
        enemy_p2    : in  std_logic_vector(2 downto 0);
        btnu        : in  std_logic;
        btnd        : in  std_logic;
        btnl        : in  std_logic;
        btnr        : in  std_logic;
        btnc        : in  std_logic;
        red         : out std_logic_vector(3 downto 0);
        green       : out std_logic_vector(3 downto 0);
        blue        : out std_logic_vector(3 downto 0);
        player_win  : out std_logic;
        enemy_win   : out std_logic;
        done        : out std_logic;
        hp_summary  : out std_logic_vector(15 downto 0)
    );
end entity;
```
**Inputs**
- `clk`: Pixel clock (25 MHz)
- `active`: Enable signal from the top-level FSM indicating the battle state is active
- `pixel_row` `pixel_col`: Vertical and horizontal pixel positioning on the display
- `player_p0` `player_p1` `player_p2`: Player’s Pokémon IDs  
- `enemy_p0` `enemy_p1` `enemy_p2`: Opponent’s Pokémon IDs
- `btnu` `btnd` `btnl` `btnr` `btnc`: Buttons for navigation and selection/attack

**Outputs**
- `red` `green` `blue`: Red, green, and blue color channels for VGA output
- `player_win`: Activated when player wins  
- `enemy_win`: Activated when opponent wins  
- `done`: Tells the program to advance to the next screen
- `hp_summary`: Summary of current Pokémon health values

---

### Outro.vhd
```vhdl
entity Outro is
    port (
        clk        : in  std_logic;
        pixel_row  : in  std_logic_vector(10 downto 0);
        pixel_col  : in  std_logic_vector(10 downto 0);
        btnc       : in  std_logic;
        player_win : in  std_logic;
        enemy_win  : in  std_logic;
        red        : out std_logic_vector(3 downto 0);
        green      : out std_logic_vector(3 downto 0);
        blue       : out std_logic_vector(3 downto 0);
        done       : out std_logic
    );
end entity;
```
**Inputs**
- `clk`: Pixel clock (25 MHz)
- `pixel_row` `pixel_col`: Vertical and horizontal pixel positioning on the display
- `btnc`: Button for advancing
- `player_win`: Indicates the player won the battle  
- `enemy_win`: Indicates the opponent won the battle  

**Outputs**
- `red` `green` `blue`: Red, green, and blue color channels for VGA output
- `done`: Tells the program to advance to the next screen

---

### alphabet.vhd
```vhdl
entity alphabet is
    port (
        char_code : in  std_logic_vector(5 downto 0); -- 0-9, A-Z
        glyph_x   : in  std_logic_vector(2 downto 0); -- 0..4
        glyph_y   : in  std_logic_vector(2 downto 0); -- 0..6
        pixel_on  : out std_logic                     -- '1' = draw
    );
end entity alphabet;
```
**Inputs**
- `char_code`: 6-bit character code selecting the glyph to draw (0–9, A–Z)  
- `glyph_x` `glyph_y`: Horizontal and vertical pixel index within the character glyph

**Outputs**
- `pixel_on`: Asserted when the selected glyph pixel should be drawn at the current glyph coordinates

---

### vga_sync.vhd
```vhdl
ENTITY vga_sync IS
	PORT (
		pixel_clk : IN STD_LOGIC;
		red_in    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		green_in  : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		blue_in   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		red_out   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		green_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		blue_out  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		hsync     : OUT STD_LOGIC;
		vsync     : OUT STD_LOGIC;
		pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
		pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
	);
END vga_sync;
```
**Inputs**
- `pixel_clk`: Pixel clock (25 MHz)
- `red_in` `green_in` `blue_in`: Red, green, and blue color values for the current pixel from the active scene  

**Outputs**
- `red_out` `green_out` `blue_out`: Red, green, and blue color values driven to the VGA connector  
- `hsync` `vsync`: Horizontal and vertical synchronization signal for the display  
- `pixel_row` `pixel_col`: Vertical and horizontal pixel positioning on the display

---

## Modifications
