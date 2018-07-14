defmodule Physdash do
  @moduledoc """
  Documentation for Physdash.
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{command: ""}, name: __MODULE__)
  end

  def init(state) do
    Keypad.start_link([25, 2, 27], [9, 10, 22, 17])
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
