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
end
