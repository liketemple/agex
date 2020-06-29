defmodule Agex.GraphId do
  use Bitwise
  defstruct lab_id: 0, loc_id: 0
  # @type t :: %__MODULE__{lab_id: Integer.t(), lab_id: Integer.t()}

  def as_integer(%Agex.GraphId{lab_id: lab_id, loc_id: loc_id}) do
    (lab_id <<< 48) ||| loc_id
  end

  def as_string(%Agex.GraphId{lab_id: lab_id, loc_id: loc_id}) do
    "#{inspect(lab_id)}.#{inspect(loc_id)}"
  end
end

defimpl Inspect, for: Agex.GraphId do
  def inspect(%Agex.GraphId{lab_id: lab_id, loc_id: loc_id}, _opts) do
    "#GID<" <> "#{lab_id}.#{loc_id}" <> ">"
  end
end