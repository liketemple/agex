defmodule Agex.Extension.GraphId do
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  # alias Agex.Util
  require Logger

  @moduledoc """
  
  """

  def init(opts) do
    Keyword.get(opts, :decode_binary, :reference)
  end

  def matching(_) do
    [output: "graphid_out"]
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
        raise DBConnection.EncodeError, Postgrex.Utils.encode_msg(other, Agex.GrpahId)
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

  def encode_elixir(%Agex.GraphId{lab_id: lab_id, loc_id: loc_id}) do
    str = to_string(lab_id) <> "." <> to_string(loc_id)
    Logger.debug("encode graphid: #{inspect(str)}")
    str |> IO.iodata_to_binary
  end

  def decode_elixir(data) do
    # Logger.debug("data: #{inspect(data)}")
    case String.split(data, ".") do
      [lab_id, loc_id] ->
        %Agex.GraphId{lab_id: lab_id, loc_id: loc_id}
      _ ->
        nil
    end
  end

end