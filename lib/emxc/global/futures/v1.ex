defmodule Emxc.Global.Futures.V1 do
  import Emxc.Utilities, only: [unwrap_response: 1]
  require Logger

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
                {Tesla.Middleware.KeepRequest, :call, [[]]},
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
      Tesla.Middleware.KeepRequest,
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
                {Tesla.Middleware.KeepRequest, :call, [[]]},
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
      Tesla.Middleware.KeepRequest,
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
  @spec get_risk_reserve_amount_history(client(), [get_risk_reserve_amount_history_option()]) ::
          response()
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

  # Account and trading endpoints

  @doc """
  Get all information of user's asset.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_account("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @spec get_account(client(), String.t()) :: response()
  @doc section: :account_and_trading
  def get_account(client, secret_key) do
    client
    |> Tesla.get("api/v1/private/account/assets",
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Get the user's single currency asset information.

  ## Options
    * `:currency` - The currency to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_currency_account("#{@docs_secret_key}", currency: "USDT")
      iex> response.result["code"]
      1005
  """
  @type get_currency_account_option ::
          {:currency, String.t()}
  @spec get_currency_account(client(), String.t(), [get_currency_account_option()]) :: response()
  @doc section: :account_and_trading
  def get_currency_account(client, secret_key, opts \\ []) do
    currency = Keyword.get(opts, :currency, nil)

    client
    |> Tesla.get("api/v1/private/account/asset/#{currency}",
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Get the user's asset transfer records.

  ## Options
    * `:currency` - The currency to get the information for. Optional.
    * `:state` - The state to get the information for. Optional.
    * `:type` - The type to get the information for. Optional.
    * `:page_num` - The page number to get the information for. Optional.
    * `:page_size` - The page size to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_asset_transfer_records("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_asset_transfer_records_option ::
          {:currency, String.t()}
          | {:state, String.t()}
          | {:type, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_asset_transfer_records(client(), String.t(), [get_asset_transfer_records_option()]) ::
          response()
  @doc section: :account_and_trading
  def get_asset_transfer_records(client, secret_key, opts \\ []) do
    currency = Keyword.get(opts, :currency, nil)
    state = Keyword.get(opts, :state, nil)
    type = Keyword.get(opts, :type, nil)
    page_num = Keyword.get(opts, :page_num, 1)
    page_size = Keyword.get(opts, :page_size, 100)

    query = [
      currency: currency,
      state: state,
      type: type,
      page_num: page_num,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/account/transfer_record",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get the user's history position information.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.
    * `:type` - The type to get the information for. Optional.
    * `:page_num` - The page number to get the information for. Optional.
    * `:page_size` - The page size to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_position_history("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_position_history_option ::
          {:symbol, String.t()}
          | {:type, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_position_history(client(), String.t(), [get_position_history_option()]) :: response()
  @doc section: :account_and_trading
  def get_position_history(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    type = Keyword.get(opts, :type, nil)
    page_num = Keyword.get(opts, :page_num, 1)
    page_size = Keyword.get(opts, :page_size, 100)

    query = [
      symbol: symbol,
      type: type,
      page_num: page_num,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/position/list/history_positions",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get the user's current holding position.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_position("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_position_option ::
          {:symbol, String.t()}
  @spec get_position(client(), String.t(), [get_position_option()]) :: response()
  @doc section: :account_and_trading
  def get_position(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)

    query = [
      symbol: symbol
    ]

    client
    |> Tesla.get("api/v1/private/position/open_positions",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get details of user's funding rate.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.
    * `:position_id` - The position id to get the information for. Optional.
    * `:page_num` - The page number to get the information for. Optional.
    * `:page_size` - The page size to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_user_funding_rate("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_user_funding_rate_option ::
          {:symbol, String.t()}
          | {:position_id, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_user_funding_rate(client(), String.t(), [get_user_funding_rate_option()]) ::
          response()
  @doc section: :account_and_trading
  def get_user_funding_rate(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    position_id = Keyword.get(opts, :position_id, nil)
    page_num = Keyword.get(opts, :page_num, 1)
    page_size = Keyword.get(opts, :page_size, 100)

    query = [
      symbol: symbol,
      position_id: position_id,
      page_num: page_num,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/position/funding_records",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get the user's current pending order.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.
    * `:page_num` - The page number to get the information for. Required.
    * `:page_size` - The page size to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_pending_order("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_pending_order_option ::
          {:symbol, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_pending_order(client(), String.t(), [get_pending_order_option()]) :: response()
  @doc section: :account_and_trading
  def get_pending_order(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    page_num = Keyword.get(opts, :page_num, nil)
    page_size = Keyword.get(opts, :page_size, nil)

    query = [
      page_num: page_num,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/order/list/open_orders/#{symbol}",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get all of the user's historical orders.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.
    * `:states` - The states to get the information for. Optional.
    * `:category` - The category to get the information for. Optional.
    * `:start_time` - The start time to get the information for. Optional.
    * `:end_time` - The end time to get the information for. Optional.
    * `:side` - The side to get the information for. Optional.
    * `:page_num` - The page number to get the information for. Required.
    * `:page_size` - The page size to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_historical_orders("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_historical_orders_option ::
          {:symbol, String.t()}
          | {:states, String.t()}
          | {:category, String.t()}
          | {:start_time, String.t()}
          | {:end_time, String.t()}
          | {:side, String.t()}
          | {:page_num, integer()}
          | {:page_size, integer()}
  @spec get_historical_orders(client(), String.t(), [get_historical_orders_option()]) ::
          response()
  @doc section: :account_and_trading
  def get_historical_orders(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)
    states = Keyword.get(opts, :states, nil)
    category = Keyword.get(opts, :category, nil)
    start_time = Keyword.get(opts, :start_time, nil)
    end_time = Keyword.get(opts, :end_time, nil)
    side = Keyword.get(opts, :side, nil)
    page_num = Keyword.get(opts, :page_num, 1)
    page_size = Keyword.get(opts, :page_size, 100)

    query = [
      symbol: symbol,
      states: states,
      category: category,
      start_time: start_time,
      end_time: end_time,
      side: side,
      page_num: page_num,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/order/list/history_orders",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Query the order based on the external number.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:external_oid` - The order id to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_external_order("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_external_order_option ::
          {:symbol, String.t()}
          | {:external_oid, String.t()}
  @spec query_external_order(client(), String.t(), [query_external_order_option()]) ::
          response()
  @doc section: :account_and_trading
  def query_external_order(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTC_USDT")
    external_oid = Keyword.get(opts, :external_oid, "1234567890")

    client
    |> Tesla.get("api/v1/private/order/external/#{symbol}/#{external_oid}",
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Query the order based on the order number.

  ## Options
    * `:order_id` - The order id to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_order("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_order_option ::
          {:order_id, String.t()}
  @spec query_order(client(), String.t(), [query_order_option()]) ::
          response()
  @doc section: :account_and_trading
  def query_order(client, secret_key, opts \\ []) do
    order_id = Keyword.get(opts, :order_id, "1234567890")

    client
    |> Tesla.get("api/v1/private/order/get/#{order_id}",
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Query the order in bulk based on the order numbers.

  ## Options
    * `:order_ids` - The order ids to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_orders("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_orders_option ::
          {:order_ids, String.t()}
  @spec query_orders(client(), String.t(), [query_orders_option()]) :: response()
  @doc section: :account_and_trading
  def query_orders(client, secret_key, opts \\ []) do
    order_ids = Keyword.get(opts, :order_ids, "1,2,3")
    query = [order_ids: order_ids]

    client
    |> Tesla.get("api/v1/private/order/batch_query",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get order transaction details based on the order ID.

  ## Options
    * `:order_id` - The order id to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_order_trades("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_order_trades_option ::
          {:order_id, String.t()}
  @spec query_order_trades(client(), String.t(), [query_order_trades_option()]) ::
          response()
  @doc section: :account_and_trading
  def query_order_trades(client, secret_key, opts \\ []) do
    order_id = Keyword.get(opts, :order_id, "1234567890")

    client
    |> Tesla.get("api/v1/private/order/deal_details/#{order_id}",
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Get all transaction details of the user's order.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.
    * `:start_time` - The start time to get the information for. Optional.
    * `:end_time` - The end time to get the information for. Optional.
    * `:page_index` - The page index to get the information for. Required.
    * `:page_size` - The page size to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_all_order_trades("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_all_order_trades_option ::
          {:symbol, String.t()}
          | {:start_time, String.t()}
          | {:end_time, String.t()}
          | {:page_index, String.t()}
          | {:page_size, String.t()}
  @spec query_all_order_trades(client(), String.t(), [query_all_order_trades_option()]) ::
          response()
  @doc section: :account_and_trading
  def query_all_order_trades(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    start_time = Keyword.get(opts, :start_time, "1234567890")
    end_time = Keyword.get(opts, :end_time, "1234567890")
    page_index = Keyword.get(opts, :page_index, "1")
    page_size = Keyword.get(opts, :page_size, "10")

    query = [
      symbol: symbol,
      start_time: start_time,
      end_time: end_time,
      page_index: page_index,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/order/list/order_deals",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Gets the trigger order list.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.
    * `:states` - The states to get the information for. Optional.
    * `:start_time` - The start time to get the information for. Optional.
    * `:end_time` - The end time to get the information for. Optional.
    * `:page_index` - The page index to get the information for. Required.
    * `:page_size` - The page size to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_trigger_order_list("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_trigger_order_list_option ::
          {:symbol, String.t()}
          | {:states, String.t()}
          | {:start_time, String.t()}
          | {:end_time, String.t()}
          | {:page_index, String.t()}
          | {:page_size, String.t()}
  @spec query_trigger_order_list(client(), String.t(), [query_trigger_order_list_option()]) ::
          response()
  @doc section: :account_and_trading
  def query_trigger_order_list(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    states = Keyword.get(opts, :states, "1")
    start_time = Keyword.get(opts, :start_time, "1234567890")
    end_time = Keyword.get(opts, :end_time, "1234567890")
    page_index = Keyword.get(opts, :page_index, "1")
    page_size = Keyword.get(opts, :page_size, "10")

    query = [
      symbol: symbol,
      states: states,
      start_time: start_time,
      end_time: end_time,
      page_index: page_index,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/planorder/list/orders",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get the stop-limit order list.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.
    * `:is_finished` - The is_finished to get the information for. Optional.
    * `:start_time` - The start time to get the information for. Optional.
    * `:end_time` - The end time to get the information for. Optional.
    * `:page_index` - The page index to get the information for. Required.
    * `:page_size` - The page size to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_stop_limit_order_list("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_stop_limit_order_list_option ::
          {:symbol, String.t()}
          | {:is_finished, String.t()}
          | {:start_time, String.t()}
          | {:end_time, String.t()}
          | {:page_index, String.t()}
          | {:page_size, String.t()}
  @spec query_stop_limit_order_list(client(), String.t(), [query_stop_limit_order_list_option()]) ::
          response()
  @doc section: :account_and_trading
  def query_stop_limit_order_list(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    is_finished = Keyword.get(opts, :is_finished, "1")
    start_time = Keyword.get(opts, :start_time, "1234567890")
    end_time = Keyword.get(opts, :end_time, "1234567890")
    page_index = Keyword.get(opts, :page_index, "1")
    page_size = Keyword.get(opts, :page_size, "10")

    query = [
      symbol: symbol,
      is_finished: is_finished,
      start_time: start_time,
      end_time: end_time,
      page_index: page_index,
      page_size: page_size
    ]

    client
    |> Tesla.get("api/v1/private/stoporder/list/orders",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get risk limits.

  ## Options
    * `:symbol` - The symbol to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_risk_limit("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_risk_limit_option ::
          {:symbol, String.t()}
  @spec query_risk_limit(client(), String.t(), [query_risk_limit_option()]) :: response()
  @doc section: :account_and_trading
  def query_risk_limit(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, nil)

    query = [
      symbol: symbol
    ]

    client
    |> Tesla.get("api/v1/private/account/risk_limit",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get's the user's current trading fee rate.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.query_fee_rate("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type query_fee_rate_option ::
          {:symbol, String.t()}
  @spec query_fee_rate(client(), String.t(), [query_fee_rate_option()]) :: response()
  @doc section: :account_and_trading
  def query_fee_rate(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")

    query = [
      symbol: symbol
    ]

    client
    |> Tesla.get("api/v1/private/account/tiered_fee_rate",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Increase or decrease margin.

  ## Options
    * `:positionId` - The positionId to get the information for. Required.
    * `:amount` - The amount to get the information for. Required.
    * `:type` - The type to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.change_margin("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type change_margin_option ::
          {:positionId, String.t()}
          | {:amount, String.t()}
          | {:type, String.t()}
  @spec change_margin(client(), String.t(), [change_margin_option()]) :: response()
  @doc section: :account_and_trading
  def change_margin(client, secret_key, opts \\ []) do
    positionId = Keyword.get(opts, :positionId, "1234567890")
    amount = Keyword.get(opts, :amount, "1")
    type = Keyword.get(opts, :type, "1")

    query = [
      positionId: positionId,
      amount: amount,
      type: type
    ]

    client
    |> Tesla.post(
      "api/v1/private/position/change_margin",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get leverage.

  ## Options
    * `:symbol` - The symbol to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_leverage("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type get_leverage_option ::
          {:symbol, String.t()}
  @spec get_leverage(client(), String.t(), [get_leverage_option()]) :: response()
  @doc section: :account_and_trading
  def get_leverage(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")

    query = [
      symbol: symbol
    ]

    client
    |> Tesla.get("api/v1/private/position/leverage",
      query: query,
      headers: get_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Switch leverage.

  ## Options
    * `:positionId` - The symbol to get the information for. Required.
    * `:leverage` - The leverage to get the information for. Required.
    * `:openType` - The openType to get the information for. Optional.
    * `:symbol` - The symbol to get the information for. Optional.
    * `:positionType` - The positionType to get the information for. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.switch_leverage("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @type switch_leverage_option ::
          {:positionId, String.t()}
          | {:leverage, String.t()}
          | {:openType, String.t()}
          | {:symbol, String.t()}
          | {:positionType, String.t()}
  @spec switch_leverage(client(), String.t(), [switch_leverage_option()]) :: response()
  @doc section: :account_and_trading
  def switch_leverage(client, secret_key, opts \\ []) do
    positionId = Keyword.get(opts, :positionId, "1234567890")
    leverage = Keyword.get(opts, :leverage, "1")
    openType = Keyword.get(opts, :openType, "1")
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    positionType = Keyword.get(opts, :positionType, "1")

    query = [
      positionId: positionId,
      leverage: leverage,
      openType: openType,
      symbol: symbol,
      positionType: positionType
    ]

    client
    |> Tesla.post(
      "api/v1/private/position/change_leverage",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Get position mode.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.get_position_mode("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @spec get_position_mode(client(), String.t()) :: response()
  @doc section: :account_and_trading
  def get_position_mode(client, secret_key) do
    client
    |> Tesla.get("api/v1/private/position/position_mode",
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Change position mode.

  ## Options
    * `:positionMode` - The position mode to get the information for. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.change_position_mode("#{@docs_secret_key}", positionMode: 1)
      iex> response.result["code"]
  """
  @type change_position_mode_option ::
          {:positionMode, integer()}
  @spec change_position_mode(client(), String.t(), [change_position_mode_option()]) :: response()
  @doc section: :account_and_trading
  def change_position_mode(client, secret_key, opts \\ []) do
    positionMode = Keyword.get(opts, :positionMode, 1)

    query = [
      positionMode: positionMode
    ]

    client
    |> Tesla.post(
      "api/v1/private/position/change_position_mode",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Create an order.

  ## Options
    * `:symbol` - The symbol to buy or sell. Required.
    * `:price` - The price to buy or sell at. Required.
    * `:vol` - The volume to buy or sell. Required.
    * `:leverage` - The leverage to buy or sell. Optional.
    * `:side` - The side of the order. Required.
    * `:type` - The type of the order. Required.
    * `:openType` - The open type of the order. Required.
    * `:positionId` - The position id of the order. Optional.
    * `:externalOid` - The external order ID of the order. Optional.
    * `:stopLossPrice` - The stop loss price of the order. Optional.
    * `:takeProfitPrice` - The take profit price of the order. Optional.
    * `:positionType` - The position type of the order. Optional.
    * `:reduceOnly` - The reduce only of the order. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.create_order("#{@docs_secret_key}", symbol: "BTCUSDT", price: "10000", vol: "1", side: "1", type: "1", openType: "1")
      iex> response.result["code"]
      1005
  """
  @type create_order_option ::
          {:symbol, String.t()}
          | {:price, String.t()}
          | {:vol, String.t()}
          | {:leverage, String.t()}
          | {:side, String.t()}
          | {:type, String.t()}
          | {:openType, String.t()}
          | {:positionId, String.t()}
          | {:externalOid, String.t()}
          | {:stopLossPrice, String.t()}
          | {:takeProfitPrice, String.t()}
          | {:positionType, String.t()}
          | {:reduceOnly, String.t()}
  @spec create_order(client(), String.t(), [create_order_option()]) :: response()
  @doc section: :account_and_trading
  def create_order(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    price = Keyword.get(opts, :price, "10000")
    vol = Keyword.get(opts, :vol, "1")
    leverage = Keyword.get(opts, :leverage, "1")
    side = Keyword.get(opts, :side, "1")
    type = Keyword.get(opts, :type, "1")
    openType = Keyword.get(opts, :openType, "1")
    positionId = Keyword.get(opts, :positionId, "1234567890")
    externalOid = Keyword.get(opts, :externalOid, "1234567890")
    stopLossPrice = Keyword.get(opts, :stopLossPrice, "10000")
    takeProfitPrice = Keyword.get(opts, :takeProfitPrice, "10000")
    positionType = Keyword.get(opts, :positionType, "1")
    reduceOnly = Keyword.get(opts, :reduceOnly, "1")

    query =
      [
        symbol: symbol,
        price: price,
        vol: vol,
        leverage: leverage,
        side: side,
        type: type,
        openType: openType,
        positionId: positionId,
        externalOid: externalOid,
        stopLossPrice: stopLossPrice,
        takeProfitPrice: takeProfitPrice,
        positionType: positionType,
        reduceOnly: reduceOnly
      ]
      |> Stream.filter(fn {_, v} -> v != nil end)
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> {k, to_string(v)} end)

    client
    |> Tesla.post(
      "api/v1/private/order/submit",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Create bulk orders.

  ## Options
    * `:orders` - The orders to create. Required. See `create_order/3` for the options.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.create_orders("#{@docs_secret_key}", orders: [[symbol: "BTCUSDT", price: "10000", vol: "1", side: "1", type: "1", openType: "1"]])
      iex> response.result["code"]
      1005
  """
  @type create_orders_option :: {:orders, [create_order_option()]}
  @spec create_orders(client(), String.t(), [create_orders_option()]) :: response()
  @doc section: :account_and_trading
  def create_orders(client, secret_key, opts \\ []) do
    orders = Keyword.get(opts, :orders, [])

    payload = orders |> Enum.map(&Enum.into(&1, %{}))

    client
    |> Tesla.post(
      "api/v1/private/order/submit_batch",
      payload,
      headers: post_request_signature(client, secret_key, payload, false)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel the order.

  ## Options
    * `:orders` - The list of orders ID's to cancel.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_order("#{@docs_secret_key}", orders: "1234567890")
      iex> response.result["code"]
      1005
  """
  @type cancel_order_option :: {:orders, String.t()}
  @spec cancel_order(client(), String.t(), [cancel_order_option()]) :: response()
  @doc section: :account_and_trading
  def cancel_order(client, secret_key, opts \\ []) do
    orders = Keyword.get(opts, :orders, "1234567890")

    query = [orders: orders]

    client
    |> Tesla.post(
      "api/v1/private/order/cancel",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel the order according to the external order ID.

  ## Options
    * `:symbol` - The symbol of the order to cancel. Required.
    * `:externalOid` - The external order ID to cancel. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_order_by_external_oid("#{@docs_secret_key}", symbol: "BTCUSDT", externalOid: "1234567890")
      iex> response.result["code"]
      1005
  """
  @type cancel_order_by_external_oid_option :: {:symbol, String.t()} | {:externalOid, String.t()}
  @spec cancel_order_by_external_oid(client(), String.t(), [cancel_order_by_external_oid_option()]) ::
          response()
  @doc section: :account_and_trading
  def cancel_order_by_external_oid(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    externalOid = Keyword.get(opts, :externalOid, "1234567890")

    query = [symbol: symbol, externalOid: externalOid]

    client
    |> Tesla.post(
      "api/v1/private/order/cancel_with_external",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel all orders under a contract.

  ## Options
    * `:symbol` - The symbol of the order to cancel. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_all_orders("#{@docs_secret_key}", symbol: "BTCUSDT")
      iex> response.result["code"]
      1005
  """
  @type cancel_all_orders_option :: {:symbol, String.t()}
  @spec cancel_all_orders(client(), String.t(), [cancel_all_orders_option()]) :: response()
  @doc section: :account_and_trading
  def cancel_all_orders(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")

    query = [symbol: symbol]

    client
    |> Tesla.post(
      "api/v1/private/order/cancel_all",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Switch the risk level (deprecated).

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.switch_risk_level("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @spec switch_risk_level(client(), String.t()) :: response()
  @doc section: :account_and_trading
  def switch_risk_level(client, secret_key) do
    client
    |> Tesla.post(
      "api/v1/private/account/change_risk_level",
      %{},
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Create a trigger order.

  ## Options
    * `:symbol` - The symbol of the order to create. Required.
    * `:price` - The price of the order to create. Optional.
    * `:vol` - The volume of the order to create. Required.
    * `:leverage` - The leverage of the order to create. Optional.
    * `:side` - The side of the order to create. Required.
    * `:openType` - The open type of the order to create. Required.
    * `:triggerPrice` - The trigger price of the order to create. Required.
    * `:triggerType` - The trigger type of the order to create. Required.
    * `:executeCycle` - The execute cycle of the order to create. Required.
    * `:orderType` - The order type of the order to create. Required.
    * `:trend` - The trend of the order to create. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.create_trigger_order("#{@docs_secret_key}", symbol: "BTCUSDT", price: 10000, vol: 1, leverage: 10, side: "BUY", openType: "LIMIT", triggerPrice: 10000, triggerType: "LAST", executeCycle: "GTC", orderType: "LIMIT", trend: "UP")
      iex> response.result["code"]
      1005
  """
  @type create_trigger_order_option ::
          {:symbol, String.t()}
          | {:price, number()}
          | {:vol, number()}
          | {:leverage, number()}
          | {:side, String.t()}
          | {:openType, String.t()}
          | {:triggerPrice, number()}
          | {:triggerType, String.t()}
          | {:executeCycle, String.t()}
          | {:orderType, String.t()}
          | {:trend, String.t()}
  @spec create_trigger_order(client(), String.t(), [create_trigger_order_option()]) :: response()
  @doc section: :account_and_trading
  def create_trigger_order(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")
    price = Keyword.get(opts, :price, 10000)
    vol = Keyword.get(opts, :vol, 1)
    leverage = Keyword.get(opts, :leverage, 10)
    side = Keyword.get(opts, :side, "BUY")
    openType = Keyword.get(opts, :openType, "LIMIT")
    triggerPrice = Keyword.get(opts, :triggerPrice, 10000)
    triggerType = Keyword.get(opts, :triggerType, "LAST")
    executeCycle = Keyword.get(opts, :executeCycle, "GTC")
    orderType = Keyword.get(opts, :orderType, "LIMIT")
    trend = Keyword.get(opts, :trend, "UP")

    query = [
      symbol: symbol,
      price: price,
      vol: vol,
      leverage: leverage,
      side: side,
      openType: openType,
      triggerPrice: triggerPrice,
      triggerType: triggerType,
      executeCycle: executeCycle,
      orderType: orderType,
      trend: trend
    ]

    client
    |> Tesla.post(
      "api/v1/private/planorder/place",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel the trigger order.

  ## Options
    * `:orders` - A list of cancel order request objects. Required.
      * `:symbol` - The symbol of the order to cancel. Required.
      * `:orderId` - The order ID of the order to cancel. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_trigger_order("#{@docs_secret_key}", orders: [%{symbol: "BTCUSDT", orderId: 1}])
      iex> response.result["code"]
      1005
  """
  @type cancel_trigger_order_option :: {:orders, [map()]}
  @spec cancel_trigger_order(client(), String.t(), [cancel_trigger_order_option()]) :: response()
  @doc section: :account_and_trading
  def cancel_trigger_order(client, secret_key, opts \\ []) do
    orders = Keyword.get(opts, :orders, [%{symbol: "BTCUSDT", orderId: 1}])

    query = [
      orders: orders
    ]

    client
    |> Tesla.post(
      "api/v1/private/planorder/cancel",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel all trigger orders.

  ## Options
    * `:symbol` - The symbol of the order to cancel. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_all_trigger_orders("#{@docs_secret_key}", symbol: "BTCUSDT")
      iex> response.result["code"]
      1005
  """
  @type cancel_all_trigger_orders_option :: {:symbol, String.t()}
  @spec cancel_all_trigger_orders(client(), String.t(), [cancel_all_trigger_orders_option()]) ::
          response()
  @doc section: :account_and_trading
  def cancel_all_trigger_orders(client, secret_key, opts \\ []) do
    symbol = Keyword.get(opts, :symbol, "BTCUSDT")

    query = [
      symbol: symbol
    ]

    client
    |> Tesla.post(
      "api/v1/private/planorder/cancel_all",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel the stop-limit trigger order.

  ## Options
    * `:orders` - The list of cancel order request objects. Required.
      * `:stopPlanOrderId` - The stop-limit trigger order ID. Required.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_stop_limit_trigger_order("#{@docs_secret_key}", orders: [%{stopPlanOrderId: 1}])
      iex> response.result["code"]
      1005
  """
  @type cancel_stop_limit_trigger_order_option :: {:orders, [map()]}
  @spec cancel_stop_limit_trigger_order(client(), String.t(), [
          cancel_stop_limit_trigger_order_option()
        ]) :: response()
  @doc section: :account_and_trading
  def cancel_stop_limit_trigger_order(client, secret_key, opts \\ []) do
    orders = Keyword.get(opts, :orders, [%{stopPlanOrderId: 1}])

    query = [
      orders: orders
    ]

    client
    |> Tesla.post(
      "api/v1/private/stoporder/cancel",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Cancel all stop-limit price trigger orders.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.cancel_all_stop_limit_trigger_orders("#{@docs_secret_key}")
      iex> response.result["code"]
      1005
  """
  @spec cancel_all_stop_limit_trigger_orders(client(), String.t()) :: response()
  @doc section: :account_and_trading
  def cancel_all_stop_limit_trigger_orders(client, secret_key) do
    client
    |> Tesla.post(
      "api/v1/private/stoporder/cancel_all",
      %{},
      headers: get_request_signature(client, secret_key)
    )
    |> unwrap_response()
  end

  @doc """
  Switch Stop-Limit limited order price.

  ## Options
    * `:orderId` - The order ID. Required.
    * `:stopLossPrice` - The stop-loss price. Optional.
    * `:takeProfitPrice` - The take-profit price. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.switch_stop_limit_order_price("#{@docs_secret_key}", orderId: 1, stopLossPrice: 1, takeProfitPrice: 1)
      iex> response.result["code"]
      1005
  """
  @type switch_stop_limit_order_option ::
          {:orderId, integer()} | {:stopLossPrice, float()} | {:takeProfitPrice, float()}
  @spec switch_stop_limit_order_price(client(), String.t(), [switch_stop_limit_order_option()]) ::
          response()
  @doc section: :account_and_trading
  def switch_stop_limit_order_price(client, secret_key, opts \\ []) do
    order_id = Keyword.get(opts, :orderId, 1)
    stop_loss_price = Keyword.get(opts, :stopLossPrice, 1)
    take_profit_price = Keyword.get(opts, :takeProfitPrice, 1)

    query = [
      orderId: order_id,
      stopLossPrice: stop_loss_price,
      takeProfitPrice: take_profit_price
    ]

    client
    |> Tesla.post(
      "api/v1/private/stoporder/change_price",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @doc """
  Switch the stop-limit price of trigger orders.

  ## Options
    * `:stopPlanOrderId` - The stop-limit trigger order ID. Required.
    * `:stopLossPrice` - The stop-loss price. Optional.
    * `:takeProfitPrice` - The take-profit price. Optional.

  ## Example
      iex> alias Emxc.Global.Futures.V1, as: Futures
      iex> {:ok, response} = Futures.authorized_client(api_key: "#{@docs_api_key}") |> Futures.switch_stop_limit_trigger_order_price("#{@docs_secret_key}", stopPlanOrderId: 1, stopLossPrice: 1, takeProfitPrice: 1)
      iex> response.result["code"]
      1005
  """
  @type switch_stop_limit_trigger_order_option ::
          {:stopPlanOrderId, integer()} | {:stopLossPrice, float()} | {:takeProfitPrice, float()}
  @spec switch_stop_limit_trigger_order_price(client(), String.t(), [
          switch_stop_limit_trigger_order_option()
        ]) ::
          response()
  @doc section: :account_and_trading
  def switch_stop_limit_trigger_order_price(client, secret_key, opts \\ []) do
    stop_plan_order_id = Keyword.get(opts, :stopPlanOrderId, 1)
    stop_loss_price = Keyword.get(opts, :stopLossPrice, 1)
    take_profit_price = Keyword.get(opts, :takeProfitPrice, 1)

    query = [
      stopPlanOrderId: stop_plan_order_id,
      stopLossPrice: stop_loss_price,
      takeProfitPrice: take_profit_price
    ]

    client
    |> Tesla.post(
      "api/v1/private/stoporder/change_plan_price",
      query |> Enum.into(%{}),
      headers: post_request_signature(client, secret_key, query)
    )
    |> unwrap_response()
  end

  @spec get_request_signature(client(), String.t(), keyword()) :: headers()
  defp get_request_signature(client, secret_key, query \\ []) do
    api_key = get_api_key(client)
    timestamp = timestamp()

    parameters =
      if Enum.empty?(query) do
        ""
      else
        query
        |> URI.encode_query()
      end

    signature = sign_sha256(secret_key, parameters <> api_key <> timestamp)
    [{"Request-Time", "#{timestamp}"}, {"Signature", "#{signature}"}]
  end

  @spec post_request_signature(client(), String.t(), keyword(), boolean()) :: headers()
  defp post_request_signature(client, secret_key, payload, convert_to_map? \\ true) do
    api_key = get_api_key(client)
    timestamp = timestamp()

    payload = if convert_to_map?, do: payload |> Enum.into(%{}), else: payload

    signature =
      sign_sha256(
        secret_key,
        api_key <> timestamp <> (payload |> Jason.encode!())
      )

    [{"Request-Time", "#{timestamp}"}, {"Signature", "#{signature}"}]
  end

  @spec sign_sha256(String.t(), String.t()) :: String.t()
  defp sign_sha256(key, content) do
    :crypto.mac(:hmac, :sha256, key, content)
    |> Base.encode16(case: :lower)
  end

  defp timestamp do
    DateTime.utc_now()
    |> DateTime.to_unix(:millisecond)
    |> Integer.to_string()
  end

  defp get_api_key(%Tesla.Client{pre: pre}) do
    pre
    |> Enum.find(fn {x, _, _} -> x == Tesla.Middleware.Headers end)
    |> elem(2)
    |> List.flatten()
    |> Enum.find(fn {x, _} -> x == "ApiKey" end)
    |> elem(1)
  end
end
