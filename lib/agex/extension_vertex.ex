defmodule Age.Extension.Vertex do
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  # alias Age.Util
  require Logger

  @moduledoc """
  
  """

  def init(opts) do
    Keyword.get(opts, :decode_binary, :reference)
  end

  def matching(_) do
    [output: "vertex_out"]
  end

  def format(_) do
    :text
  end

  def encode(_opts) do
    quote location: :keep do
      %Age.Vertex{} = vertex ->
        data = unquote(__MODULE__).encode_elixir(vertex)
        [<<IO.iodata_length(data)::int32>> | data]
      other ->
        raise DBConnection.EncodeError, Postgrex.Utils.encode_msg(other, Age.Vertex)
    end
  end

  def decode(:reference) do
    quote location: :keep do
      <<len::int32, data::binary-size(len)>> ->
        unquote(__MODULE__).decode_elixir(data)
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len::int32, data::binary-size(len)>> ->
        unquote(__MODULE__).decode_elixir(:binary.copy(data))
    end
  end

  def encode_elixir(%Age.Vertex{gid: gid, label: label, props: props}) do
    str = label <> "[" <> gid <> "]" <> Jason.encode!(props)
    Logger.debug("encode vertex: #{inspect(str)}")
    str |> IO.iodata_to_binary
  end

  def decode_elixir(data) do
    Logger.debug("data: #{inspect(data)}")
    {:ok, re} = :re.compile("(.+?)\\[(.+?)\\](.*)")
    case :re.split(data, re)
      |> Enum.reject(fn x -> x=="" end) do
        [label, gid, props] ->
          # vertex
          %Age.Vertex{label: label, gid: gid, props: Jason.decode!(props)}

        _ ->
          nil
      end
  end

end