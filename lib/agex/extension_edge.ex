defmodule Agex.Extension.Edge do
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  alias Agex.Extension.GraphId
  require Logger

  @moduledoc """
  
  """

  def init(opts) do
    Keyword.get(opts, :decode_binary, :reference)
  end

  def matching(_) do
    [output: "edge_out"]
  end

  def format(_) do
    :text
  end

  def encode(_opts) do
    quote location: :keep do
      %Agex.Edge{} = edge ->
        data = unquote(__MODULE__).encode_elixir(edge)
        [<<IO.iodata_length(data)::int32>> | data]
      other ->
        raise DBConnection.EncodeError, Postgrex.Utils.encode_msg(other, Agex.Edge)
    end
  end

  def decode(:reference) do
    quote location: :keep do
      <<len::int32, age::binary-size(len)>> ->
        unquote(__MODULE__).decode_elixir(age)
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len::int32, age::binary-size(len)>> ->
        unquote(__MODULE__).decode_elixir(:binary.copy(age))
    end
  end

  def encode_elixir(%Agex.Edge{start_gid: start_gid, end_gid: end_gid, gid: gid, label: label, props: props}) do
    str = label <> "[" <> GraphId.encode_elixir(gid) <> "]" 
      <> "[" <> GraphId.encode_elixir(start_gid) <> "," <> GraphId.encode_elixir(end_gid) <> "]"
      <> Jason.encode!(props)
    Logger.debug("encode edge: #{inspect(str)}")
    str |> IO.iodata_to_binary
  end

  def decode_elixir(data) do
    {:ok, re} = :re.compile("(.+?)\\[(.+?)\\]\\[(.+?),(.+?)\\](.*)")
    case :re.split(data, re)
      |> Enum.reject(fn x -> x=="" end) do
        [label, gid, start_gid, end_gid, props] ->
          # edge
          %Agex.Edge{
            start_gid: GraphId.decode_elixir(start_gid), 
            end_gid: GraphId.decode_elixir(end_gid), 
            label: label, 
            gid: GraphId.decode_elixir(gid), 
            props: Jason.decode!(props)}

        _ ->
          nil
      end
  end

end