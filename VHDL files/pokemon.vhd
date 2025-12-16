library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture Behavioral of pokemon is

    ----------------------------------------------------------------
    -- Components
    ----------------------------------------------------------------
    component clk_wiz_0
        port (
            clk_in1  : in  std_logic;
            clk_out1 : out std_logic
        );
    end component;

    component vga_sync
        port (
            pixel_clk : in  std_logic;
            red_in    : in  std_logic_vector(3 downto 0);
            green_in  : in  std_logic_vector(3 downto 0);
            blue_in   : in  std_logic_vector(3 downto 0);
            red_out   : out std_logic_vector(3 downto 0);
            green_out : out std_logic_vector(3 downto 0);
            blue_out  : out std_logic_vector(3 downto 0);
            hsync     : out std_logic;
            vsync     : out std_logic;
            pixel_row : out std_logic_vector(10 downto 0);
            pixel_col : out std_logic_vector(10 downto 0)
        );
    end component;

    component Intro
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
    end component;

    component chooseTeam
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
    end component;

    component battle
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
    end component;

    component Outro
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
    end component;

    component opponent
        port (
            player_p0 : in  std_logic_vector(2 downto 0);
            player_p1 : in  std_logic_vector(2 downto 0);
            player_p2 : in  std_logic_vector(2 downto 0);
            enemy_p0  : out std_logic_vector(2 downto 0);
            enemy_p1  : out std_logic_vector(2 downto 0);
            enemy_p2  : out std_logic_vector(2 downto 0)
        );
    end component;

    component alphabet
        port (
            char_code : in  std_logic_vector(5 downto 0);
            glyph_x   : in  std_logic_vector(2 downto 0);
            glyph_y   : in  std_logic_vector(2 downto 0);
            pixel_on  : out std_logic
        );
    end component;

    ----------------------------------------------------------------
    -- Internal signals
    ----------------------------------------------------------------
    signal clk_pixel : std_logic;

    -- VGA timing
    signal pix_row   : std_logic_vector(10 downto 0);
    signal pix_col   : std_logic_vector(10 downto 0);

    -- scene colors before caption overlay
    signal scene_base_r, scene_base_g, scene_base_b : std_logic_vector(3 downto 0);
    -- final colors after overlay
    signal scene_r, scene_g, scene_b : std_logic_vector(3 downto 0);

    signal vga_r,   vga_g,   vga_b   : std_logic_vector(3 downto 0);

    -- Intro outputs
    signal intro_r, intro_g, intro_b : std_logic_vector(3 downto 0);
    signal intro_done       : std_logic := '0';
    signal intro_done_prev  : std_logic := '0';

    -- ChooseTeam outputs
    signal choose_r, choose_g, choose_b : std_logic_vector(3 downto 0);
    signal choose_done       : std_logic := '0';
    signal choose_done_prev  : std_logic := '0';
    signal team_p0, team_p1, team_p2    : std_logic_vector(2 downto 0);

    -- Opponent team
    signal enemy_p0, enemy_p1, enemy_p2 : std_logic_vector(2 downto 0);

    -- Battle outputs
    signal battle_r, battle_g, battle_b : std_logic_vector(3 downto 0);
    signal battle_done       : std_logic := '0';
    signal battle_done_prev  : std_logic := '0';
    signal player_win_s, enemy_win_s    : std_logic;
    signal hp_data                      : std_logic_vector(15 downto 0);
    signal battle_active                : std_logic;

    -- Outro outputs
    signal outro_r, outro_g, outro_b : std_logic_vector(3 downto 0);
    signal outro_done       : std_logic := '0';
    signal outro_done_prev  : std_logic := '0';

    -- Game state
    type game_state_t is (ST_INTRO, ST_CHOOSE, ST_BATTLE, ST_OUTRO);
    signal game_state : game_state_t := ST_INTRO;

    -- Caption / alphabet
    signal cap_char_code : std_logic_vector(5 downto 0) := (others => '1');
    signal glyph_x_s     : std_logic_vector(2 downto 0) := (others => '0');
    signal glyph_y_s     : std_logic_vector(2 downto 0) := (others => '0');
    signal cap_on        : std_logic;

    -- handy constants for characters (using 0-9, A-Z mapping)
    constant CH_0  : std_logic_vector(5 downto 0) := "000000"; -- 0
    constant CH_1  : std_logic_vector(5 downto 0) := "000001"; -- 1
    constant CH_A  : std_logic_vector(5 downto 0) := "001010"; -- 10
    constant CH_B  : std_logic_vector(5 downto 0) := "001011"; -- 11
    constant CH_D  : std_logic_vector(5 downto 0) := "001101"; -- 13
    constant CH_E  : std_logic_vector(5 downto 0) := "001110"; -- 14
    constant CH_I  : std_logic_vector(5 downto 0) := "010010"; -- 18
    constant CH_M  : std_logic_vector(5 downto 0) := "010110"; -- 22
    constant CH_N  : std_logic_vector(5 downto 0) := "010111"; -- 23
    constant CH_O  : std_logic_vector(5 downto 0) := "011000"; -- 24
    constant CH_R  : std_logic_vector(5 downto 0) := "011011"; -- 27
    constant CH_T  : std_logic_vector(5 downto 0) := "011101"; -- 29
    constant CH_SP : std_logic_vector(5 downto 0) := "111111"; -- blank (out of range)

