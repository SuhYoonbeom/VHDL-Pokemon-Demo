library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture Behavioral of Intro is

    ------------------------------------------------------------
    -- Button edge detect
    ------------------------------------------------------------
    signal btnc_prev : std_logic := '0';
    signal done_int  : std_logic := '0';

    ------------------------------------------------------------
    -- 5x7 BLOCK FONT
    ------------------------------------------------------------
    type char7x5_t is array(0 to 6) of std_logic_vector(4 downto 0);

    constant CHAR_A : char7x5_t := (
        "01110","10001","10001","11111","10001","10001","10001"
    );
    constant CHAR_B : char7x5_t := (
        "11110","10001","11110","10001","10001","10001","11110"
    );
    constant CHAR_C : char7x5_t := (
        "01110","10001","10000","10000","10000","10001","01110"
    );
    constant CHAR_D : char7x5_t := (
        "11100","10010","10001","10001","10001","10010","11100"
    );
    constant CHAR_E : char7x5_t := (
        "11111","10000","11110","10000","10000","10000","11111"
    );
    constant CHAR_F : char7x5_t := (
        "11111","10000","11110","10000","10000","10000","10000"
    );
    -- NEW: I
    constant CHAR_I : char7x5_t := (
        "00100","00100","00100","00100","00100","00100","00100"
    );
    -- NEW: K
    constant CHAR_K : char7x5_t := (
        "10001","10010","10100","11000","10100","10010","10001"
    );
    constant CHAR_L : char7x5_t := (
        "10000","10000","10000","10000","10000","10000","11111"
    );
    constant CHAR_M : char7x5_t := (
        "10001","11011","10101","10001","10001","10001","10001"
    );
    constant CHAR_N : char7x5_t := (
        "10001","11001","10101","10011","10001","10001","10001"
    );
    constant CHAR_O : char7x5_t := (
        "01110","10001","10001","10001","10001","10001","01110"
    );
    constant CHAR_P : char7x5_t := (
        "11110","10001","10001","11110","10000","10000","10000"
    );
    constant CHAR_R : char7x5_t := (
        "11110","10001","10001","11110","10100","10010","10001"
    );
    constant CHAR_S : char7x5_t := (
        "01111","10000","10000","01110","00001","00001","11110"
    );
    constant CHAR_T : char7x5_t := (
        "11111","00100","00100","00100","00100","00100","00100"
    );
    constant CHAR_U : char7x5_t := (
        "10001","10001","10001","10001","10001","10001","01110"
    );
    constant CHAR_Y : char7x5_t := (
        "10001","10001","01010","00100","00100","00100","00100"
    );
    constant CHAR_SPACE : char7x5_t := (
        "00000","00000","00000","00000","00000","00000","00000"
    );

    ------------------------------------------------------------
    -- Map character → 5x7 row
    ------------------------------------------------------------
    function get_char(c : character; row : integer) return std_logic_vector is
    begin
        case c is
            when 'A' => return CHAR_A(row);
            when 'B' => return CHAR_B(row);
            when 'C' => return CHAR_C(row);
            when 'D' => return CHAR_D(row);
            when 'E' => return CHAR_E(row);
            when 'F' => return CHAR_F(row);
            when 'I' => return CHAR_I(row);
            when 'K' => return CHAR_K(row);
            when 'L' => return CHAR_L(row);
            when 'M' => return CHAR_M(row);
            when 'N' => return CHAR_N(row);
            when 'O' => return CHAR_O(row);
            when 'P' => return CHAR_P(row);
            when 'R' => return CHAR_R(row);
            when 'S' => return CHAR_S(row);
            when 'T' => return CHAR_T(row);
            when 'U' => return CHAR_U(row);
            when 'Y' => return CHAR_Y(row);
            when others => return CHAR_SPACE(row);
        end case;
    end function;

    ------------------------------------------------------------
    -- Text definitions
    ------------------------------------------------------------
    constant TITLE_TEXT  : string := "POKEMON BATTLE DEMO";
    constant SUB_TEXT    : string := "FOR EDUCATIONAL PURPOSES ONLY";

    ------------------------------------------------------------
    -- Scaling
    ------------------------------------------------------------
    constant SCALE_TITLE : integer := 3;  -- bigger text
    constant SCALE_SUB   : integer := 2;  -- medium text

