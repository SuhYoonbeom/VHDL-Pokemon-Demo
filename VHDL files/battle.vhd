library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- sprite packages
use work.pikachu_pkg.all;
use work.giratina_pkg.all;
use work.garchomp_pkg.all;
use work.empoleon_pkg.all;
use work.bidoof_pkg.all;
use work.torterra_pkg.all;

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

architecture Behavioral of battle is

    type hp8_array_t is array(0 to 2) of unsigned(7 downto 0);

    signal player_hp     : hp8_array_t := (others => (others => '0'));
    signal enemy_hp      : hp8_array_t := (others => (others => '0'));
    signal player_hp_bar : hp8_array_t := (others => (others => '0'));
    signal enemy_hp_bar  : hp8_array_t := (others => (others => '0'));

    signal player_idx  : integer range 0 to 2 := 0;
    signal enemy_idx   : integer range 0 to 2 := 0;

    signal p_hp8, p_atk8, p_def8, p_spd8 : std_logic_vector(7 downto 0);
    signal e_hp8, e_atk8, e_def8, e_spd8 : std_logic_vector(7 downto 0);

    signal rng_cnt  : unsigned(15 downto 0) := (others => '0');

    type round_state_t is (RS_IDLE, RS_FIRST, RS_WAIT, RS_SECOND);
    signal round_state : round_state_t := RS_IDLE;
    signal first_is_player : std_logic := '1';

    constant WAIT_MAX  : unsigned(27 downto 0) := to_unsigned(100000000, 28);
    signal wait_cnt    : unsigned(27 downto 0) := (others => '0');

    constant HP_ANIM_TICK : unsigned(26 downto 0) := to_unsigned(1562500, 27);
    signal player_anim_active : std_logic := '0';
    signal enemy_anim_active  : std_logic := '0';
    signal player_anim_cnt    : unsigned(26 downto 0) := (others => '0');
    signal enemy_anim_cnt     : unsigned(26 downto 0) := (others => '0');

    -- NEW: attack shake (0.25 s) and damage blink (0.25 s)
    signal player_attack_active : std_logic := '0';
    signal enemy_attack_active  : std_logic := '0';
    signal player_damage_active : std_logic := '0';
    signal enemy_damage_active  : std_logic := '0';

    signal player_attack_cnt    : unsigned(25 downto 0) := (others => '0');
    signal enemy_attack_cnt     : unsigned(25 downto 0) := (others => '0');
    signal player_damage_cnt    : unsigned(25 downto 0) := (others => '0');
    signal enemy_damage_cnt     : unsigned(25 downto 0) := (others => '0');

    -- attack timing: 0.25 s at 100 MHz (0.125s forward, 0.125s back)
    constant ATK_TOTAL : unsigned(25 downto 0) := to_unsigned(25000000, 26); -- 0.25 s
    constant ATK_HALF  : unsigned(25 downto 0) := to_unsigned(12500000, 26); -- 0.125 s

    -- damage blink timing: 0.25 s at 100 MHz (two flashes)
    constant DMG_TOTAL   : unsigned(25 downto 0) := to_unsigned(25000000, 26); -- 0.25 s
    constant DMG_QUARTER : unsigned(25 downto 0) := to_unsigned(6250000, 26);  -- 0.0625 s
    constant DMG_Q2      : unsigned(25 downto 0) := to_unsigned(12500000, 26); -- 0.125 s
    constant DMG_Q3      : unsigned(25 downto 0) := to_unsigned(18750000, 26); -- 0.1875 s

    -- NEW: faint slide (~0.5 s total, 40 steps)
    signal player_faint_active : std_logic := '0';
    signal enemy_faint_active  : std_logic := '0';
    signal player_faint_cnt    : unsigned(7 downto 0) := (others => '0');
    signal enemy_faint_cnt     : unsigned(7 downto 0) := (others => '0');
    constant FAINT_MAX         : unsigned(7 downto 0)  := to_unsigned(40, 8);

    signal player_faint_step_cnt : unsigned(23 downto 0) := (others => '0');
    signal enemy_faint_step_cnt  : unsigned(23 downto 0) := (others => '0');
    constant FAINT_STEP_TICKS    : unsigned(23 downto 0) := to_unsigned(1250000, 24); -- 0.0125 s per step -> ~0.5 s total

    signal btnc_prev, btnl_prev, btnr_prev : std_logic := '0';
    signal active_prev : std_logic := '0';

    signal player_win_s : std_logic := '0';
    signal enemy_win_s  : std_logic := '0';
    signal done_s       : std_logic := '0';

    signal game_over    : std_logic := '0';
    signal game_over_cnt: unsigned(27 downto 0) := (others => '0');

    constant ZERO8 : unsigned(7 downto 0) := (others => '0');

    ----------------------------------------------------------------
    -- sprite anchor positions in battle scene + scale
    ----------------------------------------------------------------
    constant ENEMY_X0      : integer := 490;  -- enemy on right
    constant ENEMY_Y0      : integer := 100;
    constant PLAYER_X0     : integer := 80;   -- player on left
    constant PLAYER_Y0     : integer := 240;
    constant ENEMY_SCALE   : integer := 3;
    constant PLAYER_SCALE  : integer := 4;

    ----------------------------------------------------------------
    -- ID HELPERS
    ----------------------------------------------------------------
    function player_id_at(idx : integer; a,b,c : std_logic_vector(2 downto 0))
        return std_logic_vector is
    begin
        case idx is
            when 0 => return a;
            when 1 => return b;
            when 2 => return c;
            when others => return a;
        end case;
    end function;

    function enemy_id_at(idx : integer; a,b,c : std_logic_vector(2 downto 0))
        return std_logic_vector is
    begin
        case idx is
            when 0 => return a;
            when 1 => return b;
            when 2 => return c;
            when others => return a;
        end case;
    end function;

    ----------------------------------------------------------------
    -- BASE STATS
    ----------------------------------------------------------------
    function base_hp8(p : std_logic_vector(2 downto 0)) return unsigned is
    begin
        case p is
            when "000" => return to_unsigned(40,8); -- Pikachu
            when "001" => return to_unsigned(60,8); -- Giratina
            when "010" => return to_unsigned(55,8); -- Empoleon
            when "011" => return to_unsigned(45,8); -- Garchomp
            when "100" => return to_unsigned(35,8); -- Torterra
            when "101" => return to_unsigned(65,8); -- Bidoof
            when others => return to_unsigned(40,8);
        end case;
    end function;

    function base_atk8(p : std_logic_vector(2 downto 0)) return unsigned is
    begin
        case p is
            when "000" => return to_unsigned(55,8);
            when "001" => return to_unsigned(70,8);
            when "010" => return to_unsigned(65,8);
            when "011" => return to_unsigned(40,8);
            when "100" => return to_unsigned(30,8);
            when "101" => return to_unsigned(70,8);
            when others => return to_unsigned(40,8);
        end case;
    end function;

    function base_def8(p : std_logic_vector(2 downto 0)) return unsigned is
    begin
        case p is
            when "000" => return to_unsigned(30,8);
            when "001" => return to_unsigned(60,8);
            when "010" => return to_unsigned(60,8);
            when "011" => return to_unsigned(50,8);
            when "100" => return to_unsigned(25,8);
            when "101" => return to_unsigned(70,8);
            when others => return to_unsigned(30,8);
        end case;
    end function;

    function base_spd8(p : std_logic_vector(2 downto 0)) return unsigned is
    begin
        case p is
            when "000" => return to_unsigned(90,8);
            when "001" => return to_unsigned(50,8);
            when "010" => return to_unsigned(50,8);
            when "011" => return to_unsigned(40,8);
            when "100" => return to_unsigned(30,8);
            when "101" => return to_unsigned(30,8);
            when others => return to_unsigned(40,8);
        end case;
    end function;

    ----------------------------------------------------------------
    -- 5x7 FONT (0-9, A-Z)
    ----------------------------------------------------------------
    subtype row_t   is std_logic_vector(4 downto 0);
    type    glyph_t is array(0 to 6) of row_t;
    type    font_t  is array(0 to 35) of glyph_t;

    constant FONT : font_t := (
         0 => ("01110","10001","10011","10101","11001","10001","01110"), -- '0'
         1 => ("00100","01100","00100","00100","00100","00100","01110"), -- '1'
         2 => ("01110","10001","00001","00010","00100","01000","11111"), -- '2'
         3 => ("01110","10001","00001","00110","00001","10001","01110"), -- '3'
         4 => ("00010","00110","01010","10010","11111","00010","00010"), -- '4'
         5 => ("11111","10000","11110","00001","00001","10001","01110"), -- '5'
         6 => ("01110","10000","11110","10001","10001","10001","01110"), -- '6'
         7 => ("11111","00001","00010","00100","01000","01000","01000"), -- '7'
         8 => ("01110","10001","10001","01110","10001","10001","01110"), -- '8'
         9 => ("01110","10001","10001","01111","00001","00010","01100"), -- '9'
        10 => ("01110","10001","10001","11111","10001","10001","10001"), -- 'A'
        11 => ("11110","10001","10001","11110","10001","10001","11110"), -- 'B'
        12 => ("01110","10001","10000","10000","10000","10001","01110"), -- 'C'
        13 => ("11100","10010","10001","10001","10001","10010","11100"), -- 'D'
        14 => ("11111","10000","10000","11110","10000","10000","11111"), -- 'E'
        15 => ("11111","10000","10000","11110","10000","10000","10000"), -- 'F'
        16 => ("01110","10001","10000","10000","10011","10001","01110"), -- 'G'
        17 => ("10001","10001","10001","11111","10001","10001","10001"), -- 'H'
        18 => ("11111","00100","00100","00100","00100","00100","11111"), -- 'I'
        19 => ("00001","00001","00001","00001","10001","10001","01110"), -- 'J'
        20 => ("10001","10010","10100","11000","10100","10010","10001"), -- 'K'
        21 => ("10000","10000","10000","10000","10000","10000","11111"), -- 'L'
        22 => ("10001","11011","10101","10101","10001","10001","10001"), -- 'M'
        23 => ("10001","11001","10101","10011","10001","10001","10001"), -- 'N'
        24 => ("01110","10001","10001","10001","10001","10001","01110"), -- 'O'
        25 => ("11110","10001","10001","11110","10000","10000","10000"), -- 'P'
        26 => ("01110","10001","10001","10001","10101","10010","01101"), -- 'Q'
        27 => ("11110","10001","10001","11110","10100","10010","10001"), -- 'R'
        28 => ("01111","10000","10000","01110","00001","00001","11110"), -- 'S'
        29 => ("11111","00100","00100","00100","00100","00100","00100"), -- 'T'
        30 => ("10001","10001","10001","10001","10001","10001","01110"), -- 'U'
        31 => ("10001","10001","10001","10001","10001","01010","00100"), -- 'V'
        32 => ("10001","10001","10001","10101","10101","11011","10001"), -- 'W'
        33 => ("10001","10001","01010","00100","01010","10001","10001"), -- 'X'
        34 => ("10001","10001","01010","00100","00100","00100","00100"), -- 'Y'
        35 => ("11111","00001","00010","00100","01000","10000","11111")  -- 'Z'
    );

    function font_pixel(
        char_code : std_logic_vector(5 downto 0);
        gx        : integer;  -- 0..4
        gy        : integer   -- 0..6
    ) return std_logic is
        variable idx    : integer;
        variable bitpos : integer;
    begin
        idx := to_integer(unsigned(char_code));
        if (idx >= 0 and idx <= 35) and
           (gx >= 0 and gx <= 4) and
           (gy >= 0 and gy <= 6) then
            bitpos := 4 - gx;
            if FONT(idx)(gy)(bitpos) = '1' then
                return '1';
            else
                return '0';
            end if;
        else
            return '0';
        end if;
    end function;

    ----------------------------------------------------------------
    -- Pokémon name encoding (MATCHED TO chooseTeam IDs!)
    ----------------------------------------------------------------
    function pokemon_char_code(
        poke_id   : std_logic_vector(2 downto 0);
        char_idx  : integer
    ) return std_logic_vector is
        variable code : std_logic_vector(5 downto 0);

        function C(n : integer) return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(n, 6));
        end function;
    begin
        case poke_id is
            -- "PIKACHU"
            when "000" =>
                case char_idx is
                    when 0 => code := C(25); -- P
                    when 1 => code := C(18); -- I
                    when 2 => code := C(20); -- K
                    when 3 => code := C(10); -- A
                    when 4 => code := C(12); -- C
                    when 5 => code := C(17); -- H
                    when 6 => code := C(30); -- U
                    when others => code := C(63);
                end case;

            -- "GIRATINA"
            when "001" =>
                case char_idx is
                    when 0 => code := C(16); -- G
                    when 1 => code := C(18); -- I
                    when 2 => code := C(27); -- R
                    when 3 => code := C(10); -- A
                    when 4 => code := C(29); -- T
                    when 5 => code := C(18); -- I
                    when 6 => code := C(23); -- N
                    when 7 => code := C(10); -- A
                    when others => code := C(63);
                end case;

            -- "EMPOLEON"
            when "010" =>
                case char_idx is
                    when 0 => code := C(14); -- E
                    when 1 => code := C(22); -- M
                    when 2 => code := C(25); -- P
                    when 3 => code := C(24); -- O
                    when 4 => code := C(21); -- L
                    when 5 => code := C(14); -- E
                    when 6 => code := C(24); -- O
                    when 7 => code := C(23); -- N
                    when others => code := C(63);
                end case;

            -- "GARCHOMP"
            when "011" =>
                case char_idx is
                    when 0 => code := C(16); -- G
                    when 1 => code := C(10); -- A
                    when 2 => code := C(27); -- R
                    when 3 => code := C(12); -- C
                    when 4 => code := C(17); -- H
                    when 5 => code := C(24); -- O
                    when 6 => code := C(22); -- M
                    when 7 => code := C(25); -- P
                    when others => code := C(63);
                end case;

            -- "TORTERRA"  (ID 100)
            when "100" =>
                case char_idx is
                    when 0 => code := C(29); -- T
                    when 1 => code := C(24); -- O
                    when 2 => code := C(27); -- R
                    when 3 => code := C(29); -- T
                    when 4 => code := C(14); -- E
                    when 5 => code := C(27); -- R
                    when 6 => code := C(27); -- R
                    when 7 => code := C(10); -- A
                    when others => code := C(63);
                end case;

            -- "BIDOOF"   (ID 101)
            when "101" =>
                case char_idx is
                    when 0 => code := C(11); -- B
                    when 1 => code := C(18); -- I
                    when 2 => code := C(13); -- D
                    when 3 => code := C(24); -- O
                    when 4 => code := C(24); -- O
                    when 5 => code := C(15); -- F
                    when others => code := C(63);
                end case;

            when others =>
                code := C(63);
        end case;
        return code;
    end function;

    ----------------------------------------------------------------
    -- Text positioning + 2x scaling (names)
    ----------------------------------------------------------------
    constant NAME_CHAR_WIDTH       : integer := 5;
    constant NAME_CHAR_SPACING     : integer := 6;
    constant NAME_MAX_CHARS        : integer := 8;
    constant NAME_SCALE            : integer := 2;

    constant NAME_CHAR_WIDTH_PIX   : integer := NAME_CHAR_WIDTH * NAME_SCALE;
    constant NAME_CHAR_SPACING_PIX : integer := NAME_CHAR_SPACING * NAME_SCALE;
    constant NAME_HEIGHT_PIX       : integer := 7 * NAME_SCALE;

    constant ENEMY_NAME_X_LEFT  : integer := 80;
    constant ENEMY_NAME_Y_TOP   : integer := 150;
    constant PLAYER_NAME_X_LEFT : integer := 540;
    constant PLAYER_NAME_Y_TOP  : integer := 410;

    ----------------------------------------------------------------
    -- HP numeric text (cur/max) below bars, right-aligned
    ----------------------------------------------------------------
    constant HP_TEXT_MAX_CHARS        : integer := 7;   -- "000/000"
    constant HP_TEXT_SCALE            : integer := 2;
    constant HP_TEXT_CHAR_WIDTH       : integer := 5;
    constant HP_TEXT_CHAR_SPACING     : integer := 6;
    constant HP_TEXT_CHAR_WIDTH_PIX   : integer := HP_TEXT_CHAR_WIDTH * HP_TEXT_SCALE;
    constant HP_TEXT_CHAR_SPACING_PIX : integer := HP_TEXT_CHAR_SPACING * HP_TEXT_SCALE;
    constant HP_TEXT_HEIGHT_PIX       : integer := 7 * HP_TEXT_SCALE;
    constant HP_TEXT_WIDTH_PIX        : integer := HP_TEXT_MAX_CHARS * HP_TEXT_CHAR_SPACING_PIX;

    constant ENEMY_HP_TEXT_RIGHT : integer := 279;
    constant ENEMY_HP_TEXT_LEFT  : integer := ENEMY_HP_TEXT_RIGHT - HP_TEXT_WIDTH_PIX + 1;
    constant ENEMY_HP_TEXT_Y_TOP : integer := 185;

    constant PLAYER_HP_TEXT_RIGHT : integer := 739;
    constant PLAYER_HP_TEXT_LEFT  : integer := PLAYER_HP_TEXT_RIGHT - HP_TEXT_WIDTH_PIX + 1;
    constant PLAYER_HP_TEXT_Y_TOP : integer := 445;

