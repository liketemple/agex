defmodule AgexTest do
  use ExUnit.Case, async: false
  require Logger
  doctest Agex

  def query(conn, query, params \\ []) do
    case Postgrex.query(conn, query, params) do
      {:ok, response} ->
        Logger.debug("response: #{inspect(response)}")
        :ok
      _ ->
        :error
    end
  end

  def set_graph(conn, graph \\ "network") do
    query(conn, "set graph_path=#{graph};")
  end

  setup_all do
    env = Application.get_env(:agex, :agensdb)

    {:ok, pid} =
      Postgrex.start_link(
        hostname: env[:ip],
        port: env[:port],
        username: env[:user],
        password: env[:password],
        database: env[:db],
        types: Agex.PostgresTypes
      )
    # Agent.start_link(fn -> pid end, name: :agens_conn)

    query(pid, "LOAD 'age';")
    q = """
    SET search_path = ag_catalog, "$user", public;
    """
    query(pid, q)
    set_graph(pid)
    {:ok, conn: pid}
  end

  test "basic vertex", context do
    assert query(context[:conn], "MATCH (v:movie) return v;", []) == :ok
  end

  test "basic edge", context do
    assert query(context[:conn], "MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;", []) == :ok
  end

  test "basic path", context do
    assert query(context[:conn], "MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;", []) == :ok
  end

end

Postgrex.Types.define(Agex.PostgresTypes, [
  Agex.Extension.GraphId, 
  Agex.Extension.Vertex, 
  Agex.Extension.Edge, 
  Agex.Extension.Path], [])