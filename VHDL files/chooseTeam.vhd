library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pikachu_pkg.all;     -- Pikachu sprite package
use work.giratina_pkg.all;    -- Giratina sprite package
use work.garchomp_pkg.all;    -- Garchomp sprite package
use work.empoleon_pkg.all;    -- Empoleon sprite package
use work.bidoof_pkg.all;      -- Bidoof sprite package
use work.torterra_pkg.all;    -- Torterra sprite package

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

architecture Behavioral of chooseTeam is

    -- Pokemon IDs
    subtype poke_id_t is std_logic_vector(2 downto 0);

    constant P0 : poke_id_t := "000"; -- Pikachu
    constant P1 : poke_id_t := "001"; -- Giratina
    constant P2 : poke_id_t := "010"; -- Empoleon
    constant P3 : poke_id_t := "011"; -- Garchomp
    constant P4 : poke_id_t := "100"; -- Torterra
    constant P5 : poke_id_t := "101"; -- Bidoof

    -- Boxes
    constant BOX_W : integer := 128;
    constant BOX_H : integer := 128;
    constant BOX_Y : integer := 150;  -- top of first row
    constant BOX_X0: integer := 45;   -- shifted 5 pixels right
    constant GAP_X : integer := 10;
    constant GAP_Y : integer := 10;
    constant ROW1_TOP : integer := BOX_Y + (BOX_H + GAP_Y) + 25; -- second row

    --Sprites
    -- Pikachu
    constant PIKA_OFF_X : integer := (128 - PIKA_W) / 2; 
    constant PIKA_OFF_Y : integer := (128 - PIKA_H) / 2; 

    -- Giratina
    constant GIR_W     : integer := GIRATINA_FRONT(0)'length;
    constant GIR_H     : integer := GIRATINA_FRONT'length;
    constant GIR_OFF_X : integer := (128 - GIR_W) / 2;
    constant GIR_OFF_Y : integer := (128 - GIR_H) / 2;

    -- Garchomp
    constant GARCH_W     : integer := 80;
    constant GARCH_H     : integer := 80;
    constant GARCH_OFF_X : integer := (128 - GARCH_W) / 2;  
    constant GARCH_OFF_Y : integer := (128 - GARCH_H) / 2;  

    -- Empoleon
    constant EMP_OFF_X : integer := (128 - EMP_W) / 2;
    constant EMP_OFF_Y : integer := (128 - EMP_H) / 2;

    -- Bidoof
    constant BID_OFF_X : integer := (128 - BIDOOF_W) / 2;
    constant BID_OFF_Y : integer := (128 - BIDOOF_H) / 2;

    -- Torterra
    constant TORT_OFF_X : integer := (128 - TORTERRA_W) / 2;
    constant TORT_OFF_Y : integer := (128 - TORTERRA_H) / 2;

    -- 5x7 FONT
    type char7x5_t is array(0 to 6) of std_logic_vector(4 downto 0);

    -- Letters we need: A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,T,U
    constant CHAR_A : char7x5_t := (
        "01110",
        "10001",
        "10001",
        "11111",
        "10001",
        "10001",
        "10001"
    );

    constant CHAR_B : char7x5_t := (
        "11110",
        "10001",
        "10001",
        "11110",
        "10001",
        "10001",
        "11110"
    );

    constant CHAR_C : char7x5_t := (
        "01110",
        "10001",
        "10000",
        "10000",
        "10000",
        "10001",
        "01110"
    );

    constant CHAR_D : char7x5_t := (
        "11100",
        "10010",
        "10001",
        "10001",
        "10001",
        "10010",
        "11100"
    );

    constant CHAR_E : char7x5_t := (
        "11111",
        "10000",
        "10000",
        "11110",
        "10000",
        "10000",
        "11111"
    );

    constant CHAR_F : char7x5_t := (
        "11111",
        "10000",
        "10000",
        "11110",
        "10000",
        "10000",
        "10000"
    );

    constant CHAR_G : char7x5_t := (
        "01110",
        "10001",
        "10000",
        "10111",
        "10001",
        "10001",
        "01110"
    );

    constant CHAR_H : char7x5_t := (
        "10001",
        "10001",
        "10001",
        "11111",
        "10001",
        "10001",
        "10001"
    );

    constant CHAR_I : char7x5_t := (
        "00100",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100"
    );

    constant CHAR_K : char7x5_t := (
        "10001",
        "10010",
        "10100",
        "11000",
        "10100",
        "10010",
        "10001"
    );

    constant CHAR_L : char7x5_t := (
        "10000",
        "10000",
        "10000",
        "10000",
        "10000",
        "10000",
        "11111"
    );

    constant CHAR_M : char7x5_t := (
        "10001",
        "11011",
        "10101",
        "10101",
        "10001",
        "10001",
        "10001"
    );

    constant CHAR_N : char7x5_t := (
        "10001",
        "11001",
        "10101",
        "10011",
        "10001",
        "10001",
        "10001"
    );

    constant CHAR_O : char7x5_t := (
        "01110",
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01110"
    );

    constant CHAR_P : char7x5_t := (
        "11110",
        "10001",
        "10001",
        "11110",
        "10000",
        "10000",
        "10000"
    );

    constant CHAR_R : char7x5_t := (
        "11110",
        "10001",
        "10001",
        "11110",
        "10100",
        "10010",
        "10001"
    );

    constant CHAR_T : char7x5_t := (
        "11111",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100"
    );

    constant CHAR_U : char7x5_t := (
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01110"
    );

    -- font parameters
    constant NAME_CHAR_W   : integer := 5;
    constant NAME_CHAR_SP  : integer := 1;
    constant NAME_FONT_H   : integer := 7;
    constant SCALE_NAME    : integer := 2;  -- 2x bigger
    constant NAME_ADVANCE  : integer :=
        (NAME_CHAR_W + NAME_CHAR_SP) * SCALE_NAME;
    constant NAME_H_PIX    : integer := NAME_FONT_H * SCALE_NAME;

    -- Name strings
    constant NAME_PIKA : string := "PIKACHU";
    constant NAME_GIRA : string := "GIRATINA";
    constant NAME_EMPO : string := "EMPOLEON";
    constant NAME_GARC : string := "GARCHOMP";
    constant NAME_TORT : string := "TORTERRA";
    constant NAME_BIDO : string := "BIDOOF";

    -- Name pixel widths
    constant NAME_PIKA_W : integer := NAME_PIKA'length * NAME_ADVANCE;
    constant NAME_GIRA_W : integer := NAME_GIRA'length * NAME_ADVANCE;
    constant NAME_EMPO_W : integer := NAME_EMPO'length * NAME_ADVANCE;
    constant NAME_GARC_W : integer := NAME_GARC'length * NAME_ADVANCE;
    constant NAME_TORT_W : integer := NAME_TORT'length * NAME_ADVANCE;
    constant NAME_BIDO_W : integer := NAME_BIDO'length * NAME_ADVANCE;

    -- Name positions (centered under each box)
    constant NAME_PIKA_X0 : integer :=
        BOX_X0 + (BOX_W - NAME_PIKA_W)/2;
    constant NAME_PIKA_Y0 : integer := BOX_Y + BOX_H + 10;

    constant NAME_GIRA_X0 : integer :=
        BOX_X0 + (BOX_W + GAP_X) + (BOX_W - NAME_GIRA_W)/2;
    constant NAME_GIRA_Y0 : integer := BOX_Y + BOX_H + 10;

    constant NAME_EMPO_X0 : integer :=
        BOX_X0 + 2*(BOX_W + GAP_X) + (BOX_W - NAME_EMPO_W)/2;
    constant NAME_EMPO_Y0 : integer := BOX_Y + BOX_H + 10;

    constant NAME_GARC_X0 : integer :=
        BOX_X0 + 3*(BOX_W + GAP_X) + (BOX_W - NAME_GARC_W)/2;
    constant NAME_GARC_Y0 : integer := BOX_Y + BOX_H + 10;

    constant NAME_TORT_X0 : integer :=
        BOX_X0 + 4*(BOX_W + GAP_X) + (BOX_W - NAME_TORT_W)/2;
    constant NAME_TORT_Y0 : integer := BOX_Y + BOX_H + 10;

    constant NAME_BIDO_X0 : integer :=
        BOX_X0 + (BOX_W - NAME_BIDO_W)/2;
    constant NAME_BIDO_Y0 : integer := ROW1_TOP + BOX_H + 10;

    -- font lookup for a single character
    function font_row(
        ch  : character;
        row : integer
    ) return std_logic_vector is
    begin
        case ch is
            when 'A' => return CHAR_A(row);
            when 'B' => return CHAR_B(row);
            when 'C' => return CHAR_C(row);
            when 'D' => return CHAR_D(row);
            when 'E' => return CHAR_E(row);
            when 'F' => return CHAR_F(row);
            when 'G' => return CHAR_G(row);
            when 'H' => return CHAR_H(row);
            when 'I' => return CHAR_I(row);
            when 'K' => return CHAR_K(row);
            when 'L' => return CHAR_L(row);
            when 'M' => return CHAR_M(row);
            when 'N' => return CHAR_N(row);
            when 'O' => return CHAR_O(row);
            when 'P' => return CHAR_P(row);
            when 'R' => return CHAR_R(row);
            when 'T' => return CHAR_T(row);
            when 'U' => return CHAR_U(row);
            when others =>
                return (others => '0');  -- blank
        end case;
    end function;

    -- Selecting Pokemon

    signal cursor_idx  : integer range 0 to 9 := 0;  -- highlighted box index
    signal sel_count   : integer range 0 to 3 := 0;  -- how many chosen (0..3)
    signal team0_reg   : poke_id_t := P0;
    signal team1_reg   : poke_id_t := P1;
    signal team2_reg   : poke_id_t := P2;
    signal done_reg    : std_logic := '0';

    -- button edge detection
    signal btnl_prev, btnr_prev, btnc_prev : std_logic := '0';
    signal btnu_prev, btnd_prev            : std_logic := '0';

    -- ignore the very first BTNC edge (Intro → choose screen)
    signal ignore_first_c : std_logic := '1';

    -- helper: map box index (0..5) -> poke ID (in desired order)
    function idx_to_poke(idx : integer) return poke_id_t is
    begin
        case idx is
            when 0 => return P0; -- Pikachu
            when 1 => return P1; -- Giratina
            when 2 => return P2; -- Empoleon
            when 3 => return P3; -- Garchomp
            when 4 => return P4; -- Torterra
            when 5 => return P5; -- Bidoof
            when others =>
                return (others => '0'); -- not used for empty slots
        end case;
    end function;

