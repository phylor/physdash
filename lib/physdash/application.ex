defmodule Physdash.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  @target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    spawn fn -> start_demo() end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Physdash.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  # List all child processes to be supervised
  def children("host") do
    [
      # Starts a worker by calling: Physdash.Worker.start_link(arg)
      # {Physdash.Worker, arg},
    ]
  end

  def children(_target) do
    import Supervisor.Spec, warn: false

    config = %{rs: 18, en: 24, d4: 25, d5: 8, d6: 7, d7: 12, rows: 2, cols: 20, font_5x10: false }

    [
      # Starts a worker by calling: Physdash.Worker.start_link(arg)
      # {Physdash.Worker, arg},
      worker(ExLCD, [{ExLCD.HD44780, config}]),
      {Physdash, %{}}
    ]
  end

  def start_demo do
    Process.sleep(1000)
    Logger.info("Writing to display..")
    ExLCD.clear()
    ExLCD.enable(:display)
    ExLCD.write("VERB")
  end
end