begin

    p_hp8   <= std_logic_vector(base_hp8(
                   player_id_at(player_idx, player_p0, player_p1, player_p2)));
    p_atk8  <= std_logic_vector(base_atk8(
                   player_id_at(player_idx, player_p0, player_p1, player_p2)));
    p_def8  <= std_logic_vector(base_def8(
                   player_id_at(player_idx, player_p0, player_p1, player_p2)));
    p_spd8  <= std_logic_vector(base_spd8(
                   player_id_at(player_idx, player_p0, player_p1, player_p2)));

    e_hp8   <= std_logic_vector(base_hp8(
                   enemy_id_at(enemy_idx, enemy_p0, enemy_p1, enemy_p2)));
    e_atk8  <= std_logic_vector(base_atk8(
                   enemy_id_at(enemy_idx, enemy_p0, enemy_p1, enemy_p2)));
    e_def8  <= std_logic_vector(base_def8(
                   enemy_id_at(enemy_idx, enemy_p0, enemy_p1, enemy_p2)));
    e_spd8  <= std_logic_vector(base_spd8(
                   enemy_id_at(enemy_idx, enemy_p0, enemy_p1, enemy_p2)));

    ----------------------------------------------------------------
    -- MAIN BATTLE LOGIC
    ----------------------------------------------------------------
    process(clk)
        variable btnc_edge, btnl_edge, btnr_edge : boolean;
        variable j : integer;
        variable p_roll, e_roll : integer;
        variable atk_val, def_val, rnd_val, dmg_int : integer;
        variable cur_hp_before, cur_hp_after : integer;
        variable battle_over : boolean;
    begin
        if rising_edge(clk) then
            rng_cnt <= rng_cnt + 1;

            btnc_edge := (btnc = '1' and btnc_prev = '0');
            btnl_edge := (btnl = '1' and btnl_prev = '0');
            btnr_edge := (btnr = '1' and btnr_prev = '0');

            battle_over := (player_win_s = '1') or (enemy_win_s = '1');

            if active = '1' and active_prev = '0' then
                -- init HP
                player_hp(0)     <= base_hp8(player_p0);
                player_hp(1)     <= base_hp8(player_p1);
                player_hp(2)     <= base_hp8(player_p2);
                enemy_hp(0)      <= base_hp8(enemy_p0);
                enemy_hp(1)      <= base_hp8(enemy_p1);
                enemy_hp(2)      <= base_hp8(enemy_p2);

                player_hp_bar(0) <= base_hp8(player_p0);
                player_hp_bar(1) <= base_hp8(player_p1);
                player_hp_bar(2) <= base_hp8(player_p2);
                enemy_hp_bar(0)  <= base_hp8(enemy_p0);
                enemy_hp_bar(1)  <= base_hp8(enemy_p1);
                enemy_hp_bar(2)  <= base_hp8(enemy_p2);

                player_idx <= 0;
                enemy_idx  <= 0;

                player_win_s <= '0';
                enemy_win_s  <= '0';
                done_s       <= '0';
                game_over    <= '0';
                game_over_cnt<= (others => '0');

                round_state <= RS_IDLE;
                wait_cnt    <= (others => '0');

                player_anim_active <= '0';
                enemy_anim_active  <= '0';
                player_anim_cnt    <= (others => '0');
                enemy_anim_cnt     <= (others => '0');

                player_attack_active <= '0';
                enemy_attack_active  <= '0';
                player_damage_active <= '0';
                enemy_damage_active  <= '0';
                player_attack_cnt    <= (others => '0');
                enemy_attack_cnt     <= (others => '0');
                player_damage_cnt    <= (others => '0');
                enemy_damage_cnt     <= (others => '0');

                player_faint_active    <= '0';
                enemy_faint_active     <= '0';
                player_faint_cnt       <= (others => '0');
                enemy_faint_cnt        <= (others => '0');
                player_faint_step_cnt  <= (others => '0');
                enemy_faint_step_cnt   <= (others => '0');

            elsif active = '1' then

                --------------------------------------------------------
                -- IDLE: choose pokemon + start round on btnc
                --------------------------------------------------------
                if (round_state = RS_IDLE) and (not battle_over) then
                    -- switch player pokemon
                    if btnl_edge and player_idx > 0 then
                        player_idx <= player_idx - 1;
                    elsif btnr_edge and player_idx < 2 then
                        player_idx <= player_idx + 1;
                    end if;

                    -- attack button
                    if btnc_edge then
                        p_roll := to_integer(unsigned(p_spd8)) / 2
                                  + to_integer(rng_cnt(7 downto 0));
                        e_roll := to_integer(unsigned(e_spd8)) / 2
                                  + to_integer(rng_cnt(15 downto 8));
                        if p_roll >= e_roll then
                            first_is_player <= '1';
                        else
                            first_is_player <= '0';
                        end if;
                        round_state <= RS_FIRST;
                    end if;

                    -- auto switch enemy if fainted (after faint animation done)
                    if enemy_hp(enemy_idx) = ZERO8 then
                        if (enemy_anim_active = '0') and (enemy_faint_active = '0') then
                            for j in 0 to 2 loop
                                if enemy_hp(j) > ZERO8 then
                                    enemy_idx <= j;
                                end if;
                            end loop;
                        end if;
                    end if;

                    -- auto switch player if fainted
                    if player_hp(player_idx) = ZERO8 then
                        if (player_anim_active = '0') and (player_faint_active = '0') then
                            for j in 0 to 2 loop
                                if player_hp(j) > ZERO8 then
                                    player_idx <= j;
                                end if;
                            end loop;
                        end if;
                    end if;

                --------------------------------------------------------
                -- ACTUAL ROUND: FIRST -> WAIT -> SECOND
                --------------------------------------------------------
                elsif not battle_over then
                    case round_state is
                        ------------------------------------------------
                        when RS_FIRST =>
                            if first_is_player = '1' then
                                -- PLAYER attacks first
                                if enemy_hp(enemy_idx) > ZERO8 then
                                    def_val := to_integer(unsigned(e_def8));
                                    if def_val < 1 then def_val := 1; end if;
                                    atk_val := to_integer(unsigned(p_atk8));
                                    rnd_val := to_integer(rng_cnt(7 downto 0)) mod def_val;
                                    dmg_int := atk_val - rnd_val;
                                    if dmg_int < 1 then dmg_int := 1; end if;
                                    cur_hp_before := to_integer(enemy_hp(enemy_idx));
                                    if cur_hp_before > dmg_int then
                                        cur_hp_after := cur_hp_before - dmg_int;
                                    else
                                        cur_hp_after := 0;
                                    end if;
                                    enemy_hp(enemy_idx) <= to_unsigned(cur_hp_after, 8);
                                    if enemy_hp_bar(enemy_idx) < to_unsigned(cur_hp_before,8) then
                                        enemy_hp_bar(enemy_idx) <= to_unsigned(cur_hp_before,8);
                                    end if;
                                    enemy_anim_active <= '1';
                                    enemy_anim_cnt    <= (others => '0');

                                    -- animations: player attacks, enemy damaged
                                    player_attack_active <= '1';
                                    player_attack_cnt    <= (others => '0');
                                    enemy_damage_active  <= '1';
                                    enemy_damage_cnt     <= (others => '0');

                                    -- start faint slide if HP just hit 0
                                    if cur_hp_after = 0 then
                                        enemy_faint_active   <= '1';
                                        enemy_faint_cnt      <= (others => '0');
                                        enemy_faint_step_cnt <= (others => '0');
                                    end if;
                                end if;
                            else
                                -- ENEMY attacks first
                                if player_hp(player_idx) > ZERO8 then
                                    def_val := to_integer(unsigned(p_def8));
                                    if def_val < 1 then def_val := 1; end if;
                                    atk_val := to_integer(unsigned(e_atk8));
                                    rnd_val := to_integer(rng_cnt(7 downto 0)) mod def_val;
                                    dmg_int := atk_val - rnd_val;
                                    if dmg_int < 1 then dmg_int := 1; end if;
                                    cur_hp_before := to_integer(player_hp(player_idx));
                                    if cur_hp_before > dmg_int then
                                        cur_hp_after := cur_hp_before - dmg_int;
                                    else
                                        cur_hp_after := 0;
                                    end if;
                                    player_hp(player_idx) <= to_unsigned(cur_hp_after, 8);
                                    if player_hp_bar(player_idx) < to_unsigned(cur_hp_before,8) then
                                        player_hp_bar(player_idx) <= to_unsigned(cur_hp_before,8);
                                    end if;
                                    player_anim_active <= '1';
                                    player_anim_cnt    <= (others => '0');

                                    -- animations: enemy attacks, player damaged
                                    enemy_attack_active <= '1';
                                    enemy_attack_cnt    <= (others => '0');
                                    player_damage_active<= '1';
                                    player_damage_cnt   <= (others => '0');

                                    if cur_hp_after = 0 then
                                        player_faint_active   <= '1';
                                        player_faint_cnt      <= (others => '0');
                                        player_faint_step_cnt <= (others => '0');
                                    end if;
                                end if;
                            end if;

                            -- check KO
                         if enemy_hp(0)=ZERO8 and enemy_hp(1)=ZERO8 and enemy_hp(2)=ZERO8 then
                            player_win_s <= '1';
                            game_over    <= '1';
                            done_s       <= '1';  -- immediately signal battle done
                        elsif player_hp(0)=ZERO8 and player_hp(1)=ZERO8 and player_hp(2)=ZERO8 then
                            enemy_win_s <= '1';
                            game_over   <= '1';
                            done_s      <= '1';   -- immediately signal battle done
                        end if;

                            if game_over = '0' then
                                wait_cnt    <= (others => '0');
                                round_state <= RS_WAIT;
                            else
                                round_state <= RS_IDLE;
                            end if;

                        ------------------------------------------------
                        when RS_WAIT =>
                            if wait_cnt = WAIT_MAX then
                                wait_cnt    <= (others => '0');
                                round_state <= RS_SECOND;
                            else
                                wait_cnt <= wait_cnt + 1;
                            end if;

                        ------------------------------------------------
                        when RS_SECOND =>
                            if first_is_player = '1' then
                                -- ENEMY attacks second (if still alive)
                                if enemy_hp(enemy_idx) > ZERO8 then
                                    if player_hp(player_idx) > ZERO8 then
                                        def_val := to_integer(unsigned(p_def8));
                                        if def_val < 1 then def_val := 1; end if;
                                        atk_val := to_integer(unsigned(e_atk8));
                                        rnd_val := to_integer(rng_cnt(15 downto 8)) mod def_val;
                                        dmg_int := atk_val - rnd_val;
                                        if dmg_int < 1 then dmg_int := 1; end if;
                                        cur_hp_before := to_integer(player_hp(player_idx));
                                        if cur_hp_before > dmg_int then
                                            cur_hp_after := cur_hp_before - dmg_int;
                                        else
                                            cur_hp_after := 0;
                                        end if;
                                        player_hp(player_idx) <= to_unsigned(cur_hp_after, 8);
                                        if player_hp_bar(player_idx) < to_unsigned(cur_hp_before,8) then
                                            player_hp_bar(player_idx) <= to_unsigned(cur_hp_before,8);
                                        end if;
                                        player_anim_active <= '1';
                                        player_anim_cnt    <= (others => '0');

                                        -- animations: enemy attacks, player damaged
                                        enemy_attack_active <= '1';
                                        enemy_attack_cnt    <= (others => '0');
                                        player_damage_active<= '1';
                                        player_damage_cnt   <= (others => '0');

                                        if cur_hp_after = 0 then
                                            player_faint_active   <= '1';
                                            player_faint_cnt      <= (others => '0');
                                            player_faint_step_cnt <= (others => '0');
                                        end if;
                                    end if;
                                end if;
                            else
                                -- PLAYER attacks second (if still alive)
                                if player_hp(player_idx) > ZERO8 then
                                    if enemy_hp(enemy_idx) > ZERO8 then
                                        def_val := to_integer(unsigned(e_def8));
                                        if def_val < 1 then def_val := 1; end if;
                                        atk_val := to_integer(unsigned(p_atk8));
                                        rnd_val := to_integer(rng_cnt(15 downto 8)) mod def_val;
                                        dmg_int := atk_val - rnd_val;
                                        if dmg_int < 1 then dmg_int := 1; end if;
                                        cur_hp_before := to_integer(enemy_hp(enemy_idx));
                                        if cur_hp_before > dmg_int then
                                            cur_hp_after := cur_hp_before - dmg_int;
                                        else
                                            cur_hp_after := 0;
                                        end if;
                                        enemy_hp(enemy_idx) <= to_unsigned(cur_hp_after, 8);
                                        if enemy_hp_bar(enemy_idx) < to_unsigned(cur_hp_before,8) then
                                            enemy_hp_bar(enemy_idx) <= to_unsigned(cur_hp_before,8);
                                        end if;
                                        enemy_anim_active <= '1';
                                        enemy_anim_cnt    <= (others => '0');

                                        -- animations: player attacks, enemy damaged
                                        player_attack_active <= '1';
                                        player_attack_cnt    <= (others => '0');
                                        enemy_damage_active  <= '1';
                                        enemy_damage_cnt     <= (others => '0');

                                        if cur_hp_after = 0 then
                                            enemy_faint_active   <= '1';
                                            enemy_faint_cnt      <= (others => '0');
                                            enemy_faint_step_cnt <= (others => '0');
                                        end if;
                                    end if;
                                end if;
                            end if;

                            -- KO check
                            if enemy_hp(0)=ZERO8 and enemy_hp(1)=ZERO8 and enemy_hp(2)=ZERO8 then
                                player_win_s <= '1';
                                game_over    <= '1';
                            elsif player_hp(0)=ZERO8 and player_hp(1)=ZERO8 and player_hp(2)=ZERO8 then
                                enemy_win_s <= '1';
                                game_over   <= '1';
                            end if;

                            round_state <= RS_IDLE;

                        when others =>
                            round_state <= RS_IDLE;
                    end case;
                end if;

                --------------------------------------------------------
                -- HP BAR ANIMATION (slow)
                --------------------------------------------------------
                if player_anim_active = '1' then
                    if player_hp_bar(player_idx) > player_hp(player_idx) then
                        if player_anim_cnt = HP_ANIM_TICK then
                            player_anim_cnt <= (others => '0');
                            player_hp_bar(player_idx) <= player_hp_bar(player_idx) - 1;
                        else
                            player_anim_cnt <= player_anim_cnt + 1;
                        end if;
                    else
                        player_anim_active <= '0';
                        player_anim_cnt    <= (others => '0');
                    end if;
                end if;

                if enemy_anim_active = '1' then
                    if enemy_hp_bar(enemy_idx) > enemy_hp(enemy_idx) then
                        if enemy_anim_cnt = HP_ANIM_TICK then
                            enemy_anim_cnt <= (others => '0');
                            enemy_hp_bar(enemy_idx) <= enemy_hp_bar(enemy_idx) - 1;
                        else
                            enemy_anim_cnt <= enemy_anim_cnt + 1;
                        end if;
                    else
                        enemy_anim_active <= '0';
                        enemy_anim_cnt    <= (others => '0');
                    end if;
                end if;

                --------------------------------------------------------
                -- ATTACK SHAKE TIMERS (0.25 s each event)
                --------------------------------------------------------
                if player_attack_active = '1' then
                    if player_attack_cnt = ATK_TOTAL then
                        player_attack_active <= '0';
                        player_attack_cnt    <= (others => '0');
                    else
                        player_attack_cnt <= player_attack_cnt + 1;
                    end if;
                end if;

                if enemy_attack_active = '1' then
                    if enemy_attack_cnt = ATK_TOTAL then
                        enemy_attack_active <= '0';
                        enemy_attack_cnt    <= (others => '0');
                    else
                        enemy_attack_cnt <= enemy_attack_cnt + 1;
                    end if;
                end if;

                --------------------------------------------------------
                -- DAMAGE BLINK TIMERS (0.25 s each event)
                --------------------------------------------------------
                if player_damage_active = '1' then
                    if player_damage_cnt = DMG_TOTAL then
                        player_damage_active <= '0';
                        player_damage_cnt    <= (others => '0');
                    else
                        player_damage_cnt <= player_damage_cnt + 1;
                    end if;
                end if;

                if enemy_damage_active = '1' then
                    if enemy_damage_cnt = DMG_TOTAL then
                        enemy_damage_active <= '0';
                        enemy_damage_cnt    <= (others => '0');
                    else
                        enemy_damage_cnt <= enemy_damage_cnt + 1;
                    end if;
                end if;

                --------------------------------------------------------
                -- FAINT SLIDE TIMERS (~0.5 s total)
                --------------------------------------------------------
                if player_faint_active = '1' then
                    if player_faint_cnt = FAINT_MAX then
                        player_faint_active <= '0';
                    else
                        if player_faint_step_cnt = FAINT_STEP_TICKS then
                            player_faint_step_cnt <= (others => '0');
                            player_faint_cnt      <= player_faint_cnt + 1;
                        else
                            player_faint_step_cnt <= player_faint_step_cnt + 1;
                        end if;
                    end if;
                else
                    player_faint_step_cnt <= (others => '0');
                end if;

                if enemy_faint_active = '1' then
                    if enemy_faint_cnt = FAINT_MAX then
                        enemy_faint_active <= '0';
                    else
                        if enemy_faint_step_cnt = FAINT_STEP_TICKS then
                            enemy_faint_step_cnt <= (others => '0');
                            enemy_faint_cnt      <= enemy_faint_cnt + 1;
                        else
                            enemy_faint_step_cnt <= enemy_faint_step_cnt + 1;
                        end if;
                    end if;
                else
                    enemy_faint_step_cnt <= (others => '0');
                end if;

                --------------------------------------------------------
                -- GAME OVER DELAY
                --------------------------------------------------------
                if game_over = '1' then
                    if game_over_cnt = WAIT_MAX then
                        done_s        <= '1';
                        game_over_cnt <= WAIT_MAX;
                    else
                        game_over_cnt <= game_over_cnt + 1;
                    end if;
                end if;

            end if;

            active_prev <= active;
            btnc_prev   <= btnc;
            btnl_prev   <= btnl;
            btnr_prev   <= btnr;
        end if;
    end process;

    hp_summary <= std_logic_vector(player_hp(player_idx)) &
                  std_logic_vector(enemy_hp(enemy_idx));

    player_win <= player_win_s;
    enemy_win  <= enemy_win_s;
    done       <= done_s;

    ----------------------------------------------------------------
    -- RENDERER (sprites, bars, names, numeric HP)
    ----------------------------------------------------------------
    process(pixel_row, pixel_col,
            player_hp_bar, enemy_hp_bar,
            player_idx, enemy_idx,
            player_p0, player_p1, player_p2,
            enemy_p0, enemy_p1, enemy_p2,
            player_win_s, enemy_win_s,
            p_hp8, e_hp8, active,
            player_attack_active, enemy_attack_active,
            player_attack_cnt, enemy_attack_cnt,
            player_damage_active, enemy_damage_active,
            player_damage_cnt, enemy_damage_cnt,
            player_faint_active, enemy_faint_active,
            player_faint_cnt, enemy_faint_cnt,
            player_hp, enemy_hp)
        variable x,y : integer;
        variable php, ehp : integer;
        variable pbase, ebase : integer;
        variable p_fill, e_fill : integer;
        variable curP, curE : std_logic_vector(2 downto 0);

        variable sx, sy : integer;
        variable srcx, srcy : integer;
        variable color_idx : std_logic_vector(3 downto 0);
        variable pr,pg,pb : std_logic_vector(3 downto 0);

        variable char_idx        : integer;
        variable col_in_char_big : integer;
        variable gx, gy          : integer;
        variable cc              : std_logic_vector(5 downto 0);

        variable p_cur, p_max, e_cur, e_max : integer;
        variable p_c_d0, p_c_d1, p_c_d2     : integer;
        variable p_m_d0, p_m_d1, p_m_d2     : integer;
        variable e_c_d0, e_c_d1, e_c_d2     : integer;
        variable e_m_d0, e_m_d1, e_m_d2     : integer;
        variable p_c_len, p_m_len           : integer;
        variable e_c_len, e_m_len           : integer;
        variable p_total_len, e_total_len   : integer;
        variable offset, pos_in             : integer;
        variable hp_char                    : integer;
        variable slash_on                   : boolean;

        variable player_x_offset, enemy_x_offset : integer;
        variable player_y_offset, enemy_y_offset : integer;
    begin
        x := to_integer(unsigned(pixel_col));
        y := to_integer(unsigned(pixel_row));

        red   <= (others => '0');
        green <= (others => '0');
        blue  <= (others => '0');

        if active = '1' then
            curP := player_id_at(player_idx, player_p0, player_p1, player_p2);
            curE := enemy_id_at(enemy_idx, enemy_p0, enemy_p1, enemy_p2);

            php := to_integer(player_hp_bar(player_idx));
            ehp := to_integer(enemy_hp_bar(enemy_idx));

            pbase := to_integer(unsigned(p_hp8));
            ebase := to_integer(unsigned(e_hp8));

            if pbase > 0 then p_fill := (200 * php) / pbase; else p_fill := 0; end if;
            if ebase > 0 then e_fill := (200 * ehp) / ebase; else e_fill := 0; end if;

            -- background
            if y < 300 then
                red <= "0011"; green <= "0101"; blue <= "1111";
            else
                red <= "0001"; green <= "1011"; blue <= "0001";
            end if;

            ------------------------------------------------------------
            -- Offsets for shake + faint slide
            ------------------------------------------------------------
            player_x_offset := 0;
            enemy_x_offset  := 0;
            player_y_offset := 0;
            enemy_y_offset  := 0;

            -- SHAKE / LUNGE: attacker only (0.25 s total, diagonal toward opponent)
            -- First half (0.125s): move toward opponent
            -- Second half (0.125s): return to original position
            if player_attack_active = '1' then
                if player_attack_cnt < ATK_HALF then
                    -- player is on left, enemy on right and a bit up:
                    -- move up-right: +50 X, -25 Y
                    player_x_offset := 50;
                    player_y_offset := -25;
                else
                    -- return to original
                    player_x_offset := 0;
                    player_y_offset := 0;
                end if;
            end if;

            if enemy_attack_active = '1' then
                if enemy_attack_cnt < ATK_HALF then
                    -- enemy on right, player on left and lower:
                    -- move down-left: -50 X, +25 Y
                    enemy_x_offset := -50;
                    enemy_y_offset := 25;
                else
                    -- return to original
                    enemy_x_offset := 0;
                    enemy_y_offset := 0;
                end if;
            end if;

            -- FAINT SLIDE: slide down while faint_active=1, then hide
            -- but DO NOT disappear until HP BAR hits 0.
            if enemy_faint_active = '1' then
                enemy_y_offset := enemy_y_offset + to_integer(enemy_faint_cnt);
            elsif enemy_hp_bar(enemy_idx) = ZERO8 and enemy_hp(enemy_idx) = ZERO8 then
                enemy_y_offset := 1000; -- completely off-screen only when bar is 0
            end if;

            if player_faint_active = '1' then
                player_y_offset := player_y_offset + to_integer(player_faint_cnt);
            elsif player_hp_bar(player_idx) = ZERO8 and player_hp(player_idx) = ZERO8 then
                player_y_offset := 1000;
            end if;

            ----------------------------------------------------------------
            -- ENEMY SPRITE (3x scale)
            ----------------------------------------------------------------
            sx := x - (ENEMY_X0 + enemy_x_offset);
            sy := y - (ENEMY_Y0 + enemy_y_offset);

            if (sx >= 0) and (sy >= 0) then
                if curE = "000" then  -- Pikachu
                    if (sx < PIKA_W * ENEMY_SCALE) and
                       (sy < PIKA_H * ENEMY_SCALE) then
                        srcx := sx / ENEMY_SCALE;
                        srcy := sy / ENEMY_SCALE;
                        color_idx := PIKACHU_SPRITE(srcy)(srcx);
                        if color_idx /= "0000" then
                            pikachu_color(color_idx, pr, pg, pb);

                            -- BLINK on damage: exactly 2 white flashes in 0.25 s
                            if enemy_damage_active = '1' then
                                if (enemy_damage_cnt < DMG_QUARTER) or
                                   (enemy_damage_cnt >= DMG_Q2 and enemy_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curE = "001" then  -- Giratina
                    if (sx < GIRATINA_FRONT(0)'length * ENEMY_SCALE) and
                       (sy < GIRATINA_FRONT'length     * ENEMY_SCALE) then
                        srcx := sx / ENEMY_SCALE;
                        srcy := sy / ENEMY_SCALE;
                        color_idx := GIRATINA_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            giratina_color(color_idx, pr, pg, pb);

                            if enemy_damage_active = '1' then
                                if (enemy_damage_cnt < DMG_QUARTER) or
                                   (enemy_damage_cnt >= DMG_Q2 and enemy_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curE = "010" then  -- Empoleon
                    if (sx < EMPOLEON_FRONT(0)'length * ENEMY_SCALE) and
                       (sy < EMPOLEON_FRONT'length     * ENEMY_SCALE) then
                        srcx := sx / ENEMY_SCALE;
                        srcy := sy / ENEMY_SCALE;
                        color_idx := EMPOLEON_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            empoleon_color(color_idx, pr, pg, pb);

                            if enemy_damage_active = '1' then
                                if (enemy_damage_cnt < DMG_QUARTER) or
                                   (enemy_damage_cnt >= DMG_Q2 and enemy_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curE = "011" then  -- Garchomp
                    if (sx < GARCHOMP_FRONT(0)'length * ENEMY_SCALE) and
                       (sy < GARCHOMP_FRONT'length     * ENEMY_SCALE) then
                        srcx := sx / ENEMY_SCALE;
                        srcy := sy / ENEMY_SCALE;
                        color_idx := GARCHOMP_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            garchomp_color(color_idx, pr, pg, pb);

                            if enemy_damage_active = '1' then
                                if (enemy_damage_cnt < DMG_QUARTER) or
                                   (enemy_damage_cnt >= DMG_Q2 and enemy_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curE = "100" then  -- Torterra
                    if (sx < TORTERRA_FRONT(0)'length * ENEMY_SCALE) and
                       (sy < TORTERRA_FRONT'length     * ENEMY_SCALE) then
                        srcx := sx / ENEMY_SCALE;
                        srcy := sy / ENEMY_SCALE;
                        color_idx := TORTERRA_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            torterra_color(color_idx, pr, pg, pb);

                            if enemy_damage_active = '1' then
                                if (enemy_damage_cnt < DMG_QUARTER) or
                                   (enemy_damage_cnt >= DMG_Q2 and enemy_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curE = "101" then  -- Bidoof
                    if (sx < BIDOOF_FRONT(0)'length * ENEMY_SCALE) and
                       (sy < BIDOOF_FRONT'length     * ENEMY_SCALE) then
                        srcx := sx / ENEMY_SCALE;
                        srcy := sy / ENEMY_SCALE;
                        color_idx := BIDOOF_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            bidoof_color(color_idx, pr, pg, pb);

                            if enemy_damage_active = '1' then
                                if (enemy_damage_cnt < DMG_QUARTER) or
                                   (enemy_damage_cnt >= DMG_Q2 and enemy_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- PLAYER SPRITE (4x scale, HORIZONTALLY FLIPPED)
            ----------------------------------------------------------------
            sx := x - (PLAYER_X0 + player_x_offset);
            sy := y - (PLAYER_Y0 + player_y_offset);

            if (sx >= 0) and (sy >= 0) then
                if curP = "000" then  -- Pikachu
                    if (sx < PIKA_W * PLAYER_SCALE) and
                       (sy < PIKA_H * PLAYER_SCALE) then
                        srcx := PIKA_W - 1 - (sx / PLAYER_SCALE);  -- flip horizontally
                        srcy := sy / PLAYER_SCALE;
                        color_idx := PIKACHU_SPRITE(srcy)(srcx);
                        if color_idx /= "0000" then
                            pikachu_color(color_idx, pr, pg, pb);

                            -- blink on damage for player
                            if player_damage_active = '1' then
                                if (player_damage_cnt < DMG_QUARTER) or
                                   (player_damage_cnt >= DMG_Q2 and player_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curP = "001" then  -- Giratina
                    if (sx < GIRATINA_FRONT(0)'length * PLAYER_SCALE) and
                       (sy < GIRATINA_FRONT'length     * PLAYER_SCALE) then
                        srcx := GIRATINA_FRONT(0)'length - 1 - (sx / PLAYER_SCALE);
                        srcy := sy / PLAYER_SCALE;
                        color_idx := GIRATINA_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            giratina_color(color_idx, pr, pg, pb);

                            if player_damage_active = '1' then
                                if (player_damage_cnt < DMG_QUARTER) or
                                   (player_damage_cnt >= DMG_Q2 and player_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curP = "010" then  -- Empoleon
                    if (sx < EMPOLEON_FRONT(0)'length * PLAYER_SCALE) and
                       (sy < EMPOLEON_FRONT'length     * PLAYER_SCALE) then
                        srcx := EMPOLEON_FRONT(0)'length - 1 - (sx / PLAYER_SCALE);
                        srcy := sy / PLAYER_SCALE;
                        color_idx := EMPOLEON_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            empoleon_color(color_idx, pr, pg, pb);

                            if player_damage_active = '1' then
                                if (player_damage_cnt < DMG_QUARTER) or
                                   (player_damage_cnt >= DMG_Q2 and player_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curP = "011" then  -- Garchomp
                    if (sx < GARCHOMP_FRONT(0)'length * PLAYER_SCALE) and
                       (sy < GARCHOMP_FRONT'length     * PLAYER_SCALE) then
                        srcx := GARCHOMP_FRONT(0)'length - 1 - (sx / PLAYER_SCALE);
                        srcy := sy / PLAYER_SCALE;
                        color_idx := GARCHOMP_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            garchomp_color(color_idx, pr, pg, pb);

                            if player_damage_active = '1' then
                                if (player_damage_cnt < DMG_QUARTER) or
                                   (player_damage_cnt >= DMG_Q2 and player_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curP = "100" then  -- Torterra
                    if (sx < TORTERRA_FRONT(0)'length * PLAYER_SCALE) and
                       (sy < TORTERRA_FRONT'length     * PLAYER_SCALE) then
                        srcx := TORTERRA_FRONT(0)'length - 1 - (sx / PLAYER_SCALE);
                        srcy := sy / PLAYER_SCALE;
                        color_idx := TORTERRA_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            torterra_color(color_idx, pr, pg, pb);

                            if player_damage_active = '1' then
                                if (player_damage_cnt < DMG_QUARTER) or
                                   (player_damage_cnt >= DMG_Q2 and player_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;

                elsif curP = "101" then  -- Bidoof
                    if (sx < BIDOOF_FRONT(0)'length * PLAYER_SCALE) and
                       (sy < BIDOOF_FRONT'length     * PLAYER_SCALE) then
                        srcx := BIDOOF_FRONT(0)'length - 1 - (sx / PLAYER_SCALE);
                        srcy := sy / PLAYER_SCALE;
                        color_idx := BIDOOF_FRONT(srcy)(srcx);
                        if color_idx /= "0000" then
                            bidoof_color(color_idx, pr, pg, pb);

                            if player_damage_active = '1' then
                                if (player_damage_cnt < DMG_QUARTER) or
                                   (player_damage_cnt >= DMG_Q2 and player_damage_cnt < DMG_Q3) then
                                    pr := "1111"; pg := "1111"; pb := "1111";
                                end if;
                            end if;

                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- enemy HP bar (80..280)
            ----------------------------------------------------------------
            if y>=170 and y<180 and x>=80 and x<280 then
                if x=80 or x=279 or y=170 or y=179 then
                    red <= "1111"; green <= "1111"; blue <= "1111";
                else
                    if x < 80 + e_fill then
                        red <= "1111"; green <= "0000"; blue <= "0000";
                    else
                        red <= "0010"; green <= "0000"; blue <= "0000";
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- player HP bar (540..740)
            ----------------------------------------------------------------
            if y>=430 and y<440 and x>=540 and x<740 then
                if x=540 or x=739 or y=430 or y=439 then
                    red <= "1111"; green <= "1111"; blue <= "1111";
                else
                    if x < 540 + p_fill then
                        red <= "0010"; green <= "1111"; blue <= "0010";
                    else
                        red <= "0000"; green <= "0100"; blue <= "0000";
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- ENEMY NAME ABOVE ENEMY HP BAR
            ----------------------------------------------------------------
            if (y >= ENEMY_NAME_Y_TOP) and (y < ENEMY_NAME_Y_TOP + NAME_HEIGHT_PIX) then
                if (x >= ENEMY_NAME_X_LEFT) and
                   (x < ENEMY_NAME_X_LEFT + NAME_MAX_CHARS * NAME_CHAR_SPACING_PIX) then

                    char_idx        := (x - ENEMY_NAME_X_LEFT) / NAME_CHAR_SPACING_PIX;
                    col_in_char_big := (x - ENEMY_NAME_X_LEFT) mod NAME_CHAR_SPACING_PIX;

                    if (char_idx >= 0) and (char_idx < NAME_MAX_CHARS) and
                       (col_in_char_big >= 0) and (col_in_char_big < NAME_CHAR_WIDTH_PIX) then

                        gx := col_in_char_big / NAME_SCALE;
                        gy := (y - ENEMY_NAME_Y_TOP) / NAME_SCALE;

                        cc := pokemon_char_code(curE, char_idx);

                        if font_pixel(cc, gx, gy) = '1' then
                            red   <= "1111";
                            green <= "1111";
                            blue  <= "1111";
                        end if;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- PLAYER NAME ABOVE PLAYER HP BAR
            ----------------------------------------------------------------
            if (y >= PLAYER_NAME_Y_TOP) and (y < PLAYER_NAME_Y_TOP + NAME_HEIGHT_PIX) then
                if (x >= PLAYER_NAME_X_LEFT) and
                   (x < PLAYER_NAME_X_LEFT + NAME_MAX_CHARS * NAME_CHAR_SPACING_PIX) then

                    char_idx        := (x - PLAYER_NAME_X_LEFT) / NAME_CHAR_SPACING_PIX;
                    col_in_char_big := (x - PLAYER_NAME_X_LEFT) mod NAME_CHAR_SPACING_PIX;

                    if (char_idx >= 0) and (char_idx < NAME_MAX_CHARS) and
                       (col_in_char_big >= 0) and (col_in_char_big < NAME_CHAR_WIDTH_PIX) then

                        gx := col_in_char_big / NAME_SCALE;
                        gy := (y - PLAYER_NAME_Y_TOP) / NAME_SCALE;

                        cc := pokemon_char_code(curP, char_idx);

                        if font_pixel(cc, gx, gy) = '1' then
                            red   <= "1111";
                            green <= "1111";
                            blue  <= "1111";
                        end if;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- NUMERIC HP: cur/max BELOW BARS, RIGHT-ALIGNED
            ----------------------------------------------------------------
            p_cur := to_integer(player_hp_bar(player_idx));
            e_cur := to_integer(enemy_hp_bar(enemy_idx));
            p_max := to_integer(unsigned(p_hp8));
            e_max := to_integer(unsigned(e_hp8));

            p_c_d0 := p_cur mod 10;
            p_c_d1 := (p_cur / 10) mod 10;
            p_c_d2 := (p_cur / 100) mod 10;
            if p_cur >= 100 then
                p_c_len := 3;
            elsif p_cur >= 10 then
                p_c_len := 2;
            else
                p_c_len := 1;
            end if;

            p_m_d0 := p_max mod 10;
            p_m_d1 := (p_max / 10) mod 10;
            p_m_d2 := (p_max / 100) mod 10;
            if p_max >= 100 then
                p_m_len := 3;
            elsif p_max >= 10 then
                p_m_len := 2;
            else
                p_m_len := 1;
            end if;

            e_c_d0 := e_cur mod 10;
            e_c_d1 := (e_cur / 10) mod 10;
            e_c_d2 := (e_cur / 100) mod 10;
            if e_cur >= 100 then
                e_c_len := 3;
            elsif e_cur >= 10 then
                e_c_len := 2;
            else
                e_c_len := 1;
            end if;

            e_m_d0 := e_max mod 10;
            e_m_d1 := (e_max / 10) mod 10;
            e_m_d2 := (e_max / 100) mod 10;
            if e_max >= 100 then
                e_m_len := 3;
            elsif e_max >= 10 then
                e_m_len := 2;
            else
                e_m_len := 1;
            end if;

            p_total_len := p_c_len + 1 + p_m_len;
            e_total_len := e_c_len + 1 + e_m_len;

            ----------------------------------------------------------------
            -- ENEMY HP TEXT
            ----------------------------------------------------------------
            if (y >= ENEMY_HP_TEXT_Y_TOP) and
               (y < ENEMY_HP_TEXT_Y_TOP + HP_TEXT_HEIGHT_PIX) then
                if (x >= ENEMY_HP_TEXT_LEFT) and
                   (x < ENEMY_HP_TEXT_LEFT + HP_TEXT_WIDTH_PIX) then

                    char_idx        := (x - ENEMY_HP_TEXT_LEFT) / HP_TEXT_CHAR_SPACING_PIX;
                    col_in_char_big := (x - ENEMY_HP_TEXT_LEFT) mod HP_TEXT_CHAR_SPACING_PIX;

                    if (char_idx >= 0) and (char_idx < HP_TEXT_MAX_CHARS) and
                       (col_in_char_big >= 0) and
                       (col_in_char_big < HP_TEXT_CHAR_WIDTH_PIX) then

                        gx := col_in_char_big / HP_TEXT_SCALE;
                        gy := (y - ENEMY_HP_TEXT_Y_TOP) / HP_TEXT_SCALE;

                        offset := char_idx - (HP_TEXT_MAX_CHARS - e_total_len);
                        if offset < 0 then
                            hp_char := -1;
                        else
                            if offset < e_c_len then
                                pos_in := offset;
                                if e_c_len = 1 then
                                    hp_char := e_c_d0;
                                elsif e_c_len = 2 then
                                    if pos_in = 0 then
                                        hp_char := e_c_d1;
                                    else
                                        hp_char := e_c_d0;
                                    end if;
                                else
                                    if pos_in = 0 then
                                        hp_char := e_c_d2;
                                    elsif pos_in = 1 then
                                        hp_char := e_c_d1;
                                    else
                                        hp_char := e_c_d0;
                                    end if;
                                end if;
                            elsif offset = e_c_len then
                                hp_char := 100; -- slash
                            else
                                pos_in := offset - e_c_len - 1;
                                if e_m_len = 1 then
                                    hp_char := e_m_d0;
                                elsif e_m_len = 2 then
                                    if pos_in = 0 then
                                        hp_char := e_m_d1;
                                    else
                                        hp_char := e_m_d0;
                                    end if;
                                else
                                    if pos_in = 0 then
                                        hp_char := e_m_d2;
                                    elsif pos_in = 1 then
                                        hp_char := e_m_d1;
                                    else
                                        hp_char := e_m_d0;
                                    end if;
                                end if;
                            end if;
                        end if;

                        if (hp_char >= 0) and (hp_char <= 9) then
                            cc := std_logic_vector(to_unsigned(hp_char, 6));
                            if font_pixel(cc, gx, gy) = '1' then
                                red   <= "1111";
                                green <= "1111";
                                blue  <= "1111";
                            end if;
                        elsif hp_char = 100 then
                            slash_on := false;
                            if (gx = 4 and gy = 0) or
                               (gx = 3 and gy = 1) or
                               (gx = 2 and gy = 2) or
                               (gx = 1 and gy = 3) or
                               (gx = 0 and gy = 4) then
                                slash_on := true;
                            end if;
                            if slash_on then
                                red   <= "1111";
                                green <= "1111";
                                blue  <= "1111";
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- PLAYER HP TEXT
            ----------------------------------------------------------------
            if (y >= PLAYER_HP_TEXT_Y_TOP) and
               (y < PLAYER_HP_TEXT_Y_TOP + HP_TEXT_HEIGHT_PIX) then
                if (x >= PLAYER_HP_TEXT_LEFT) and
                   (x < PLAYER_HP_TEXT_LEFT + HP_TEXT_WIDTH_PIX) then

                    char_idx        := (x - PLAYER_HP_TEXT_LEFT) / HP_TEXT_CHAR_SPACING_PIX;
                    col_in_char_big := (x - PLAYER_HP_TEXT_LEFT) mod HP_TEXT_CHAR_SPACING_PIX;

                    if (char_idx >= 0) and (char_idx < HP_TEXT_MAX_CHARS) and
                       (col_in_char_big >= 0) and
                       (col_in_char_big < HP_TEXT_CHAR_WIDTH_PIX) then

                        gx := col_in_char_big / HP_TEXT_SCALE;
                        gy := (y - PLAYER_HP_TEXT_Y_TOP) / HP_TEXT_SCALE;

                        offset := char_idx - (HP_TEXT_MAX_CHARS - p_total_len);
                        if offset < 0 then
                            hp_char := -1;
                        else
                            if offset < p_c_len then
                                pos_in := offset;
                                if p_c_len = 1 then
                                    hp_char := p_c_d0;
                                elsif p_c_len = 2 then
                                    if pos_in = 0 then
                                        hp_char := p_c_d1;
                                    else
                                        hp_char := p_c_d0;
                                    end if;
                                else
                                    if pos_in = 0 then
                                        hp_char := p_c_d2;
                                    elsif pos_in = 1 then
                                        hp_char := p_c_d1;
                                    else
                                        hp_char := p_c_d0;
                                    end if;
                                end if;
                            elsif offset = p_c_len then
                                hp_char := 100;
                            else
                                pos_in := offset - p_c_len - 1;
                                if p_m_len = 1 then
                                    hp_char := p_m_d0;
                                elsif p_m_len = 2 then
                                    if pos_in = 0 then
                                        hp_char := p_m_d1;
                                    else
                                        hp_char := p_m_d0;
                                    end if;
                                else
                                    if pos_in = 0 then
                                        hp_char := p_m_d2;
                                    elsif pos_in = 1 then
                                        hp_char := p_m_d1;
                                    else
                                        hp_char := p_m_d0;
                                    end if;
                                end if;
                            end if;
                        end if;

                        if (hp_char >= 0) and (hp_char <= 9) then
                            cc := std_logic_vector(to_unsigned(hp_char, 6));
                            if font_pixel(cc, gx, gy) = '1' then
                                red   <= "1111";
                                green <= "1111";
                                blue  <= "1111";
                            end if;
                        elsif hp_char = 100 then
                            slash_on := false;
                            if (gx = 4 and gy = 0) or
                               (gx = 3 and gy = 1) or
                               (gx = 2 and gy = 2) or
                               (gx = 1 and gy = 3) or
                               (gx = 0 and gy = 4) then
                                slash_on := true;
                            end if;
                            if slash_on then
                                red   <= "1111";
                                green <= "1111";
                                blue  <= "1111";
                            end if;
                        end if;
                    end if;
                end if;
            end if;

        end if;
    end process;

end architecture Behavioral;
