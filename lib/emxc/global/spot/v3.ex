defmodule Emxc.Global.Spot.V3 do
  import Emxc.Utilities, only: [unwrap_response: 1]

  @base_url "https://api.mexc.com"

  @type response :: {:ok, map()} | {:error, any()} | no_return()
  @type client :: Tesla.Client.t()
  @type headers :: Tesla.Env.headers()

  @doc """
  Create a client for the public endpoints.

  ## Options
    * `:base_url` - The base URL to be used for the client. Defaults to `"https://api.mexc.com"`.
    * `:headers` - A list of headers to be sent with each request.
    * `:adapter` - The adapter to be used for the client. Defaults to `Tesla.Adapter.Hackney`.

  ## Example
      iex> Emxc.Global.Spot.V3.public_client()
      %Tesla.Client{
              fun: nil,
              pre: [
                {Tesla.Middleware.BaseUrl, :call,
                 ["https://api.mexc.com"]},
                {Tesla.Middleware.JSON, :call, [[]]},
                {Tesla.Middleware.Headers, :call,
                 [[{"Content-Type", "application/json"}]]}
              ],
              post: [],
              adapter: {Tesla.Adapter.Hackney, :call, [[]]}
            }
  """
  @type public_option ::
          {:headers, headers()} | {:adapter, Tesla.Client.adapter()} | {:base_url, String.t()}
  @spec public_client([public_option()]) :: client()
  @doc section: :api
  def public_client(opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @base_url)
    custom_headers = Keyword.get(opts, :headers, [])
    adapter = Keyword.get(opts, :adapter, Tesla.Adapter.Hackney)

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Content-Type", "application/json"} | custom_headers]}
    ]

    Tesla.client(middleware, adapter)
  end

  @doc """
  Create a client for the private endpoints.

  ## Options
    * `:base_url` - The base URL to be used for the client. Defaults to `"https://api.mexc.com"`.
    * `:headers` - A list of headers to be sent with each request.
    * `:adapter` - The adapter to be used for the client. Defaults to `Tesla.Adapter.Hackney`.
    * `:api_key` - The API key to be used for the client. Defaults to `"api_key"`.

  ## Example
      iex> Emxc.Global.Spot.V3.authorized_client()
      %Tesla.Client{
              fun: nil,
              pre: [
                {Tesla.Middleware.BaseUrl, :call,
                 ["https://api.mexc.com"]},
                {Tesla.Middleware.JSON, :call, [[]]},
                {Tesla.Middleware.Headers, :call,
                 [
                   [
                     {"X-MEXC-APIKEY", "api_key"},
                     {"Content-Type", "application/json"}
                   ]
                 ]}
              ],
              post: [],
              adapter: {Tesla.Adapter.Hackney, :call, [[]]}
            }
  """
  @type authorized_option ::
          {:headers, headers()}
          | {:api_key, String.t()}
          | {:adapter, Tesla.Client.adapter()}
          | {:base_url, String.t()}
  @spec authorized_client(Tesla.Env.headers()) :: client()
  @doc section: :api
  def authorized_client(opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @base_url)
    custom_headers = Keyword.get(opts, :headers, [])
    api_key = Keyword.get(opts, :api_key, "api_key")
    adapter = Keyword.get(opts, :adapter, Tesla.Adapter.Hackney)

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [{"X-MEXC-APIKEY", api_key}, {"Content-Type", "application/json"} | custom_headers]}
    ]

    Tesla.client(middleware, adapter)
  end

  # Market Data Endpoints

  @doc """
  Test connectivity to the Rest API.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.ping()
      iex> response.status
      200
  """
  @spec ping(client()) :: response()
  @doc section: :market_data
  def ping(client), do: client |> Tesla.get("/api/v3/ping") |> unwrap_response()

  @doc """
  Check server time.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.time()
      iex> response.result["serverTime"] <= :calendar.universal_time()
      true
  """
  @spec time(client()) :: response()
  @doc section: :market_data
  def time(client), do: client |> Tesla.get("/api/v3/time") |> unwrap_response()

  @doc """
  Exchange information.

  ## Options

    * `:symbol` - The symbol to get the exchange information for.
    * `:symbols` - A list of symbols to get the exchange information for.


  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.exchange_info(symbols: "BTCUSDT,SNTUSDT")
      iex> response.result["symbols"] |> Enum.map(& &1["symbol"]) |> Enum.sort()
      ["BTCUSDT", "SNTUSDT"]
  """
  @type exchange_info_option :: {:symbol, String.t()} | {:symbols, list(String.t())}
  @spec exchange_info(client(), [exchange_info_option()]) :: response()
  @doc section: :market_data
  def exchange_info(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/exchangeInfo", query: opts) |> unwrap_response()

  @doc """
  Order book.

  ## Options

    * `:limit` - Default 100; max 1000.
    * `:symbol` - The symbol to get the order book for.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.order_book(symbol: "BTCUSDT", limit: 1)
      iex> response.result["bids"] |> length() |> then(& &1 == response.result["asks"] |> length())
      true
  """
  @type order_book_option :: {:limit, integer()} | {:symbol, String.t()}
  @spec order_book(client(), [order_book_option()]) :: response()
  @doc section: :market_data
  def order_book(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/depth", query: opts) |> unwrap_response()

  @doc """
  Recent trades.

  ## Options

    * `:limit` - Default 500; max 1000.
    * `:symbol` - The symbol to get trades for.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.recent_trades(symbol: "BTCUSDT", limit: 1)
      iex> response.result |> length()
      1
  """
  @type recent_trades_option :: {:limit, integer()} | {:symbol, String.t()}
  @spec recent_trades(client(), [recent_trades_option()]) :: response()
  @doc section: :market_data
  def recent_trades(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/trades", query: opts) |> unwrap_response()

  @doc """
  Compressed/Aggregate trades.

  ## Options

    * `:limit` - Default 500; max 1000.
    * `:symbol` - The symbol to get trades for.
    * `:startTime` - Timestamp in ms to get aggregate trades from INCLUSIVE.
    * `:endTime` - Timestamp in ms to get aggregate trades until INCLUSIVE.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.compressed_trades(symbol: "BTCUSDT", limit: 1)
      iex> response.result |> length()
      1
  """
  @type compressed_trades_option ::
          {:limit, integer()}
          | {:symbol, String.t()}
          | {:startTime, integer()}
          | {:endTime, integer()}
  @spec compressed_trades(client(), [compressed_trades_option()]) :: response()
  @doc section: :market_data
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

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.kline(symbol: "BTCUSDT", interval: "1m", limit: 1)
      iex> response.result |> length()
      1
  """
  @type kline_option ::
          {:limit, integer()}
          | {:symbol, String.t()}
          | {:interval, String.t()}
          | {:startTime, integer()}
          | {:endTime, integer()}
  @spec kline(client(), [kline_option()]) :: response()
  @doc section: :market_data
  def kline(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/klines", query: opts) |> unwrap_response()

  @doc """
  Current average price.

  ## Options

    * `:symbol` - The symbol to get the average price for.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.average_price(symbol: "BTCUSDT")
      iex> response.result["price"] > 0
      ...> && Decimal.gt?(Decimal.new(response.result["price"]), 0)
      true
  """
  @type average_price_option :: {:symbol, String.t()}
  @spec average_price(client(), [average_price_option()]) :: response()
  @doc section: :market_data
  def average_price(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/avgPrice", query: opts) |> unwrap_response()

  @doc """
  24hr ticker price change statistics.

  ## Options

    * `:symbol` - The symbol to get the ticker for.
    * If no symbol is provided, all tickers will be returned in a list.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.ticker_24hr(symbol: "BTCUSDT")
      iex> response.result["symbol"]
      "BTCUSDT"
  """
  @type ticker_24hr_option :: {:symbol, String.t()}
  @spec ticker_24hr(client(), [ticker_24hr_option()]) :: response()
  @doc section: :market_data
  def ticker_24hr(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/ticker/24hr", query: opts) |> unwrap_response()

  @doc """
  Symbol price ticker.

  ## Options

    * `:symbol` - The symbol to get the ticker for.
    * If no symbol is provided, all tickers will be returned in a list.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.ticker_price(symbol: "BTCUSDT")
      iex> response.result["symbol"] == "BTCUSDT" && response.result["price"] > 0
      true
  """
  @type ticker_price_option :: {:symbol, String.t()}
  @spec ticker_price(client(), [ticker_price_option()]) :: response()
  @doc section: :market_data
  def ticker_price(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/ticker/price", query: opts) |> unwrap_response()

  @doc """
  Symbol order book ticker.

  ## Options

    * `:symbol` - The symbol to get the ticker for.
    * If no symbol is provided, all tickers will be returned in a list.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.ticker_book(symbol: "BTCUSDT")
      iex> response.result["symbol"] == "BTCUSDT" && response.result["bidPrice"] > 0
      true
  """
  @type ticker_book_option :: {:symbol, String.t()}
  @spec ticker_book(client(), [ticker_book_option()]) :: response()
  @doc section: :market_data
  def ticker_book(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/ticker/bookTicker", query: opts) |> unwrap_response()
end
