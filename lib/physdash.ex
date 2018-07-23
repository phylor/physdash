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
                  String.to_integer(state.command) |> process_command
                  %{state | command: ""}
                else
                  new_command = state.command <> character

                  displayed_command = String.pad_trailing(new_command, 16, " ")
                  write_line(0, "VERB")
                  write_line(1, displayed_command)

                  %{state | command: new_command}
                end

    {:noreply, new_state}
  end

  defp process_command(1) do
    write_line(0, "IP")
    write_line(1, ip_address)
  end

  defp process_command(command) do
    write_line(0, "Unknown verb")
    write_line(1, Integer.to_string(command))
  end

  defp write_line(line, text) do
    displayed_text = String.pad_trailing(text, 16, " ")

    ExLCD.move_to(line, 0)
    ExLCD.write(displayed_text)
  end

  def ip_address do
    ip_addresses = SystemRegistry.match(:_)
                   |> get_in([:state, :network_interface])
                   |> Map.values
                   |> Enum.filter(fn interface -> Map.has_key?(interface, :ipv4_address) end)
                   |> Enum.map(fn interface -> interface.ipv4_address end)

    [ip_address | _] = ip_addresses

    ip_address
  end
end
