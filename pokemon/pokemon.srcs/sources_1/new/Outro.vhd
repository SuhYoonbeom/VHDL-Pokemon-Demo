library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture Behavioral of Outro is

    ----------------------------------------------------------------
    -- Simple 5x7 FONT (A-Z, plus "blank" 26)
    ----------------------------------------------------------------
    subtype row_t   is std_logic_vector(4 downto 0);
    type    glyph_t is array(0 to 6) of row_t;
    type    font_t  is array(0 to 25) of glyph_t; -- A..Z

    -- A=0, B=1, ..., Z=25  (same shapes as used in battle file)
    constant FONT : font_t := (
        -- A
        0  => ("01110","10001","10001","11111","10001","10001","10001"),
        -- B
        1  => ("11110","10001","10001","11110","10001","10001","11110"),
        -- C
        2  => ("01110","10001","10000","10000","10000","10001","01110"),
        -- D
        3  => ("11100","10010","10001","10001","10001","10010","11100"),
        -- E
        4  => ("11111","10000","10000","11110","10000","10000","11111"),
        -- F
        5  => ("11111","10000","10000","11110","10000","10000","10000"),
        -- G
        6  => ("01110","10001","10000","10000","10011","10001","01110"),
        -- H
        7  => ("10001","10001","10001","11111","10001","10001","10001"),
        -- I
        8  => ("11111","00100","00100","00100","00100","00100","11111"),
        -- J
        9  => ("00001","00001","00001","00001","10001","10001","01110"),
        -- K
        10 => ("10001","10010","10100","11000","10100","10010","10001"),
        -- L
        11 => ("10000","10000","10000","10000","10000","10000","11111"),
        -- M
        12 => ("10001","11011","10101","10101","10001","10001","10001"),
        -- N
        13 => ("10001","11001","10101","10011","10001","10001","10001"),
        -- O
        14 => ("01110","10001","10001","10001","10001","10001","01110"),
        -- P
        15 => ("11110","10001","10001","11110","10000","10000","10000"),
        -- Q
        16 => ("01110","10001","10001","10001","10101","10010","01101"),
        -- R
        17 => ("11110","10001","10001","11110","10100","10010","10001"),
        -- S
        18 => ("01111","10000","10000","01110","00001","00001","11110"),
        -- T
        19 => ("11111","00100","00100","00100","00100","00100","00100"),
        -- U
        20 => ("10001","10001","10001","10001","10001","10001","01110"),
        -- V
        21 => ("10001","10001","10001","10001","10001","01010","00100"),
        -- W
        22 => ("10001","10001","10001","10101","10101","11011","10001"),
        -- X
        23 => ("10001","10001","01010","00100","01010","10001","10001"),
        -- Y
        24 => ("10001","10001","01010","00100","00100","00100","00100"),
        -- Z
        25 => ("11111","00001","00010","00100","01000","10000","11111")
    );

    -- font_pixel: returns '1' if pixel for letter idx (0..25) at (gx,gy) is set
    function font_pixel(
        idx : integer;    -- 0..25 (A..Z)
        gx  : integer;    -- 0..4
        gy  : integer     -- 0..6
    ) return std_logic is
    begin
        if (idx < 0) or (idx > 25) then
            return '0';
        end if;
        if (gx < 0) or (gx > 4) or (gy < 0) or (gy > 6) then
            return '0';
        end if;
        if FONT(idx)(gy)(4-gx) = '1' then
            return '1';
        else
            return '0';
        end if;
    end function;

    ----------------------------------------------------------------
    -- Message mapping
    ----------------------------------------------------------------
    -- 26 indicates a "space" (no letter drawn)
    function winlose_char_idx(
        is_win  : std_logic;
        pos     : integer
    ) return integer is
    begin
        if is_win = '1' then
            -- "YOU WON"  (length = 7)
            case pos is
                when 0 => return 24; -- Y
                when 1 => return 14; -- O
                when 2 => return 20; -- U
                when 3 => return 26; -- space
                when 4 => return 22; -- W
                when 5 => return 14; -- O
                when 6 => return 13; -- N
                when others => return 26;
            end case;
        else
            -- "YOU LOST" (length = 8)
            case pos is
                when 0 => return 24; -- Y
                when 1 => return 14; -- O
                when 2 => return 20; -- U
                when 3 => return 26; -- space
                when 4 => return 11; -- L
                when 5 => return 14; -- O
                when 6 => return 18; -- S
                when 7 => return 19; -- T
                when others => return 26;
            end case;
        end if;
    end function;

    -- "MADE BY SEONGJUN AN AND MATTHEW SUH"
    -- indices: A=0, B=1, ..., Z=25, 26=space
    function credit_char_idx(pos : integer) return integer is
    begin
        case pos is
            -- "MADE"
            when  0 => return 12; -- M
            when  1 => return  0; -- A
            when  2 => return  3; -- D
            when  3 => return  4; -- E
            when  4 => return 26; -- space
            -- "BY"
            when  5 => return  1; -- B
            when  6 => return 24; -- Y
            when  7 => return 26; -- space
            -- "SEONGJUN"
            when  8 => return 18; -- S
            when  9 => return  4; -- E
            when 10 => return 14; -- O
            when 11 => return 13; -- N
            when 12 => return  6; -- G
            when 13 => return  9; -- J
            when 14 => return 20; -- U
            when 15 => return 13; -- N
            when 16 => return 26; -- space
            -- "AN"
            when 17 => return  0; -- A
            when 18 => return 13; -- N
            when 19 => return 26; -- space
            -- "AND"
            when 20 => return  0; -- A
            when 21 => return 13; -- N
            when 22 => return  3; -- D
            when 23 => return 26; -- space
            -- "MATTHEW"
            when 24 => return 12; -- M
            when 25 => return  0; -- A
            when 26 => return 19; -- T
            when 27 => return 19; -- T
            when 28 => return  7; -- H
            when 29 => return  4; -- E
            when 30 => return 22; -- W
            when 31 => return 26; -- space
            -- "SUH"
            when 32 => return 18; -- S
            when 33 => return 20; -- U
            when 34 => return  7; -- H
            when others => return 26;
        end case;
    end function;

    constant CREDIT_LEN : integer := 35;

    ----------------------------------------------------------------
    -- Layout constants
    ----------------------------------------------------------------
    constant SCREEN_W : integer := 800;

    -- Big box (center area for YOU WON / YOU LOST)
    constant BIG_BOX_X1 : integer := 80;
    constant BIG_BOX_X2 : integer := 720;
    constant BIG_BOX_Y1 : integer := 140;
    constant BIG_BOX_Y2 : integer := 340;

    -- Bottom yellow credit box
    constant CREDIT_BOX_X1 : integer := 80;
    constant CREDIT_BOX_X2 : integer := 720;
    constant CREDIT_BOX_Y1 : integer := 380;
    constant CREDIT_BOX_Y2 : integer := 460;

    -- Big text (YOU WON / YOU LOST) using 5x7 font scaled up
    constant BIG_SCALE         : integer := 4;           -- large
    constant BIG_CHAR_SPACING  : integer := 6 * BIG_SCALE; -- pixel spacing per char
    constant BIG_MSG_LEN_WIN   : integer := 7;           -- "YOU WON"
    constant BIG_MSG_LEN_LOSE  : integer := 8;           -- "YOU LOST"
    constant BIG_CHAR_W_PIX    : integer := 5 * BIG_SCALE;
    constant BIG_CHAR_H_PIX    : integer := 7 * BIG_SCALE;

    -- Credit text scale (smaller)
    constant CRED_SCALE        : integer := 2;
    constant CRED_CHAR_SPACING : integer := 6 * CRED_SCALE;
    constant CRED_CHAR_W_PIX   : integer := 5 * CRED_SCALE;
    constant CRED_CHAR_H_PIX   : integer := 7 * CRED_SCALE;

    signal btnc_prev : std_logic := '0';
    signal done_int  : std_logic := '0';

