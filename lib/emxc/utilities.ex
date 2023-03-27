defmodule Emxc.Utilities do
  @doc """
  Unwraps a Tesla response into a tuple of `{:ok, map()}` or `{:error, any()}`.
  """
  @spec unwrap_response(any()) :: {:ok, map()} | {:error, any()} | no_return()
  def unwrap_response({:ok, %Tesla.Env{} = e}) do
    {:ok,
     %{
       status: e.status,
       result: e.body
     }}
  end

  def unwrap_response({:error, %Tesla.Env{} = e}) do
    {:error,
     %{
       status: e.status,
       result: e.body
     }}
  end

  def unwrap_response({:error, reason}) do
    {:error, reason}
  end

  def unwrap_response(_), do: {:error, :unknown}

  @doc """
  Generates an HMAC-256 signature for a given set of query parameters.

  ## Example
      iex> query = [symbol: "BTCUSDT", side: "BUY", type: "LIMIT", quantity: 1, price: 11, recvWindow: 5000, timestamp: 1644489390087]
      iex> secret_key = "45d0b3c26f2644f19bfb98b07741b2f5"
      iex> Emxc.Utilities.sign_get_query(query, secret_key)
      "fd3e4e8543c5188531eb7279d68ae7d26a573d0fc5ab0d18eb692451654d837a"
  """
  @spec sign_get_query(Enumerable.t(), String.t()) :: String.t()
  def sign_get_query(query, secret_key) do
    query_string =
      query
      |> URI.encode_query()

    sign_sha256(secret_key, query_string)
  end

  @doc """
    Signs a given string using the HMAC SHA-256 algorithm.

  ## Example
      iex> Emxc.Utilities.sign_sha256("foo", "bar")
      "f9320baf0249169e73850cd6156ded0106e2bb6ad8cab01b7bbbebe6d1065317"
  """
  @spec sign_sha256(String.t(), String.t()) :: String.t()
  def sign_sha256(key, content) do
    :crypto.mac(:hmac, :sha256, key, content)
    |> Base.encode16()
    |> String.downcase()
  end
end
