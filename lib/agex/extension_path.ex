defmodule Age.Extension.Path do
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
    [output: "graphpath_out"]
  end

  def format(_) do
    :text
  end

  def encode(_opts) do
    quote location: :keep do
      %Age.Path{} = path ->
        data = unquote(__MODULE__).encode_elixir(path)
        [<<IO.iodata_length(data)::int32>> | data]
      other ->
        raise DBConnection.EncodeError, Postgrex.Utils.encode_msg(other, Age.Path)
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

  def encode_elixir(%Age.Path{vertices: vertices, edges: edges}) do
    v_str_list = Enum.reduce(vertices, [], fn v, acc -> 
      [Age.Extension.Vertex.encode_elixir(v) | acc]
    end) |> Enum.reverse()

    e_str_list = Enum.reduce(edges, [], fn e, acc -> 
      [Age.Extension.Edge.encode_elixir(e) | acc]
    end) |> Enum.reverse()

    str = Enum.reduce(0..(length(e_str_list)-1), "", fn index, acc ->
      acc <> Enum.at(v_str_list, index) <> "," <> Enum.at(e_str_list, index) <> "," <> Enum.at(v_str_list, (index + 1))
    end)
    
    Logger.debug("encode path: #{inspect(str)}")
    str |> IO.iodata_to_binary
  end

  def decode_elixir(data) do
    Logger.debug("data: #{inspect(data)}")
    raw_list = data
      |> String.trim
      |> String.slice(1, String.length(data)-2)
      |> String.split("},")
      |> Enum.map(fn x -> 
        if String.at(x, -1) != "}" do
          x <> "}" 
        else
          x
        end
      end)
    list_len = length(raw_list)
    Logger.debug("raw_list: #{inspect(raw_list)}, list_len: #{inspect(list_len)}")
    cond do
      list_len >= 3 and rem(list_len,2) == 1 ->
        raw_vertices = Enum.take_every(raw_list, 2)
        raw_edges = Enum.drop_every(raw_list, 2)
        Logger.debug("raw_vertices: #{inspect(raw_vertices)}")
        Logger.debug("raw_edges: #{inspect(raw_edges)}")
        vertices = Enum.reduce(raw_vertices, [], fn raw_v, acc ->
          Logger.debug("raw_v: #{inspect(raw_v)}")
          [Age.Extension.Vertex.decode_elixir(raw_v) | acc]
        end)
        edges = Enum.reduce(raw_edges, [], fn raw_d, acc ->
          [Age.Extension.Edge.decode_elixir(raw_d) | acc]
        end)
        %Age.Path{vertices: Enum.reverse(vertices), edges: Enum.reverse(edges)}
      true ->
        nil
    end
  end

end