begin

    done <= done_int;

    ----------------------------------------------------------------
    -- button handling
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if (btnc = '1') and (btnc_prev = '0') then
                done_int <= '1';
            end if;
            btnc_prev <= btnc;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Renderer
    ----------------------------------------------------------------
    process(pixel_row, pixel_col, player_win, enemy_win)
        variable y, x : integer;
        variable r, g, b : std_logic_vector(3 downto 0);

        variable is_win        : std_logic;
        variable big_msg_len   : integer;
        variable big_text_w    : integer;
        variable big_x0        : integer;
        variable big_y0        : integer;

        variable gx, gy        : integer;
        variable char_idx      : integer;
        variable letter_idx    : integer;

        variable cred_text_w   : integer;
        variable cred_x0       : integer;
        variable cred_y0       : integer;
    begin
        y := to_integer(unsigned(pixel_row));
        x := to_integer(unsigned(pixel_col));

        -- default background = black
        r := "0000"; g := "0000"; b := "0000";

        ----------------------------------------------------------------
        -- Decide win/lose message
        ----------------------------------------------------------------
        if player_win = '1' then
            is_win      := '1';
            big_msg_len := BIG_MSG_LEN_WIN;  -- "YOU WON"
        elsif enemy_win = '1' then
            is_win      := '0';
            big_msg_len := BIG_MSG_LEN_LOSE; -- "YOU LOST"
        else
            -- No winner flags? just show black screen
            is_win      := '0';
            big_msg_len := BIG_MSG_LEN_WIN;
        end if;

        big_text_w := big_msg_len * BIG_CHAR_SPACING;
        big_x0     := (SCREEN_W - big_text_w)/2;
        big_y0     := (BIG_BOX_Y1 + BIG_BOX_Y2)/2 - BIG_CHAR_H_PIX/2;

        ----------------------------------------------------------------
        -- Big box background
        ----------------------------------------------------------------
        if player_win = '1' then
            -- green box for win
            if (y >= BIG_BOX_Y1 and y <= BIG_BOX_Y2) and
               (x >= BIG_BOX_X1 and x <= BIG_BOX_X2) then
                r := "0000"; g := "1011"; b := "0000";  -- green
            end if;
        elsif enemy_win = '1' then
            -- red box for lose
            if (y >= BIG_BOX_Y1 and y <= BIG_BOX_Y2) and
               (x >= BIG_BOX_X1 and x <= BIG_BOX_X2) then
                r := "1011"; g := "0000"; b := "0000";  -- red
            end if;
        end if;

        ----------------------------------------------------------------
        -- Bottom yellow credit box
        ----------------------------------------------------------------
        if (y >= CREDIT_BOX_Y1 and y <= CREDIT_BOX_Y2) and
           (x >= CREDIT_BOX_X1 and x <= CREDIT_BOX_X2) then
            r := "1111"; g := "1111"; b := "0000";  -- yellow
        end if;

        ----------------------------------------------------------------
        -- Draw big text: "YOU WON" / "YOU LOST" in white in big box
        ----------------------------------------------------------------
        if (y >= big_y0) and (y < big_y0 + BIG_CHAR_H_PIX) then
            if (x >= big_x0) and (x < big_x0 + big_text_w) then
                char_idx := (x - big_x0) / BIG_CHAR_SPACING;
                if (char_idx >= 0) and (char_idx < big_msg_len) then
                    -- local coord inside character
                    gx := ((x - big_x0) mod BIG_CHAR_SPACING) / BIG_SCALE;
                    gy := (y - big_y0) / BIG_SCALE;

                    if (gx >= 0) and (gx < 5) and (gy >= 0) and (gy < 7) then
                        letter_idx := winlose_char_idx(is_win, char_idx);
                        if (letter_idx >= 0) and (letter_idx <= 25) then
                            if font_pixel(letter_idx, gx, gy) = '1' then
                                -- overwrite box color with white text
                                r := "1111"; g := "1111"; b := "1111";
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;

        ----------------------------------------------------------------
        -- Draw credits text in yellow box:
        -- "MADE BY SEONGJUN AN AND MATTHEW SUH"
        ----------------------------------------------------------------
        cred_text_w := CREDIT_LEN * CRED_CHAR_SPACING;
        cred_x0     := (SCREEN_W - cred_text_w)/2;
        cred_y0     := CREDIT_BOX_Y1 + ( (CREDIT_BOX_Y2 - CREDIT_BOX_Y1)/2 ) - (CRED_CHAR_H_PIX/2);

        if (y >= cred_y0) and (y < cred_y0 + CRED_CHAR_H_PIX) then
            if (x >= cred_x0) and (x < cred_x0 + cred_text_w) then
                char_idx := (x - cred_x0) / CRED_CHAR_SPACING;
                if (char_idx >= 0) and (char_idx < CREDIT_LEN) then
                    gx := ((x - cred_x0) mod CRED_CHAR_SPACING) / CRED_SCALE;
                    gy := (y - cred_y0) / CRED_SCALE;

                    if (gx >= 0) and (gx < 5) and (gy >= 0) and (gy < 7) then
                        letter_idx := credit_char_idx(char_idx);
                        if (letter_idx >= 0) and (letter_idx <= 25) then
                            if font_pixel(letter_idx, gx, gy) = '1' then
                                -- dark text on yellow background
                                r := "0000"; g := "0000"; b := "0000";
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;

        red   <= r;
        green <= g;
        blue  <= b;
    end process;

end architecture Behavioral;