begin

    ----------------------------------------------------------------
    -- Clock wizard
    ----------------------------------------------------------------
    u_clk : clk_wiz_0
        port map (
            clk_in1  => clk_in,
            clk_out1 => clk_pixel
        );

    ----------------------------------------------------------------
    -- VGA timing generator
    ----------------------------------------------------------------
    u_vga : vga_sync
        port map (
            pixel_clk => clk_pixel,
            red_in    => scene_r,
            green_in  => scene_g,
            blue_in   => scene_b,
            red_out   => vga_r,
            green_out => vga_g,
            blue_out  => vga_b,
            hsync     => VGA_hsync,
            vsync     => VGA_vsync,
            pixel_row => pix_row,
            pixel_col => pix_col
        );

    VGA_red   <= vga_r;
    VGA_green <= vga_g;
    VGA_blue  <= vga_b;

    ----------------------------------------------------------------
    -- Scene modules
    ----------------------------------------------------------------

    u_intro : Intro
        port map (
            clk        => clk_pixel,
            pixel_row  => pix_row,
            pixel_col  => pix_col,
            btnc       => btnc,
            red        => intro_r,
            green      => intro_g,
            blue       => intro_b,
            done       => intro_done
        );

    u_choose : chooseTeam
        port map (
            clk        => clk_pixel,
            pixel_row  => pix_row,
            pixel_col  => pix_col,
            btnu       => btnu,
            btnd       => btnd,
            btnl       => btnl,
            btnr       => btnr,
            btnc       => btnc,
            red        => choose_r,
            green      => choose_g,
            blue       => choose_b,
            team_p0    => team_p0,
            team_p1    => team_p1,
            team_p2    => team_p2,
            done       => choose_done
        );

    u_opp : opponent
        port map (
            player_p0 => team_p0,
            player_p1 => team_p1,
            player_p2 => team_p2,
            enemy_p0  => enemy_p0,
            enemy_p1  => enemy_p1,
            enemy_p2  => enemy_p2
        );

    battle_active <= '1' when game_state = ST_BATTLE else '0';

    u_battle : battle
        port map (
            clk         => clk_pixel,
            active      => battle_active,
            pixel_row   => pix_row,
            pixel_col   => pix_col,
            player_p0   => team_p0,
            player_p1   => team_p1,
            player_p2   => team_p2,
            enemy_p0    => enemy_p0,
            enemy_p1    => enemy_p1,
            enemy_p2    => enemy_p2,
            btnu        => btnu,
            btnd        => btnd,
            btnl        => btnl,
            btnr        => btnr,
            btnc        => btnc,
            red         => battle_r,
            green       => battle_g,
            blue        => battle_b,
            player_win  => player_win_s,
            enemy_win   => enemy_win_s,
            done        => battle_done,
            hp_summary  => hp_data
        );

    u_outro : Outro
        port map (
            clk        => clk_pixel,
            pixel_row  => pix_row,
            pixel_col  => pix_col,
            btnc       => btnc,
            player_win => player_win_s,
            enemy_win  => enemy_win_s,
            red        => outro_r,
            green      => outro_g,
            blue       => outro_b,
            done       => outro_done
        );

    ----------------------------------------------------------------
    -- Alphabet instance (for captions, now always blank)
    ----------------------------------------------------------------
    u_alpha : alphabet
        port map (
            char_code => cap_char_code,
            glyph_x   => glyph_x_s,
            glyph_y   => glyph_y_s,
            pixel_on  => cap_on
        );

    ----------------------------------------------------------------
    -- Game state machine with edge-detected "done"
    ----------------------------------------------------------------
    process(clk_pixel)
        variable intro_rise  : boolean;
        variable choose_rise : boolean;
        variable battle_rise : boolean;
        variable outro_rise  : boolean;
    begin
        if rising_edge(clk_pixel) then
            intro_rise  := (intro_done  = '1' and intro_done_prev  = '0');
            choose_rise := (choose_done = '1' and choose_done_prev = '0');
            battle_rise := (battle_done = '1' and battle_done_prev = '0');
            outro_rise  := (outro_done  = '1' and outro_done_prev  = '0');

            case game_state is
                when ST_INTRO =>
                    if intro_rise then
                        game_state <= ST_CHOOSE;
                    end if;

                when ST_CHOOSE =>
                    if choose_rise then
                        game_state <= ST_BATTLE;
                    end if;

                when ST_BATTLE =>
                    if battle_rise then
                        game_state <= ST_OUTRO;
                    end if;

                when ST_OUTRO =>
                    if outro_rise then
                        game_state <= ST_INTRO;
                    end if;
            end case;

            intro_done_prev  <= intro_done;
            choose_done_prev <= choose_done;
            battle_done_prev <= battle_done;
            outro_done_prev  <= outro_done;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Scene base color mux
    ----------------------------------------------------------------
    process(game_state, intro_r, intro_g, intro_b,
            choose_r, choose_g, choose_b,
            battle_r, battle_g, battle_b,
            outro_r,  outro_g,  outro_b,
            hp_data)
    begin
        scene_base_r <= (others => '0');
        scene_base_g <= (others => '0');
        scene_base_b <= (others => '0');

        case game_state is
            when ST_INTRO =>
                scene_base_r <= intro_r;
                scene_base_g <= intro_g;
                scene_base_b <= intro_b;

            when ST_CHOOSE =>
                scene_base_r <= choose_r;
                scene_base_g <= choose_g;
                scene_base_b <= choose_b;

            when ST_BATTLE =>
                scene_base_r <= battle_r;
                scene_base_g <= battle_g;
                scene_base_b <= battle_b;

            when ST_OUTRO =>
                scene_base_r <= outro_r;
                scene_base_g <= outro_g;
                scene_base_b <= outro_b;
        end case;
    end process;

    ----------------------------------------------------------------
    -- Caption overlay DISABLED: just pass scene_base_* through
    ----------------------------------------------------------------
    process(scene_base_r, scene_base_g, scene_base_b,
            pix_row, pix_col, game_state, cap_on)
        variable r, g, b  : std_logic_vector(3 downto 0);
    begin
        -- forward the base scene colors (no bar, no text)
        r := scene_base_r;
        g := scene_base_g;
        b := scene_base_b;

        -- keep alphabet idle (no visible characters)
        cap_char_code <= CH_SP;
        glyph_x_s     <= (others => '0');
        glyph_y_s     <= (others => '0');

        scene_r <= r;
        scene_g <= g;
        scene_b <= b;
    end process;

end architecture Behavioral;
