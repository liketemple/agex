defmodule Agex.Edge do
  @moduledoc """
  
  """

  defstruct start_gid: nil, end_gid: nil, gid: nil, label: "", props: %{}
  # @type t :: %__MODULE__{start_gid: Agex.GraphId.t(), end_gid: Agex.GraphId.t(), gid: Agex.GraphId.t(), label: String.t(), props: Map.t()}
end
