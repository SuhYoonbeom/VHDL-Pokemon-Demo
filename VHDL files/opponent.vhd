library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity opponent is
    port (
        player_p0 : in  std_logic_vector(2 downto 0);
        player_p1 : in  std_logic_vector(2 downto 0);
        player_p2 : in  std_logic_vector(2 downto 0);
        enemy_p0  : out std_logic_vector(2 downto 0);
        enemy_p1  : out std_logic_vector(2 downto 0);
        enemy_p2  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture Behavioral of opponent is
begin
    process(player_p0, player_p1, player_p2)
        type id_array_t is array (0 to 2) of std_logic_vector(2 downto 0);
        variable chosen : id_array_t;
        variable idx    : integer := 0;
        variable i      : integer;
        variable cur_id : std_logic_vector(2 downto 0);
    begin
        chosen(0) := "000";
        chosen(1) := "001";
        chosen(2) := "010";
        idx := 0;

        -- loop through all 6 IDs: 000..101
        for i in 0 to 5 loop
            cur_id := std_logic_vector(to_unsigned(i, 3));
            if (cur_id /= player_p0) and
               (cur_id /= player_p1) and
               (cur_id /= player_p2) then
                if idx <= 2 then
                    chosen(idx) := cur_id;
                    idx := idx + 1;
                end if;
            end if;
        end loop;

        enemy_p0 <= chosen(0);
        enemy_p1 <= chosen(1);
        enemy_p2 <= chosen(2);
    end process;
end architecture;
