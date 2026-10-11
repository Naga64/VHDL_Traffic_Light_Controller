-- Testbench for the traffic light controller.
-- Checks on every clock cycle that:
--   1. Both directions are never green at the same time
--   2. Each direction has exactly one light on
-- And at the end that both directions actually got a green light.

library ieee;
use ieee.std_logic_1164.all;

entity tb_traffic is
end entity tb_traffic;

architecture sim of tb_traffic is

  constant CLK_PERIOD : time := 10 ns;

  signal clk       : std_logic := '0';
  signal reset     : std_logic := '1';
  signal ns_red, ns_yellow, ns_green : std_logic;
  signal ew_red, ew_yellow, ew_green : std_logic;

  signal done         : boolean := false;
  signal ns_green_seen : boolean := false;
  signal ew_green_seen : boolean := false;

begin

  -- Device under test
  uut : entity work.traffic
    generic map (GREEN_TIME => 10, YELLOW_TIME => 3)
    port map (
      clk       => clk,
      reset     => reset,
      ns_red    => ns_red,
      ns_yellow => ns_yellow,
      ns_green  => ns_green,
      ew_red    => ew_red,
      ew_yellow => ew_yellow,
      ew_green  => ew_green
    );

  -- Clock generator
  clk_gen : process
  begin
    while not done loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process clk_gen;

  -- Stimulus: reset, then let it run for 120 clock cycles
  stim : process
  begin
    reset <= '1';
    wait for 2 * CLK_PERIOD;
    reset <= '0';
    wait for 120 * CLK_PERIOD;

    assert ns_green_seen report "FAIL: north-south never got a green light" severity failure;
    assert ew_green_seen report "FAIL: east-west never got a green light"   severity failure;
    report "PASS: all checks passed" severity note;

    done <= true;
    wait;
  end process stim;

  -- Safety checker, sampled on each falling clock edge
  checker : process (clk)
  begin
    if falling_edge(clk) and reset = '0' then
      assert not (ns_green = '1' and ew_green = '1')
        report "FAIL: both directions are green" severity failure;

      assert (ns_red = '1' and ns_yellow = '0' and ns_green = '0') or
             (ns_red = '0' and ns_yellow = '1' and ns_green = '0') or
             (ns_red = '0' and ns_yellow = '0' and ns_green = '1')
        report "FAIL: north-south does not have exactly one light on" severity failure;

      assert (ew_red = '1' and ew_yellow = '0' and ew_green = '0') or
             (ew_red = '0' and ew_yellow = '1' and ew_green = '0') or
             (ew_red = '0' and ew_yellow = '0' and ew_green = '1')
        report "FAIL: east-west does not have exactly one light on" severity failure;

      if ns_green = '1' then ns_green_seen <= true; end if;
      if ew_green = '1' then ew_green_seen <= true; end if;
    end if;
  end process checker;

end architecture sim;
