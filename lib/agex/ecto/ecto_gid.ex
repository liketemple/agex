if Code.ensure_loaded?(Ecto.Type) do
  defmodule Age.Ecto.GraphId do

    if macro_exported?(Ecto.Type, :__using__, 1) do
      use Ecto.Type
    else
      @behaviour Ecto.Type
    end

    def type, do: :graphid
    def base?(_), do: false

    def load(%Agex.GraphId{} = graphid), do: {:ok, graphid}
    def load(_), do: :error

    def dump(%Agex.GraphId{} = graphid), do: {:ok, graphid}
    def dump(_), do: :error

    def cast({:ok, value}), do: cast(value)
    def cast(%Agex.GraphId{} = graphid), do: {:ok, Map.from_struct(graphid)}

    def cast(%{:lob_id => lab_id, :loc_id => loc_id} = _graphid) when is_integer(lab_id) and is_integer(loc_id) do
      {:ok, %Agex.GraphId{lab_id: lab_id, loc_id: loc_id}}
    end

    def cast(%{"lob_id" => lab_id, "loc_id" => loc_id} = _graphid) when is_integer(lab_id) and is_integer(loc_id) do
      {:ok, %Agex.GraphId{lab_id: lab_id, loc_id: loc_id}}
    end

    def cast(graphid) when is_bitstring(graphid) do
      case String.split(data, ".") do
        [lab_id, loc_id] ->
          %Agex.GraphId{lab_id: String.to_integer(lab_id), loc_id: String.to_integer(loc_id)}
        _ ->
          :error
      end
    end


    def cast(_), do: :error
    def embed_as(_), do: :self
    def equal?(a, b), do: a == b
  end

  defmodule Agex.Ecto.Vertex do
    if macro_exported?(Ecto.Type, :__using__, 1) do
      use Ecto.Type
    else
      @behaviour Ecto.Type
    end

    def type, do: :vertex
    def base?(_), do: false

    def load(%Agex.Vertex{} = vertex), do: {:ok, vertex}
    def load(_), do: :error

    def dump(%Agex.Vertex{} = vertex), do: {:ok, vertex}
    def dump(_), do: :error

    def cast({:ok, value}), do: cast(value)
    def cast(%Agex.Vertex{} = age), do: {:ok, Map.from_struct(age)}

    def cast(%{:lob_id => lab_id, :loc_id => loc_id} = age) when is_integer(lab_id) and is_integer(loc_id) do
      {:ok, %Agex.Vertex{lab_id: lab_id, loc_id: loc_id}}
    end

    def cast(%{"lob_id" => lab_id, "loc_id" => loc_id} = age) when is_integer(lab_id) and is_integer(loc_id) do
      {:ok, %Agex.Vertex{lab_id: lab_id, loc_id: loc_id}}
    end

    def cast(age) when is_bitstring(age) do
      case String.split(data, ".") do
        [lab_id, loc_id] ->
          %Agex.GraphId{lab_id: String.to_integer(lab_id), loc_id: String.to_integer(loc_id)}
        _ ->
          :error
      end
    end


    def cast(_), do: :error
    def embed_as(_), do: :self
    def equal?(a, b), do: a == b
  end
end