begin

    ------------------------------------------------------------
    -- Detect button press to exit intro
    ------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if (btnc = '1') and (btnc_prev = '0') then
                done_int <= '1';
            end if;
            btnc_prev <= btnc;
        end if;
    end process;

    done <= done_int;

    ------------------------------------------------------------
    -- Drawing
    ------------------------------------------------------------
    process(pixel_row, pixel_col)
        variable x, y : integer;
        variable r, g, b : std_logic_vector(3 downto 0);
        variable char_row : std_logic_vector(4 downto 0);
        variable row_in, col_in : integer;
        variable col_idx, char_idx : integer;
        variable text_w, text_x0, text_y0 : integer;
        variable sub_w, sub_x0, sub_y0 : integer;
    begin
        x := to_integer(unsigned(pixel_col));
        y := to_integer(unsigned(pixel_row));

        ------------------------------------------------------------
        -- BACKGROUND (dark blue)
        ------------------------------------------------------------
        r := "0000"; g := "0001"; b := "0011";

        ------------------------------------------------------------
        -- BIG YELLOW TITLE BOX
        ------------------------------------------------------------
        if (y >= 120 and y <= 240) and (x >= 80 and x <= 720) then
            r := "1111"; g := "1111"; b := "0000";
        end if;

        ------------------------------------------------------------
        -- TEXT INSIDE TITLE BOX - "POKEMON BATTLE DEMO"
        ------------------------------------------------------------
        text_w := TITLE_TEXT'length * (6 * SCALE_TITLE); -- 5px glyph +1px space
        text_x0 := 400 - text_w/2;
        text_y0 := 150;

        if (x >= text_x0 and x < text_x0 + text_w) and
           (y >= text_y0 and y < text_y0 + 7*SCALE_TITLE) then

            row_in := (y - text_y0) / SCALE_TITLE;
            col_in := (x - text_x0) / SCALE_TITLE;

            char_idx := col_in / 6;
            if char_idx < TITLE_TEXT'length then
                col_idx := col_in mod 6;
                if col_idx < 5 then
                    char_row := get_char(TITLE_TEXT(char_idx+1), row_in);
                    if char_row(4 - col_idx) = '1' then
                        r := "0000"; g := "0000"; b := "0000"; -- black text
                    end if;
                end if;
            end if;
        end if;

        ------------------------------------------------------------
        -- GREEN SUBTITLE BOX
        ------------------------------------------------------------
        if (y >= 260 and y <= 320) and (x >= 140 and x <= 660) then
            r := "0000"; g := "1111"; b := "0000";
        end if;

        ------------------------------------------------------------
        -- TEXT - "FOR EDUCATIONAL PURPOSES ONLY"
        ------------------------------------------------------------
        sub_w := SUB_TEXT'length * (6 * SCALE_SUB);
        sub_x0 := 400 - sub_w/2;
        sub_y0 := 275;

        if (x >= sub_x0 and x < sub_x0 + sub_w) and
           (y >= sub_y0 and y < sub_y0 + 7*SCALE_SUB) then

            row_in := (y - sub_y0) / SCALE_SUB;
            col_in := (x - sub_x0) / SCALE_SUB;

            char_idx := col_in / 6;
            if char_idx < SUB_TEXT'length then
                col_idx := col_in mod 6;
                if col_idx < 5 then
                    char_row := get_char(SUB_TEXT(char_idx+1), row_in);
                    if char_row(4 - col_idx) = '1' then
                        r := "0000"; g := "0000"; b := "0000"; -- black font
                    end if;
                end if;
            end if;
        end if;

        red <= r; 
        green <= g; 
        blue <= b;
    end process;

end architecture;
