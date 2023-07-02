defmodule Emxc.Global.Futures.V1 do
  import Emxc.Utilities, only: [unwrap_response: 1, timestamp: 0, sign_get_query: 2]

  @base_url "https://contract.mexc.com"
  @docs_api_key Emxc.Utilities.docs_api_key()
  @docs_secret_key Emxc.Utilities.docs_secret_key()

  @type response :: {:ok, map()} | {:error, any()} | no_return()
  @type client :: Tesla.Client.t()
  @type headers :: Tesla.Env.headers()

  @doc """
  Create a client for the public endpoints.

  ## Options
    * `:base_url` - The base url for the API. Defaults to `https://contract.mexc.com`.
    * `:headers` - A list of headers to be sent with every request.
    * `:adapter` - The adapter to use for the HTTP requests. Defaults to `Tesla.Adapter.Hackney`.

  ## Example
      iex> Emxc.Global.Futures.V1.public_client()
      %Tesla.Client{
              fun: nil,
              pre: [
                {Tesla.Middleware.BaseUrl, :call,
                 ["https://contract.mexc.com"]},
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
    * `:base_url` - The base URL to be used for the client. Defaults to `"https://contract.mexc.com"`.
    * `:headers` - A list of headers to be sent with each request.
    * `:adapter` - The adapter to be used for the client. Defaults to `Tesla.Adapter.Hackney`.
    * `:api_key` - The API key to be used for the client. Defaults to `"api_key"`.

  ## Example
      iex> Emxc.Global.Futures.V1.authorized_client()
      %Tesla.Client{
              fun: nil,
              pre: [
                {Tesla.Middleware.BaseUrl, :call,
                 ["https://contract.mexc.com"]},
                {Tesla.Middleware.JSON, :call, [[]]},
                {Tesla.Middleware.Headers, :call,
                 [
                   [
                     {"ApiKey", "api_key"},
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
  @spec authorized_client([authorized_option()]) :: client()
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
       [{"ApiKey", api_key}, {"Content-Type", "application/json"} | custom_headers]}
    ]

    Tesla.client(middleware, adapter)
  end

  # Market endpoints
  @doc """
  Test connectivity to the Rest API.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.ping()
      iex> response.status
      200

  """
  @spec ping(client()) :: response()
  @doc section: :market_data
  def ping(client), do: client |> Tesla.get("api/v1/contract/ping") |> unwrap_response()

  @doc """
  Get the contract information.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_contract_info()
      iex> response.result["data"] |> then(&(&1 |> length() > 0))
      true
      iex> {:ok, response} = Futures.public_client() |> Futures.get_contract_info(symbol: "BTC_USDT")
      iex> response.result["data"]["quoteCoin"] == "USDT"
      true
  """
  @type get_contract_info_option :: {:symbol, String.t()}
  @spec get_contract_info(client(), [get_contract_info_option()]) :: response()
  @doc section: :market_data
  def get_contract_info(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    query = if symbol, do: "?symbol=#{symbol}", else: ""
    query = query |> URI.encode()
    client |> Tesla.get("api/v1/contract/detail#{query}") |> unwrap_response()
  end

  @doc """
  Get the transferable currencies.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_transferable_currencies()
      iex> response.result["data"] |> then(&(&1 |> length() > 0))
      true
  """
  @spec get_transferable_currencies(client()) :: response()
  @doc section: :market_data
  def get_transferable_currencies(client),
    do: client |> Tesla.get("api/v1/contract/support_currencies") |> unwrap_response()

  @doc """
  Get the contract's depth information.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:limit` - The depth to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_depth(symbol: "BTC_USDT", limit: 10)
      iex> response.result["data"]["asks"] |> then(&(&1 |> length() == 10))
      true
      iex> response.result["data"]["bids"] |> then(&(&1 |> length() == 10))
      true
  """
  @type get_depth_option :: {:symbol, String.t()} | {:limit, integer()}
  @spec get_depth(client(), [get_depth_option()]) :: response()
  @doc section: :market_data
  def get_depth(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    limit = Keyword.get(opts, :limit, nil)
    query = if limit, do: "?limit=#{limit}", else: ""
    query = query |> URI.encode()
    client |> Tesla.get("api/v1/contract/depth/#{symbol}#{query}") |> unwrap_response()
  end

  @doc """
  Get a snapshot of the latest N depth information of the contract.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:limit` - The depth to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_depth_snapshot(symbol: "BTC_USDT", limit: 10)
      iex> response.result["data"] |> then(&(&1 |> length() == 10))
      true
  """
  @type get_depth_snapshot_option :: {:symbol, String.t()} | {:limit, integer()}
  @spec get_depth_snapshot(client(), [get_depth_snapshot_option()]) :: response()
  @doc section: :market_data
  def get_depth_snapshot(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    limit = Keyword.get(opts, :limit, nil)
    query = if limit, do: "#{symbol}/#{limit}", else: "#{symbol}"
    query = query |> URI.encode()
    client |> Tesla.get("api/v1/contract/depth_commits/#{query}") |> unwrap_response()
  end

  @doc """
  Get contract index price.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_index_price(symbol: "BTC_USDT")
      iex> response.result["data"]["indexPrice"] |> then(&(&1 > 0))
      true
  """
  @type get_index_price_option :: {:symbol, String.t()}
  @spec get_index_price(client(), [get_index_price_option()]) :: response()
  @doc section: :market_data
  def get_index_price(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    query = "#{symbol}"
    query = query |> URI.encode()
    client |> Tesla.get("api/v1/contract/index_price/#{query}") |> unwrap_response()
  end

  @doc """
  Get contract fair price.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_fair_price(symbol: "BTC_USDT")
      iex> response.result["data"]["fairPrice"] |> then(&(&1 > 0))
      true
  """
  @type get_fair_price_option :: {:symbol, String.t()}
  @spec get_fair_price(client(), [get_fair_price_option()]) :: response()
  @doc section: :market_data
  def get_fair_price(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    query = "#{symbol}"
    query = query |> URI.encode()
    client |> Tesla.get("api/v1/contract/fair_price/#{query}") |> unwrap_response()
  end

  @doc """
  Get contract funding rate.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_funding_rate(symbol: "BTC_USDT")
      iex> response.result["data"]["fundingRate"] |> then(&(&1 > 0))
      true
  """
  @type get_funding_rate_option :: {:symbol, String.t()}
  @spec get_funding_rate(client(), [get_funding_rate_option()]) :: response()
  @doc section: :market_data
  def get_funding_rate(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    query = "#{symbol}"
    query = query |> URI.encode()
    client |> Tesla.get("api/v1/contract/funding_rate/#{query}") |> unwrap_response()
  end

  @doc """
  Kline data.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:interval` - The interval to get the information for. Required.
    * `:start` - The start time to get the information for. Optional.
    * `:end` - The end time to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_kline(symbol: "BTC_USDT", interval: "Min1")
      iex> response.result["data"]["time"] |> then(&(&1 |> length() > 0))
      true
  """
  @type get_kline_option ::
          {:symbol, String.t()}
          | {:interval, String.t()}
          | {:start, String.t()}
          | {:end, String.t()}
  @spec get_kline(client(), [get_kline_option()]) :: response()
  @doc section: :market_data
  def get_kline(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    interval = Keyword.get(opts, :interval, nil)
    start = Keyword.get(opts, :start, nil)
    end_ = Keyword.get(opts, :end, nil)

    client
    |> Tesla.get("api/v1/contract/kline/#{symbol}",
      query: [interval: interval, start: start, end: end_]
    )
    |> unwrap_response()
  end

  @doc """
  Get kline data of the index price.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:interval` - The interval to get the information for. Required.
    * `:start` - The start time to get the information for. Optional.
    * `:end` - The end time to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_index_kline(symbol: "BTC_USDT", interval: "Min1")
      iex> response.result["data"]["time"] |> then(&(&1 |> length() > 0))
      true
  """
  @type get_index_kline_option ::
          {:symbol, String.t()}
          | {:interval, String.t()}
          | {:start, String.t()}
          | {:end, String.t()}
  @spec get_index_kline(client(), [get_index_kline_option()]) :: response()
  @doc section: :market_data
  def get_index_kline(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    interval = Keyword.get(opts, :interval, nil)
    start = Keyword.get(opts, :start, nil)
    end_ = Keyword.get(opts, :end, nil)

    client
    |> Tesla.get("api/v1/contract/kline/index_price/#{symbol}",
      query: [interval: interval, start: start, end: end_]
    )
    |> unwrap_response()
  end

  @doc """
  Get kline data of the fair price.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:interval` - The interval to get the information for. Required.
    * `:start` - The start time to get the information for. Optional.
    * `:end` - The end time to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_fair_price_kline(symbol: "BTC_USDT", interval: "Min1")
      iex> response.result["data"]["time"] |> then(&(&1 |> length() > 0))
      true
  """
  @type get_fair_price_kline_option ::
          {:symbol, String.t()}
          | {:interval, String.t()}
          | {:start, String.t()}
          | {:end, String.t()}
  @spec get_fair_price_kline(client(), [get_fair_price_kline_option()]) :: response()
  @doc section: :market_data
  def get_fair_price_kline(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    interval = Keyword.get(opts, :interval, nil)
    start = Keyword.get(opts, :start, nil)
    end_ = Keyword.get(opts, :end, nil)

    client
    |> Tesla.get("api/v1/contract/kline/fair_price/#{symbol}",
      query: [interval: interval, start: start, end: end_]
    )
    |> unwrap_response()
  end

  @doc """
  Get contract transaction data.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:limit` - The limit to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_trades(symbol: "BTC_USDT")
      iex> response.result["data"] |> then(&(&1 |> length() > 0))
      true
  """
  @type get_trades_option ::
          {:symbol, String.t()}
          | {:limit, integer()}
  @spec get_trades(client(), [get_trades_option()]) :: response()
  @doc section: :market_data
  def get_trades(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    limit = Keyword.get(opts, :limit, nil)

    client
    |> Tesla.get("api/v1/contract/deals/#{symbol}",
      query: [limit: limit]
    )
    |> unwrap_response()
  end

  @doc """
  Get contract trend data.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_trend(symbol: "BTC_USDT")
      iex> response.result["data"]["symbol"]
      "BTC_USDT"
  """
  @type get_trend_option ::
          {:symbol, String.t()}
  @spec get_trend(client(), [get_trend_option()]) :: response()
  @doc section: :market_data
  def get_trend(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)

    client
    |> Tesla.get("api/v1/contract/ticker",
      query: [symbol: symbol]
    )
    |> unwrap_response()
  end

  @doc """
  Get all contract risk fund balance.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_risk_reserve_amount()
      iex> response.result["data"] |> then(&(&1 |> length() > 0))
      true
  """
  @spec get_risk_reserve_amount(client()) :: response()
  @doc section: :market_data
  def get_risk_reserve_amount(client) do
    client
    |> Tesla.get("api/v1/contract/risk_reverse")
    |> unwrap_response()
  end

  @doc """
  Get contract risk fund balance history.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:page_num` - The page number to get the information for. Optional.
    * `:page_size` - The page size to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_risk_reserve_amount_history(symbol: "BTC_USDT")
      iex> response.result["data"]["currentPage"]
      1
  """
  @type get_risk_reserve_amount_history_option ::
          {:symbol, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_risk_reserve_amount_history(client(), [get_risk_reserve_amount_history_option()]) :: response()
  @doc section: :market_data
  def get_risk_reserve_amount_history(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    page_num = Keyword.get(opts, :page_num, nil)
    page_size = Keyword.get(opts, :page_size, nil)

    client
    |> Tesla.get("api/v1/contract/risk_reverse/history",
      query: [symbol: symbol, page_num: page_num, page_size: page_size]
    )
    |> unwrap_response()
  end

  @doc """
  Get contract funding rate history.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:page_num` - The page number to get the information for. Optional.
    * `:page_size` - The page size to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.public_client() |> Futures.get_funding_rate_history(symbol: "BTC_USDT")
      iex> response.result["data"]["currentPage"]
      1
  """
  @type get_funding_rate_history_option ::
          {:symbol, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_funding_rate_history(client(), [get_funding_rate_history_option()]) :: response()
  @doc section: :market_data
  def get_funding_rate_history(client, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    page_num = Keyword.get(opts, :page_num, nil)
    page_size = Keyword.get(opts, :page_size, nil)

    client
    |> Tesla.get("api/v1/contract/funding_rate/history",
      query: [symbol: symbol, page_num: page_num, page_size: page_size]
    )
    |> unwrap_response()
  end
end