begin

    ----------------------------------------------------------------
    -- Selection state machine (clocked)
    ----------------------------------------------------------------
    process(clk)
        variable l_edge, r_edge, c_edge : boolean;
        variable u_edge, d_edge         : boolean;
        variable chosen_id : poke_id_t;
        variable already   : boolean;
    begin
        if rising_edge(clk) then
            -- rising-edge detect
            l_edge := (btnl = '1' and btnl_prev = '0');
            r_edge := (btnr = '1' and btnr_prev = '0');
            c_edge := (btnc = '1' and btnc_prev = '0');
            u_edge := (btnu = '1' and btnu_prev = '0');
            d_edge := (btnd = '1' and btnd_prev = '0');

            if done_reg = '0' then
                -- move cursor left / right across 0..9
                if l_edge and cursor_idx > 0 then
                    cursor_idx <= cursor_idx - 1;
                elsif r_edge and cursor_idx < 9 then
                    cursor_idx <= cursor_idx + 1;
                end if;

                -- move cursor up/down between rows (jump by 5)
                if u_edge and cursor_idx >= 5 then
                    cursor_idx <= cursor_idx - 5;
                elsif d_edge and cursor_idx <= 4 then
                    cursor_idx <= cursor_idx + 5;
                end if;

                -- choose current Pokémon into next slot
                if c_edge then
                    if ignore_first_c = '1' then
                        -- consume the first press (used by Intro)
                        ignore_first_c <= '0';
                    else
                        -- only selectable if cursor_idx in 0..5
                        if (sel_count < 3) and (cursor_idx <= 5) then
                            chosen_id := idx_to_poke(cursor_idx);

                            -- check if this Pokémon is already in the team
                            already := false;
                            if (sel_count > 0) and (chosen_id = team0_reg) then
                                already := true;
                            end if;
                            if (sel_count > 1) and (chosen_id = team1_reg) then
                                already := true;
                            end if;
                            if (sel_count > 2) and (chosen_id = team2_reg) then
                                already := true;
                            end if;

                            -- only add if not already chosen
                            if not already then
                                case sel_count is
                                    when 0 =>
                                        team0_reg <= chosen_id;
                                        sel_count <= 1;
                                    when 1 =>
                                        team1_reg <= chosen_id;
                                        sel_count <= 2;
                                    when 2 =>
                                        team2_reg <= chosen_id;
                                        sel_count <= 3;
                                        done_reg  <= '1'; -- all 3 chosen
                                    when others =>
                                        null;
                                end case;
                            end if;
                        end if;  -- valid selectable slot
                    end if;
                end if;
            end if;

            -- store previous button states
            btnl_prev <= btnl;
            btnr_prev <= btnr;
            btnc_prev <= btnc;
            btnu_prev <= btnu;
            btnd_prev <= btnd;
        end if;
    end process;

    team_p0 <= team0_reg;
    team_p1 <= team1_reg;
    team_p2 <= team2_reg;
    done    <= done_reg;

    ----------------------------------------------------------------
    -- VGA drawing (combinational)
    ----------------------------------------------------------------
    process(pixel_row, pixel_col, cursor_idx, sel_count,
            team0_reg, team1_reg, team2_reg)
        variable x, y  : integer;
        variable inside, border : boolean;
        variable box_left, box_top : integer;
        variable idx      : integer;
        variable this_id  : poke_id_t;
        variable is_chosen: boolean;

        variable sx, sy   : integer;
        variable color_idx : std_logic_vector(3 downto 0);

        variable char_idx : integer;
        variable col_in   : integer;
        variable row_in   : integer;
        variable char_row : std_logic_vector(4 downto 0);
        variable col_idx  : integer;
        variable row_idx  : integer;

        -- temp RGB vars for sprite color procedures
        variable pr, pg, pb : std_logic_vector(3 downto 0); -- Pikachu
        variable grr, grg, grb : std_logic_vector(3 downto 0); -- Giratina
        variable cr, cg, cb : std_logic_vector(3 downto 0); -- Garchomp
        variable er, eg, eb : std_logic_vector(3 downto 0); -- Empoleon
        variable br, bg, bb : std_logic_vector(3 downto 0); -- Bidoof
        variable tr, tg, tb : std_logic_vector(3 downto 0); -- Torterra
    begin
        x := to_integer(unsigned(pixel_col));
        y := to_integer(unsigned(pixel_row));

        -- background
        red   <= "0000";
        green <= "0000";
        blue  <= "1000"; -- dark blue

        -- title band
        if y < 100 then
            red   <= "0010";
            green <= "0010";
            blue  <= "1111";
        end if;

        ----------------------------------------------------------------
        -- 10 selection boxes: 5 columns × 2 rows
        ----------------------------------------------------------------
        for idx in 0 to 9 loop
            col_idx := idx mod 5;
            row_idx := idx / 5; -- 0 or 1

            box_left := BOX_X0 + col_idx * (BOX_W + GAP_X);

            -- second row shifted 25 pixels down
            if row_idx = 0 then
                box_top  := BOX_Y;
            else
                box_top  := ROW1_TOP;
            end if;

            inside := (x >= box_left) and (x < box_left + BOX_W) and
                      (y >= box_top)  and (y < box_top + BOX_H);

            if inside then
                -- is this a real Pokémon slot? (0..5) or empty (6..9)
                if idx <= 5 then
                    this_id := idx_to_poke(idx);

                    -- check if this Pokémon is already chosen
                    is_chosen := false;
                    if (sel_count > 0) and (this_id = team0_reg) then
                        is_chosen := true;
                    end if;
                    if (sel_count > 1) and (this_id = team1_reg) then
                        is_chosen := true;
                    end if;
                    if (sel_count > 2) and (this_id = team2_reg) then
                        is_chosen := true;
                    end if;

                    -- fill color:
                    -- normal = green-ish, chosen = light blue
                    if is_chosen then
                        -- light blue for chosen Pokémon
                        red   <= "0011";
                        green <= "0111";
                        blue  <= "1111";
                    else
                        red   <= "0011";
                        green <= "1011";
                        blue  <= "0011";  -- green-ish
                    end if;
                else
                    -- empty/unselectable slot: grey box
                    is_chosen := false;
                    red   <= "0010";
                    green <= "0010";
                    blue  <= "0010";
                end if;

                ----------------------------------------------------------------
                -- Pikachu sprite in the first box (idx = 0)
                ----------------------------------------------------------------
                if idx = 0 then
                    sx := x - box_left - PIKA_OFF_X;
                    sy := y - box_top  - PIKA_OFF_Y;

                    if (sx >= 0) and (sx < PIKA_W) and
                       (sy >= 0) and (sy < PIKA_H) then
                        color_idx := PIKACHU_SPRITE(sy)(sx);

                        if color_idx /= "0000" then
                            pikachu_color(color_idx, pr, pg, pb);
                            red   <= pr;
                            green <= pg;
                            blue  <= pb;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Giratina sprite in the second box (idx = 1)
                ----------------------------------------------------------------
                if idx = 1 then
                    sx := x - box_left - GIR_OFF_X;
                    sy := y - box_top  - GIR_OFF_Y;

                    if (sx >= 0) and (sx < GIR_W) and
                       (sy >= 0) and (sy < GIR_H) then
                        color_idx := GIRATINA_FRONT(sy)(sx);

                        if color_idx /= "0000" then
                            giratina_color(color_idx, grr, grg, grb);
                            red   <= grr;
                            green <= grg;
                            blue  <= grb;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Empoleon sprite in the third box (idx = 2)
                ----------------------------------------------------------------
                if idx = 2 then
                    sx := x - box_left - EMP_OFF_X;
                    sy := y - box_top  - EMP_OFF_Y;

                    if (sx >= 0) and (sx < EMP_W) and
                       (sy >= 0) and (sy < EMP_H) then
                        color_idx := EMPOLEON_FRONT(sy)(sx);

                        if color_idx /= "0000" then
                            empoleon_color(color_idx, er, eg, eb);
                            red   <= er;
                            green <= eg;
                            blue  <= eb;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Garchomp sprite in the fourth box (idx = 3)
                ----------------------------------------------------------------
                if idx = 3 then
                    sx := x - box_left - GARCH_OFF_X;
                    sy := y - box_top  - GARCH_OFF_Y;

                    if (sx >= 0) and (sx < GARCH_W) and
                       (sy >= 0) and (sy < GARCH_H) then
                        color_idx := GARCHOMP_FRONT(sy)(sx);

                        if color_idx /= "0000" then
                            garchomp_color(color_idx, cr, cg, cb);
                            red   <= cr;
                            green <= cg;
                            blue  <= cb;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Torterra sprite in the fifth box (idx = 4)
                ----------------------------------------------------------------
                if idx = 4 then
                    sx := x - box_left - TORT_OFF_X;
                    sy := y - box_top  - TORT_OFF_Y;

                    if (sx >= 0) and (sx < TORTERRA_W) and
                       (sy >= 0) and (sy < TORTERRA_H) then
                        color_idx := TORTERRA_FRONT(sy)(sx);

                        if color_idx /= "0000" then
                            torterra_color(color_idx, tr, tg, tb);
                            red   <= tr;
                            green <= tg;
                            blue  <= tb;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Bidoof sprite in the sixth box (idx = 5)
                ----------------------------------------------------------------
                if idx = 5 then
                    sx := x - box_left - BID_OFF_X;
                    sy := y - box_top  - BID_OFF_Y;

                    if (sx >= 0) and (sx < BIDOOF_W) and
                       (sy >= 0) and (sy < BIDOOF_H) then
                        color_idx := BIDOOF_FRONT(sy)(sx);

                        if color_idx /= "0000" then
                            bidoof_color(color_idx, br, bg, bb);
                            red   <= br;
                            green <= bg;
                            blue  <= bb;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- border if cursor is on this box
                ----------------------------------------------------------------
                border :=
                    (x = box_left) or (x = box_left + BOX_W - 1) or
                    (y = box_top)  or (y = box_top + BOX_H - 1);

                if (idx = cursor_idx) and border then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end loop;

        ----------------------------------------------------------------
        -- NAME LABELS (2x size, white) for each Pokémon
        ----------------------------------------------------------------

        -- PIKACHU
        if (y >= NAME_PIKA_Y0) and (y < NAME_PIKA_Y0 + NAME_H_PIX) and
           (x >= NAME_PIKA_X0) and (x < NAME_PIKA_X0 + NAME_PIKA_W) then

            row_in   := (y - NAME_PIKA_Y0) / SCALE_NAME;  -- 0..6
            char_idx := (x - NAME_PIKA_X0) / NAME_ADVANCE; -- 0..len-1
            col_in   := ((x - NAME_PIKA_X0) / SCALE_NAME)
                        mod (NAME_CHAR_W + NAME_CHAR_SP); -- 0..5

            if (char_idx >= 0) and (char_idx < NAME_PIKA'length) and
               (col_in >= 0) and (col_in < NAME_CHAR_W) then
                char_row := font_row(NAME_PIKA(char_idx+1), row_in);
                if char_row(NAME_CHAR_W-1 - col_in) = '1' then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end if;

        -- GIRATINA
        if (y >= NAME_GIRA_Y0) and (y < NAME_GIRA_Y0 + NAME_H_PIX) and
           (x >= NAME_GIRA_X0) and (x < NAME_GIRA_X0 + NAME_GIRA_W) then

            row_in   := (y - NAME_GIRA_Y0) / SCALE_NAME;
            char_idx := (x - NAME_GIRA_X0) / NAME_ADVANCE;
            col_in   := ((x - NAME_GIRA_X0) / SCALE_NAME)
                        mod (NAME_CHAR_W + NAME_CHAR_SP);

            if (char_idx >= 0) and (char_idx < NAME_GIRA'length) and
               (col_in >= 0) and (col_in < NAME_CHAR_W) then
                char_row := font_row(NAME_GIRA(char_idx+1), row_in);
                if char_row(NAME_CHAR_W-1 - col_in) = '1' then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end if;

        -- EMPOLEON
        if (y >= NAME_EMPO_Y0) and (y < NAME_EMPO_Y0 + NAME_H_PIX) and
           (x >= NAME_EMPO_X0) and (x < NAME_EMPO_X0 + NAME_EMPO_W) then

            row_in   := (y - NAME_EMPO_Y0) / SCALE_NAME;
            char_idx := (x - NAME_EMPO_X0) / NAME_ADVANCE;
            col_in   := ((x - NAME_EMPO_X0) / SCALE_NAME)
                        mod (NAME_CHAR_W + NAME_CHAR_SP);

            if (char_idx >= 0) and (char_idx < NAME_EMPO'length) and
               (col_in >= 0) and (col_in < NAME_CHAR_W) then
                char_row := font_row(NAME_EMPO(char_idx+1), row_in);
                if char_row(NAME_CHAR_W-1 - col_in) = '1' then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end if;

        -- GARCHOMP
        if (y >= NAME_GARC_Y0) and (y < NAME_GARC_Y0 + NAME_H_PIX) and
           (x >= NAME_GARC_X0) and (x < NAME_GARC_X0 + NAME_GARC_W) then

            row_in   := (y - NAME_GARC_Y0) / SCALE_NAME;
            char_idx := (x - NAME_GARC_X0) / NAME_ADVANCE;
            col_in   := ((x - NAME_GARC_X0) / SCALE_NAME)
                        mod (NAME_CHAR_W + NAME_CHAR_SP);

            if (char_idx >= 0) and (char_idx < NAME_GARC'length) and
               (col_in >= 0) and (col_in < NAME_CHAR_W) then
                char_row := font_row(NAME_GARC(char_idx+1), row_in);
                if char_row(NAME_CHAR_W-1 - col_in) = '1' then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end if;

        -- TORTERRA
        if (y >= NAME_TORT_Y0) and (y < NAME_TORT_Y0 + NAME_H_PIX) and
           (x >= NAME_TORT_X0) and (x < NAME_TORT_X0 + NAME_TORT_W) then

            row_in   := (y - NAME_TORT_Y0) / SCALE_NAME;
            char_idx := (x - NAME_TORT_X0) / NAME_ADVANCE;
            col_in   := ((x - NAME_TORT_X0) / SCALE_NAME)
                        mod (NAME_CHAR_W + NAME_CHAR_SP);

            if (char_idx >= 0) and (char_idx < NAME_TORT'length) and
               (col_in >= 0) and (col_in < NAME_CHAR_W) then
                char_row := font_row(NAME_TORT(char_idx+1), row_in);
                if char_row(NAME_CHAR_W-1 - col_in) = '1' then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end if;

        -- BIDOOF (second row)
        if (y >= NAME_BIDO_Y0) and (y < NAME_BIDO_Y0 + NAME_H_PIX) and
           (x >= NAME_BIDO_X0) and (x < NAME_BIDO_X0 + NAME_BIDO_W) then

            row_in   := (y - NAME_BIDO_Y0) / SCALE_NAME;
            char_idx := (x - NAME_BIDO_X0) / NAME_ADVANCE;
            col_in   := ((x - NAME_BIDO_X0) / SCALE_NAME)
                        mod (NAME_CHAR_W + NAME_CHAR_SP);

            if (char_idx >= 0) and (char_idx < NAME_BIDO'length) and
               (col_in >= 0) and (col_in < NAME_CHAR_W) then
                char_row := font_row(NAME_BIDO(char_idx+1), row_in);
                if char_row(NAME_CHAR_W-1 - col_in) = '1' then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                end if;
            end if;
        end if;

    end process;

end architecture Behavioral;
