defmodule Agex.Extension.Vertex do
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  alias Agex.Extension.GraphId
  # alias Agex.Util
  require Logger

  @moduledoc """
  
  """

  def init(opts) do
    Keyword.get(opts, :decode_binary, :reference)
  end

  def matching(_) do
    [output: "vertex_out", type: "vertex"]
  end

  def format(_) do
    :text
  end

  def encode(_opts) do
    quote location: :keep do
      %Agex.Vertex{} = vertex ->
        data = unquote(__MODULE__).encode_elixir(vertex)
        [<<IO.iodata_length(data)::int32>> | data]
      other ->
        raise DBConnection.EncodeError, Postgrex.Utils.encode_msg(other, Agex.Vertex)
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

  def encode_elixir(%Agex.Vertex{gid: gid, label: label, props: props}) do
    str = label <> "[" <> GraphId.encode_elixir(gid) <> "]" <> Jason.encode!(props)
    Logger.debug("encode vertex: #{inspect(str)}")
    str |> IO.iodata_to_binary
  end

  def decode_elixir(data) do
    # Logger.debug("data: #{inspect(data)}")
    {:ok, re} = :re.compile("(.+?)\\[(.+?)\\](.*)")
    case :re.split(data, re)
      |> Enum.reject(fn x -> x=="" end) do
        [label, gid, props] ->
          # vertex
          %Agex.Vertex{
            label: label, 
            gid: GraphId.decode_elixir(gid), 
            props: Jason.decode!(props)}

        _ ->
          nil
      end
  end

end