library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Attacks is
    port (
        attacker_id : in  std_logic_vector(2 downto 0);
        defender_id : in  std_logic_vector(2 downto 0);
        move_id     : in  std_logic_vector(1 downto 0);  -- 0..3
        damage      : out std_logic_vector(7 downto 0)
    );
end entity;

architecture Behavioral of Attacks is

    component pokemonLists
        port (
            id         : in  std_logic_vector(2 downto 0);
            base_hp    : out std_logic_vector(7 downto 0);
            base_atk   : out std_logic_vector(7 downto 0);
            base_def   : out std_logic_vector(7 downto 0);
            base_speed : out std_logic_vector(7 downto 0)
        );
    end component;

    signal atk_hp, atk_atk, atk_def, atk_spd : std_logic_vector(7 downto 0);
    signal def_hp, def_atk, def_def, def_spd : std_logic_vector(7 downto 0);

begin

    u_atk_stats : pokemonLists
        port map (
            id         => attacker_id,
            base_hp    => atk_hp,
            base_atk   => atk_atk,
            base_def   => atk_def,
            base_speed => atk_spd
        );

    u_def_stats : pokemonLists
        port map (
            id         => defender_id,
            base_hp    => def_hp,
            base_atk   => def_atk,
            base_def   => def_def,
            base_speed => def_spd
        );

    process(atk_atk, def_def, move_id)
        variable atk_i  : integer;
        variable def_i  : integer;
        variable power  : integer;
        variable dmg_i  : integer;
    begin
        atk_i := to_integer(unsigned(atk_atk));
        def_i := to_integer(unsigned(def_def));

        -- Simple move power:
        -- 00: light (power 10)
        -- 01: medium (20)
        -- 10: strong (30)
        -- 11: super (40)
        case move_id is
            when "00" => power := 10;
            when "01" => power := 20;
            when "10" => power := 30;
            when others => power := 40;
        end case;

        -- Very simple damage formula:
        dmg_i := (atk_i / 4) + power - (def_i / 8);

        if dmg_i < 1 then
            dmg_i := 1;
        elsif dmg_i > 255 then
            dmg_i := 255;
        end if;

        damage <= std_logic_vector(to_unsigned(dmg_i, 8));
    end process;

end architecture;
