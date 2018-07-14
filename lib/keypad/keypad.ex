defmodule Keypad do
  use GenServer
  require Logger

  @characters Matrix.from_list([["1", "2", "3"],
                                ["4", "5", "6"],
                                ["7", "8", "9"],
                                ["*", "0", "#"]])

  defmodule Pin do
    defstruct pin: nil, type: nil, index: nil, state: :low, pid: nil
  end

  def start_link(columns \\ [25, 2, 27], rows \\ [9, 10, 22, 17]) do
    pins =
      (columns |> Enum.with_index |> Enum.map(fn {column_pin, index} ->
      %Pin{pin: column_pin, type: :column, index: index}
    end)) ++
      (rows |> Enum.with_index |> Enum.map(fn {row_pin, index} ->
        %Pin{pin: row_pin, type: :row, index: index}
      end))

    column_count = pins |> filter_columns |> Enum.count
    row_count = pins |> filter_rows |> Enum.count

    {:ok, pid} = GenServer.start_link(__MODULE__, %{pins: pins, buttons: Matrix.with_size(column_count, row_count, :low), subscribers: []}, name: __MODULE__)
    Process.send_after(pid, :check_keys, 100)

    {:ok, pid}
  end

  def init(state) do
    pins = Enum.map state.pins, fn pin ->
      mode = if pin.type == :column, do: :output, else: :input

      {:ok, pid} = ElixirALE.GPIO.start_link(pin.pin, mode)

      %{pin | pid: pid}
    end

    {:ok, %{state | pins: pins}}
  end

  # API
  def subscribe do
    GenServer.call(__MODULE__, :subscribe)
  end

  # GenServer callbacks
  def handle_call(:subscribe, from, state) do
    new_subscribers = [elem(from, 0) | state.subscribers]

    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end

  def handle_info(:check_keys, state) do
    buttons = state.pins |> filter_columns |> Enum.map(fn column ->
      ElixirALE.GPIO.write(column.pid, 1)

      states = state.pins |> filter_rows |> Enum.map(fn row ->
        pressed? = ElixirALE.GPIO.read(row.pid) == 1
        already_pressed? = state.buttons[row.index][column.index] == :high

        if pressed? && !already_pressed? do
          character = @characters[row.index][column.index]
          notify_all(state.subscribers, character)

          Logger.info("character: #{character} | column: #{column.index} | row: #{row.index} | pressed")
        end

        new_state = if pressed?, do: :high, else: :low
        new_state
      end)

      ElixirALE.GPIO.write(column.pid, 0)

      states
    end) |> Matrix.flip |> Matrix.from_list

    Process.send_after(__MODULE__, :check_keys, 100)

    {:noreply, %{state | buttons: buttons}}
  end

  defp filter_columns(pins) do
    Enum.filter pins, fn pin -> pin.type == :column end
  end

  defp filter_rows(pins) do
    Enum.filter pins, fn pin -> pin.type == :row end
  end

  defp notify_all(subscribers, character) do
    Enum.each subscribers, fn subscriber ->
      GenServer.cast(subscriber, {:key_pressed, character})
    end
  end
end
