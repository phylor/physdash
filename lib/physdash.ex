defmodule Physdash do
  @moduledoc """
  Documentation for Physdash.
  """

  use GenServer

  @characters Matrix.from_list([["1", "2", "3"],
                                ["4", "5", "6"],
                                ["7", "8", "9"],
                                ["*", "0", "#"]])

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{command: ""}, name: __MODULE__)
  end

  def init(state) do
    Keypad.start_link([5, 17, 13], [27, 26, 22, 16], @characters)
    Keypad.subscribe

    {:ok, state}
  end

  def handle_cast({:key_pressed, character}, state) do
    new_state = if character == "*" do
                  %{state | command: ""}
                else
                  %{state | command: state.command <> character}
                end

    ExLCD.move_to(1, 0)

    displayed_command = String.pad_trailing(new_state.command, 16, " ")
    ExLCD.write(displayed_command)

    {:noreply, new_state}
  end
end
