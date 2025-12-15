library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pokemonLists is
    port (
        id         : in  std_logic_vector(2 downto 0);  -- 0..5
        base_hp    : out std_logic_vector(7 downto 0);
        base_atk   : out std_logic_vector(7 downto 0);
        base_def   : out std_logic_vector(7 downto 0);
        base_speed : out std_logic_vector(7 downto 0)
    );
end entity;

architecture Behavioral of pokemonLists is
begin
    -- ID mapping:
    -- 0: Pikachu
    -- 1: Giratina
    -- 2: Empoleon
    -- 3: Garchomp
    -- 4: Bidoof
    -- 5: Torterra

    process(id)
    begin
        case id is
            when "000" => -- Pikachu
                base_hp    <= x"46"; -- 70
                base_atk   <= x"50"; -- 80
                base_def   <= x"30"; -- 48
                base_speed <= x"70"; -- 112
            when "001" => -- Giratina
                base_hp    <= x"78"; -- 120
                base_atk   <= x"7A"; -- 122
                base_def   <= x"7A"; -- 122
                base_speed <= x"46"; -- 70
            when "010" => -- Empoleon
                base_hp    <= x"64"; -- 100
                base_atk   <= x"64"; -- 100
                base_def   <= x"69"; -- 105
                base_speed <= x"41"; -- 65
            when "011" => -- Garchomp
                base_hp    <= x"66"; -- 65
                base_atk   <= x"62"; -- 50
                base_def   <= x"66"; -- 70
                base_speed <= x"32"; -- 50
            when "100" => -- Bidoof
                base_hp    <= x"68"; -- 65
                base_atk   <= x"37"; -- 55
                base_def   <= x"22"; -- 45
                base_speed <= x"22"; -- 45
            when "101" => -- Torterra
                base_hp    <= x"73"; -- 115
                base_atk   <= x"73"; -- 109
                base_def   <= x"73"; -- 105
                base_speed <= x"32"; -- 56
            when others =>
                base_hp    <= x"32";
                base_atk   <= x"32";
                base_def   <= x"32";
                base_speed <= x"32";
        end case;
    end process;
end architecture;
