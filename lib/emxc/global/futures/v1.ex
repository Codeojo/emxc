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

  @spec post_request_signature(client(), String.t(), map()) :: headers()
  defp post_request_signature(client, secret_key, payload) do
    api_key = get_api_key(client)
    timestamp = timestamp()

    signature = sign_sha256(secret_key, (payload |> Jason.encode!()) <> api_key <> timestamp)
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
