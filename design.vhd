-- Traffic light controller (two-way intersection)
-- A finite state machine cycles through four states. A counter holds
-- each state for a set number of clock cycles.
--
--   NS green  -> NS yellow -> EW green -> EW yellow -> (repeat)
--
-- While one direction is green or yellow, the other direction is red,
-- so both directions can never be green at the same time.

library ieee;
use ieee.std_logic_1164.all;

entity traffic is
  generic (
    GREEN_TIME  : positive := 10;  -- clock cycles each direction stays green
    YELLOW_TIME : positive := 3    -- clock cycles each direction stays yellow
  );
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;     -- synchronous, active high
    ns_red    : out std_logic;
    ns_yellow : out std_logic;
    ns_green  : out std_logic;
    ew_red    : out std_logic;
    ew_yellow : out std_logic;
    ew_green  : out std_logic
  );
end entity traffic;

architecture rtl of traffic is

  type state_t is (NS_GREEN_S, NS_YELLOW_S, EW_GREEN_S, EW_YELLOW_S);

  signal state      : state_t := NS_GREEN_S;
  signal next_state : state_t;
  signal timer      : integer range 0 to GREEN_TIME := 0;
  signal timer_done : std_logic;

begin

  -- State and timer registers (the only clocked process)
  seq : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= NS_GREEN_S;
        timer <= 0;
      elsif timer_done = '1' then
        state <= next_state;
        timer <= 0;
      else
        timer <= timer + 1;
      end if;
    end if;
  end process seq;

  -- The timer is done on the last cycle of the current state
  done_logic : process (state, timer)
  begin
    case state is
      when NS_GREEN_S | EW_GREEN_S =>
        if timer = GREEN_TIME - 1 then
          timer_done <= '1';
        else
          timer_done <= '0';
        end if;
      when NS_YELLOW_S | EW_YELLOW_S =>
        if timer = YELLOW_TIME - 1 then
          timer_done <= '1';
        else
          timer_done <= '0';
        end if;
    end case;
  end process done_logic;

  -- Next-state logic
  next_logic : process (state)
  begin
    case state is
      when NS_GREEN_S  => next_state <= NS_YELLOW_S;
      when NS_YELLOW_S => next_state <= EW_GREEN_S;
      when EW_GREEN_S  => next_state <= EW_YELLOW_S;
      when EW_YELLOW_S => next_state <= NS_GREEN_S;
    end case;
  end process next_logic;

  -- Outputs depend only on the current state (Moore machine)
  ns_green  <= '1' when state = NS_GREEN_S  else '0';
  ns_yellow <= '1' when state = NS_YELLOW_S else '0';
  ns_red    <= '1' when state = EW_GREEN_S or state = EW_YELLOW_S else '0';

  ew_green  <= '1' when state = EW_GREEN_S  else '0';
  ew_yellow <= '1' when state = EW_YELLOW_S else '0';
  ew_red    <= '1' when state = NS_GREEN_S or state = NS_YELLOW_S else '0';

end architecture rtl;
