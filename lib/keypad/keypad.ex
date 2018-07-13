defmodule Keypad do
  use GenServer
  require Logger

  # [5, 10, ..]
  def start_link(columns \\ [25, 2, 27], rows \\ [9, 10, 22, 17]) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{columns: columns, rows: rows, subscribers: [], column_pids: [], row_pids: []}, name: __MODULE__)
    Process.send_after(pid, :check_keys, 100)

    {:ok, pid}
  end

  def init(state) do
    column_pids = Enum.map state.columns, fn pin ->
      {:ok, pid} = ElixirALE.GPIO.start_link(pin, :output)
      pid
    end

    row_pids = Enum.map state.rows, fn pin ->
      {:ok, pid} = ElixirALE.GPIO.start_link(pin, :input)
      pid
    end

    {:ok, %{state | column_pids: column_pids, row_pids: row_pids}}
  end

  # API
  def subscribe do
    GenServer.call(__MODULE__, :subscribe)
  end

  # GenServer callbacks
  def handle_call(:subscribe, from, state) do
    new_subscribers = [elem(from, 1) | state.subscribers]

    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end

  def handle_info(:check_keys, state) do
    Enum.with_index(state.column_pids) |> Enum.each(fn {column_pid, column} ->
      ElixirALE.GPIO.write(column_pid, 1)

      Enum.with_index(state.row_pids) |> Enum.each(fn {gpio, row} ->
        pressed = ElixirALE.GPIO.read(gpio)

        if pressed == 1 do
          Logger.info("column: #{column} | row: #{row} | pressed")
        end
      end)

      ElixirALE.GPIO.write(column_pid, 0)
    end)

    Process.send_after(__MODULE__, :check_keys, 100)

    {:noreply, state}
  end
end
