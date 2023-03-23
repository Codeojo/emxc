defmodule Emxc.Utilities do
  @doc """
  Load a JSON file from the current directory.

  __NOTE__: This function is meant to be used in Macros/Metaprogramming.
  """
  def load_json(file, path) do
    Path.expand(file, path) |> File.read!() |> Jason.decode!()
  end

  @doc """
  Parses a Postman Environment JSON file into a Map.
  """
  def parse_environment(json) do
    json
    |> Map.get("values", [])
    |> Stream.filter(fn x -> x["enabled"] === true end)
    |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, x["key"], x["value"]) end)
  end

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
