defmodule Emxc.Global.Spot.V3 do
  import Emxc.Utilities, only: [unwrap_response: 1, timestamp: 0, sign_get_query: 2]

  @base_url "https://api.mexc.com"
  @docs_api_key Emxc.Utilities.docs_api_key()
  @docs_secret_key Emxc.Utilities.docs_secret_key()

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

  # ETF

  @doc """
  Get ETF info.

  ## Options

    * `:symbol` - The symbol to get the ticker for.
    * If no symbol is provided, all symbols will be returned in a list.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.public_client() |> Spot.etf_info(symbol: "BTCUSDT")
      iex> response.result["symbol"] == "BTCUSDT" && response.result["price"] > 0
      true
  """
  @type etf_info_option :: {:symbol, String.t()}
  @spec etf_info(client(), [etf_info_option()]) :: response()
  @doc section: :market_data
  def etf_info(client, opts \\ []),
    do: client |> Tesla.get("/api/v3/etf/info", query: opts) |> unwrap_response()

  # Sub-Accounts

  @doc """
  Get sub-account list.

  ## Options

    * `:subAccount` - Sub-account name.
    * `:isFreeze` - Frozen or unfrozen status. (`true` or `false`)
    * `:page` - Page number. Defaults to `1`.
    * `:limit` - Number of items per page. Defaults to `10`. Max `200`.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_list("#{@docs_secret_key}")
      iex> response.status
      401
  """
  @type subaccount_list_option ::
          {:subAccount, String.t()}
          | {:isFreeze, boolean()}
          | {:page, integer()}
          | {:limit, integer()}
          | {:recvWindow, integer()}
  @spec subaccount_list(client(), String.t(), [subaccount_list_option()]) :: response()
  @doc section: :sub_accounts
  def subaccount_list(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get("/api/v3/sub-account/list", query: query)
      |> unwrap_response()
    end)
  end

  @doc """
  Create a sub-account (for master account).

  ## Options

    * `:subAccount` - Sub-account name.
    * `:note` - Sub-account notes.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example

      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_create("#{@docs_secret_key}", subAccount: "test_sub_account", note: "test_note")
      iex> response.status
      401
  """
  @type subaccount_create_option ::
          {:subAccount, String.t()}
          | {:note, String.t()}
          | {:recvWindow, integer()}
  @spec subaccount_create(client(), String.t(), [subaccount_create_option()]) :: response()
  @doc section: :sub_accounts
  def subaccount_create(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/sub-account/virtualSubAccount?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Create a sub-account API key (for master account).

  ## Options

    * `:subAccount` - Sub-account name.
    * `:note` - API-key notes.
    * `:permissions` - API-key permissions, as a comma-separated string. Any combination of: `SPOT_ACCOUNT_READ, SPOT_ACCOUNT_WRITE, SPOT_DEAL_READ, SPOT_DEAL_WRITE, ISOLATED_MARGIN_ACCOUNT_READ, ISOLATED_MARGIN_ACCOUNT_WRITE, ISOLATED_MARGIN_DEAL_READ, ISOLATED_MARGIN_DEAL_WRITE, CONTRACT_ACCOUNT_READ, CONTRACT_ACCOUNT_WRITE, CONTRACT_DEAL_READ, CONTRACT_DEAL_WRITE, SPOT_TRANSFER_READ, SPOT_TRANSFER_WRITE`
    * `:ip` - IP address whitelist as a comma-separated string, up to a maximum of 20.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example

        iex> alias Emxc.Global.Spot.V3, as: Spot
        iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_api_key_create("#{@docs_secret_key}", subAccount: "test_sub_account", note: "test_note", permissions: "SPOT_ACCOUNT_READ, SPOT_ACCOUNT_WRITE, SPOT_DEAL_READ, SPOT_DEAL_WRITE, ISOLATED_MARGIN_ACCOUNT_READ, ISOLATED_MARGIN_ACCOUNT_WRITE, ISOLATED_MARGIN_DEAL_READ, ISOLATED_MARGIN_DEAL_WRITE, CONTRACT_ACCOUNT_READ, CONTRACT_ACCOUNT_WRITE, CONTRACT_DEAL_READ, CONTRACT_DEAL_WRITE, SPOT_TRANSFER_READ, SPOT_TRANSFER_WRITE")
        iex> response.status
        401
  """
  @type subaccount_api_key_create_option ::
          {:subAccount, String.t()}
          | {:note, String.t()}
          | {:permissions, String.t()}
          | {:ip, String.t()}
          | {:recvWindow, integer()}
  @spec subaccount_api_key_create(client(), String.t(), [subaccount_api_key_create_option()]) ::
          response()
  @doc section: :sub_accounts
  def subaccount_api_key_create(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/sub-account/apiKey?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Query sub-account API key (for master account).

  ## Options

    * `:subAccount` - Sub-account name.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_api_key_query("#{@docs_secret_key}", subAccount: "test_sub_account")
      iex> response.status
      401
  """
  @type subaccount_api_key_query_option ::
          {:subAccount, String.t()}
          | {:recvWindow, integer()}
  @spec subaccount_api_key_query(client(), String.t(), [subaccount_api_key_query_option()]) ::
          response()
  @doc section: :sub_accounts
  def subaccount_api_key_query(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get("/api/v3/sub-account/apiKey", query: query)
      |> unwrap_response()
    end)
  end

  @doc """
  Delete sub-account API key (for master account).

  ## Options

    * `:subAccount` - Sub-account name.
    * :`apiKey` - API-key to delete.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_api_key_delete("#{@docs_secret_key}", subAccount: "test_sub_account", apiKey: "#{@docs_api_key}")
      iex> response.status
      401
  """
  @type subaccount_api_key_delete_option ::
          {:subAccount, String.t()}
          | {:apiKey, String.t()}
          | {:recvWindow, integer()}
  @spec subaccount_api_key_delete(client(), String.t(), [subaccount_api_key_delete_option()]) ::
          response()
  @doc section: :sub_accounts
  def subaccount_api_key_delete(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.delete(
        "/api/v3/sub-account/apiKey",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Universal transfer (for master account).

  ## Options

    * `:fromAccount` - Account to transfer from. Will transfer from master account by default if `fromAccount` is not sent.
    * `:toAccount` - Account to transfer to. Will transfer to master account by default if `toAccount` is not sent.
    * `:fromAccountType` - Account type to transfer from. One of: `"SPOT"`, `"FUTURES"`, `"ISOLATED_MARGIN"`.
    * `:toAccountType` - Account type to transfer to. One of: `"SPOT"`, `"FUTURES"`, `"ISOLATED_MARGIN"`.
    * `:symbol` - Asset to transfer. Only supported for `"ISOLATED_MARGIN"` account type.
    * `:asset` - Asset to transfer.
    * `:amount` - Amount to transfer.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_universal_transfer_create("#{@docs_secret_key}", fromAccount: "test_sub_account", toAccount: "test_sub_account", asset: "BTC", amount: 0.1)
      iex> response.status
      401
  """
  @type subaccount_universal_transfer_create_option ::
          {:fromAccount, String.t()}
          | {:toAccount, String.t()}
          | {:fromAccountType, String.t()}
          | {:toAccountType, String.t()}
          | {:symbol, String.t()}
          | {:asset, String.t()}
          | {:amount, float()}
          | {:recvWindow, integer()}
  @spec subaccount_universal_transfer_create(client(), String.t(), [
          subaccount_universal_transfer_create_option()
        ]) :: response()
  @doc section: :sub_accounts
  def subaccount_universal_transfer_create(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/capital/sub-account/universalTransfer?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Query universal transfer history (for master account).

  ## Options

    * `:fromAccount` - Account to transfer from. Will transfer from master account by default if `fromAccount` is not sent.
    * `:toAccount` - Account to transfer to. Will transfer to master account by default if `toAccount` is not sent.
    * `:fromAccountType` - Account type to transfer from. One of: `"SPOT"`, `"FUTURES"`, `"ISOLATED_MARGIN"`.
    * `:toAccountType` - Account type to transfer to. One of: `"SPOT"`, `"FUTURES"`, `"ISOLATED_MARGIN"`.
    * `:startTime` - Start time of transfer.
    * `:endTime` - End time of transfer.
    * `:page` - Current page. Defaults to `1`.
    * `:limit` - Page size. Defaults to `500`, max `500`.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_universal_transfer_history("#{@docs_secret_key}", fromAccount: "test_sub_account", toAccount: "test_sub_account", fromAccountType: "SPOT", toAccountType: "SPOT")
      iex> response.status
      401
  """
  @type subaccount_universal_transfer_history_option ::
          {:fromAccount, String.t()}
          | {:toAccount, String.t()}
          | {:fromAccountType, String.t()}
          | {:toAccountType, String.t()}
          | {:startTime, integer()}
          | {:endTime, integer()}
          | {:page, integer()}
          | {:limit, integer()}
          | {:recvWindow, integer()}
  @spec subaccount_universal_transfer_history(client(), String.t(), [
          subaccount_universal_transfer_history_option()
        ]) :: response()
  @doc section: :sub_accounts
  def subaccount_universal_transfer_history(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/capital/sub-account/universalTransfer",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Enable futures for sub-account (for master account).

  ## Options

    * `:subAccount` - Sub-account to enable futures for.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_futures_enable("#{@docs_secret_key}", subAccount: "test_sub_account")
      iex> response.status
      401
  """
  @type subaccount_futures_enable_option ::
          {:subAccount, String.t()}
          | {:recvWindow, integer()}
  @spec subaccount_futures_enable(client(), String.t(), [subaccount_futures_enable_option()]) ::
          response()
  @doc section: :sub_accounts
  def subaccount_futures_enable(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/sub-account/futures?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Enable margin for sub-account (for master account).

  ## Options

    * `:subAccount` - Sub-account to enable margin for.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.subaccount_margin_enable("#{@docs_secret_key}", subAccount: "test_sub_account")
      iex> response.status
      401
  """
  @type subaccount_margin_enable_option ::
          {:subAccount, String.t()}
          | {:recvWindow, integer()}
  @spec subaccount_margin_enable(client(), String.t(), [subaccount_margin_enable_option()]) ::
          response()
  @doc section: :sub_accounts
  def subaccount_margin_enable(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/sub-account/margin?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  # Spot Account/Trade Endpoints
  @doc """
  User API default symbols.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.default_symbols("#{@docs_secret_key}")
      iex> response.status
      401
  """
  @spec default_symbols(client(), String.t()) :: response()
  @doc section: :spot_account_trade
  def default_symbols(client, secret_key) do
    []
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/selfSymbols",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Test new order.

  ## Options

    * `:symbol` - Symbol to trade.
    * `:side` - Trade side. `"BUY"` or `"SELL"`.
    * `:type` - Order type. On of `"LIMIT"`, `"MARKET"`, `"LIMIT_MAKER"`, `"IMMEDIATE_OR_CANCEL"`, `"FILL_OR_KILL"`.
    * `:quantity` - Order quantity.
    * `:quoteOrderQty` - Quote order quantity.
    * `:price` - Order price.
    * `:newClientOrderId` - A unique id for the order.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.


  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.test_new_order("#{@docs_secret_key}", symbol: "BTCUSDT", side: "BUY", type: "LIMIT", quantity: 1, price: 100)
      iex> response.status
      401
  """
  @type test_new_order_option ::
          {:symbol, String.t()}
          | {:side, String.t()}
          | {:type, String.t()}
          | {:quantity, float()}
          | {:quoteOrderQty, float()}
          | {:price, float()}
          | {:newClientOrderId, String.t()}
          | {:recvWindow, integer()}
  @spec test_new_order(client(), String.t(), [test_new_order_option()]) :: response()
  @doc section: :spot_account_trade
  def test_new_order(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/order/test",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  New order.

  ## Options

    * `:symbol` - Symbol to trade.
    * `:side` - Trade side. `"BUY"` or `"SELL"`.
    * `:type` - Order type. On of `"LIMIT"`, `"MARKET"`, `"LIMIT_MAKER"`, `"IMMEDIATE_OR_CANCEL"`, `"FILL_OR_KILL"`.
    * `:quantity` - Order quantity.
    * `:quoteOrderQty` - Quote order quantity.
    * `:price` - Order price.
    * `:newClientOrderId` - A unique id for the order.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.


  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.new_order("#{@docs_secret_key}", symbol: "BTCUSDT", side: "BUY", type: "LIMIT", quantity: 1, price: 100)
      iex> response.status
      401
  """
  @type new_order_option ::
          {:symbol, String.t()}
          | {:side, String.t()}
          | {:type, String.t()}
          | {:quantity, float()}
          | {:quoteOrderQty, float()}
          | {:price, float()}
          | {:newClientOrderId, String.t()}
          | {:recvWindow, integer()}
  @spec new_order(client(), String.t(), [new_order_option()]) :: response()
  @doc section: :spot_account_trade
  def new_order(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/order",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Batch orders.

  ## Options

    * `:batchOrders` - Batch orders. A list of order structs.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Order struct

    * `:symbol` - Symbol to trade.
    * `:side` - Trade side. `"BUY"` or `"SELL"`.
    * `:type` - Order type. On of `"LIMIT"`, `"MARKET"`, `"LIMIT_MAKER"`, `"IMMEDIATE_OR_CANCEL"`, `"FILL_OR_KILL"`.
    * `:quantity` - Order quantity.
    * `:quoteOrderQty` - Quote order quantity.
    * `:price` - Order price.
    * `:newClientOrderId` - A unique id for the order.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.batch_orders("#{@docs_secret_key}", batchOrders: [%{symbol: "BTCUSDT", side: "BUY", type: "LIMIT", quantity: 1, price: 100}])
      iex> response.status
      401
  """
  @type batch_orders_option ::
          {:batchOrders, list()}
          | {:recvWindow, integer()}
  @spec batch_orders(client(), String.t(), [batch_orders_option()]) :: response()
  @doc section: :spot_account_trade
  def batch_orders(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      {batch_orders, query} = Keyword.pop(query, :batchOrders, [])

      query =
        Keyword.put(
          query,
          :batchOrders,
          batch_orders |> Jason.encode!() |> Jason.Formatter.minimize()
        )

      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/batchOrders?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Cancel order.

  ## Options

    * `:symbol` - Symbol to trade.
    * `:orderId` - Order id.
    * `:origClientOrderId` - Original client order id.
    * `:newClientOrderId` - A unique id for the order.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.cancel_order("#{@docs_secret_key}", symbol: "BTCUSDT", orderId: 1)
      iex> response.status
      401
  """
  @type cancel_order_option ::
          {:symbol, String.t()}
          | {:orderId, integer()}
          | {:origClientOrderId, String.t()}
          | {:newClientOrderId, String.t()}
          | {:recvWindow, integer()}
  @spec cancel_order(client(), String.t(), [cancel_order_option()]) :: response()
  @doc section: :spot_account_trade
  def cancel_order(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.delete(
        "/api/v3/order",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Cancel all open orders on a symbol.

  ## Options

    * `:symbol` - Symbols to cancel, comma-separated list in a string. Maximum `5` symbols per request.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.cancel_all_open_orders("#{@docs_secret_key}", symbol: "BTCUSDT")
      iex> response.status
      401
  """
  @type cancel_all_open_orders_option ::
          {:symbol, String.t()}
          | {:recvWindow, integer()}
  @spec cancel_all_open_orders(client(), String.t(), [cancel_all_open_orders_option()]) ::
          response()
  @doc section: :spot_account_trade
  def cancel_all_open_orders(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.delete(
        "/api/v3/openOrders",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Query order.

  ## Options

    * `:symbol` - Symbol to trade.
    * `:origClientOrderId` - Original client order id.
    * `:orderId` - Order id.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.query_order("#{@docs_secret_key}", symbol: "BTCUSDT", orderId: 1)
      iex> response.status
      401
  """
  @type query_order_option ::
          {:symbol, String.t()}
          | {:origClientOrderId, String.t()}
          | {:orderId, integer()}
          | {:recvWindow, integer()}
  @spec query_order(client(), String.t(), [query_order_option()]) :: response()
  @doc section: :spot_account_trade
  def query_order(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/order",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Get all open orders on a symbol. ***Careful*** when accessing this with no symbol.

  ## Options

    * `:symbol` - Symbol to trade. If not sent, orders for all symbols will be returned in an array.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.open_orders("#{@docs_secret_key}", symbol: "BTCUSDT")
      iex> response.status
      401
  """
  @type open_orders_option ::
          {:symbol, String.t()}
          | {:recvWindow, integer()}
  @spec open_orders(client(), String.t(), [open_orders_option()]) :: response()
  @doc section: :spot_account_trade
  def open_orders(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/openOrders",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Query all account orders.

  ## Options

    * `:symbol` - Symbol to trade.
    * `:startTime` - Start time.
    * `:endTime` - End time.
    * `:limit` - Limit.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.all_orders("#{@docs_secret_key}", symbol: "BTCUSDT")
      iex> response.status
      401
  """
  @type all_orders_option ::
          {:symbol, String.t()}
          | {:startTime, integer()}
          | {:endTime, integer()}
          | {:limit, integer()}
          | {:recvWindow, integer()}
  @spec all_orders(client(), String.t(), [all_orders_option()]) :: response()
  @doc section: :spot_account_trade
  def all_orders(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/allOrders",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Account information.

  ## Options

    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.account("#{@docs_secret_key}")
      iex> response.status
      401
  """
  @type account_option ::
          {:recvWindow, integer()}
  @spec account(client(), String.t(), [account_option()]) :: response()
  @doc section: :spot_account_trade
  def account(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/account",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Account trade list.

  ## Options

    * `:symbol` - Symbol to trade.
    * `:orderId` - Order id.
    * `:startTime` - Start time.
    * `:endTime` - End time.
    * `:limit` - Limit. Default `500`; max `1000`.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.account_trades("#{@docs_secret_key}", symbol: "BTCUSDT")
      iex> response.status
      401
  """
  @type account_trades_option ::
          {:symbol, String.t()}
          | {:orderId, integer()}
          | {:startTime, integer()}
          | {:endTime, integer()}
          | {:limit, integer()}
          | {:recvWindow, integer()}
  @spec account_trades(client(), String.t(), [account_trades_option()]) :: response()
  @doc section: :spot_account_trade
  def account_trades(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/myTrades",
        query: query
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Enable MX Deduct.

  ## Options

    * `:mxDeductEnable` - `true` or `false`.
    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.enable_mx_deduct("#{@docs_secret_key}", mxDeductEnable: true)
      iex> response.status
      401
  """
  @type enable_mx_deduct_option ::
          {:mxDeductEnable, boolean()}
          | {:recvWindow, integer()}
  @spec enable_mx_deduct(client(), String.t(), [enable_mx_deduct_option()]) :: response()
  @doc section: :spot_account_trade
  def enable_mx_deduct(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.post(
        "/api/v3/mxDeduct/enable?#{URI.encode_query(query)}",
        query |> Enum.into(%{})
      )
      |> unwrap_response()
    end)
  end

  @doc """
  Query MX Deduct status.

  ## Options

    * `:recvWindow` -  the number of milliseconds after timestamp the request is valid for. Defaults to `5000`.

  ## Example
      iex> alias Emxc.Global.Spot.V3, as: Spot
      iex> {:ok, response} = Spot.authorized_client(api_key: "#{@docs_api_key}") |> Spot.mx_deduct_status("#{@docs_secret_key}")
      iex> response.status
      401
  """
  @type mx_deduct_status_option ::
          {:recvWindow, integer()}
  @spec mx_deduct_status(client(), String.t(), [mx_deduct_status_option()]) :: response()
  @doc section: :spot_account_trade
  def mx_deduct_status(client, secret_key, opts \\ []) do
    opts
    |> Keyword.put(:timestamp, timestamp())
    |> then(fn query ->
      signature =
        query
        |> sign_get_query(secret_key)

      query
      |> Keyword.put(:signature, signature)
    end)
    |> then(fn query ->
      client
      |> Tesla.get(
        "/api/v3/mxDeduct/enable",
        query: query
      )
      |> unwrap_response()
    end)
  end
end
