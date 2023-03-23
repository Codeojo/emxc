defmodule Emxc.Global.Spot.V3 do
  import Emxc.Utilities,
    only: [load_json: 2, parse_environment: 1, unwrap_response: 1]

  @env load_json("v3.env.json", __DIR__) |> parse_environment()
  @base_url @env["api_url"]

  @type response :: {:ok, map()} | {:error, any()} | no_return()

  @doc """
  Create a client for the public endpoints.
  """
  @type public_option :: {:headers, Tesla.Env.headers()}
  @spec public([public_option()]) :: Tesla.Client.t()
  def public(opts \\ []) do
    custom_headers = Keyword.get(opts, :headers, [])

    middleware = [
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Content-Type", "application/json"} | custom_headers]}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Create a client for the private endpoints.
  """
  @type authorized_option :: {:headers, Tesla.Env.headers()} | {:api_key, String.t()}
  @spec authorized(Tesla.Env.headers()) :: Tesla.Client.t()
  def authorized(opts \\ []) do
    custom_headers = Keyword.get(opts, :headers, [])
    api_key = Keyword.get(opts, :api_key, "api_key")

    middleware = [
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [{"X-MEXC-APIKEY", api_key}, {"Content-Type", "application/json"} | custom_headers]}
    ]

    Tesla.client(middleware)
  end

  # Market Data Endpoints

  @doc """
  Test connectivity to the Rest API.
  """
  @spec ping(Tesla.Client.t()) :: response()
  def ping(client), do: client |> Tesla.get("/api/v3/ping") |> unwrap_response()

  @doc """
  Check server time.
  """
  @spec time(Tesla.Client.t()) :: response()
  def time(client), do: client |> Tesla.get("/api/v3/time") |> unwrap_response()

  @doc """
  Exchange information.

  ## Options

    * `:symbol` - The symbol to get the exchange information for.
    * `:symbols` - A list of symbols to get the exchange information for.
  """
  @type exchange_info_option :: {:symbol, String.t()} | {:symbols, list(String.t())}
  @spec exchange_info(Tesla.Client.t(), [exchange_info_option()]) :: response()
  def exchange_info(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/exchangeInfo", query: opts) |> unwrap_response()

  @doc """
  Order book.

  ## Options

    * `:limit` - Default 100; max 1000.
    * `:symbol` - The symbol to get the order book for.
  """
  @type order_book_option :: {:limit, integer()} | {:symbol, String.t()}
  @spec order_book(Tesla.Client.t(), [order_book_option()]) :: response()
  def order_book(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/depth", query: opts) |> unwrap_response()

  @doc """
  Recent trades.

  ## Options

    * `:limit` - Default 500; max 1000.
    * `:symbol` - The symbol to get trades for.
  """
  @type recent_trades_option :: {:limit, integer()} | {:symbol, String.t()}
  @spec recent_trades(Tesla.Client.t(), [recent_trades_option()]) :: response()
  def recent_trades(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/trades", query: opts) |> unwrap_response()

  @doc """
  Compressed/Aggregate trades.

  ## Options

    * `:limit` - Default 500; max 1000.
    * `:symbol` - The symbol to get trades for.
    * `:startTime` - Timestamp in ms to get aggregate trades from INCLUSIVE.
    * `:endTime` - Timestamp in ms to get aggregate trades until INCLUSIVE.
  """
  @type compressed_trades_option ::
          {:limit, integer()}
          | {:symbol, String.t()}
          | {:startTime, integer()}
          | {:endTime, integer()}
  @spec compressed_trades(Tesla.Client.t(), [compressed_trades_option()]) :: response()
  def compressed_trades(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/aggTrades", query: opts) |> unwrap_response()

  @doc """
  Kline/candlestick bars.

  ## Options

    * `:limit` - Default 500; max 1000.
    * `:symbol` - The symbol to get klines for.
    * `:interval` - The interval to get klines for. One of: `1m`, `5m`, `15m`, `30m`, `60m`, `4h`, `1d`, `1M`.
    * `:startTime` - The start time to get klines for. In milliseconds.
    * `:endTime` - The end time to get klines for. In milliseconds.
  """
  @type kline_option ::
          {:limit, integer()}
          | {:symbol, String.t()}
          | {:interval, String.t()}
          | {:startTime, integer()}
          | {:endTime, integer()}
  @spec kline(Tesla.Client.t(), [kline_option()]) :: response()
  def kline(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/klines", query: opts) |> unwrap_response()
end
