defmodule Agex do
  @moduledoc """
  Documentation for `Agex`.
  """

  def start() do
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
    Agent.start_link(fn -> pid end, name: :agens_conn)
  end

  def conn() do
    Agent.get(:agens_conn, & &1)
  end

  def query(query, params \\ []) do
    Postgrex.query(conn(), query, params)
  end

  def set_graph(graph \\ "network") do
    query("set graph_path=#{graph};")
  end

  def test() do
    Agex.start
    Agex.query("LOAD 'age';")
    q = """
    SET search_path = ag_catalog, "$user", public;
    """
    Agex.query(q)
    Agex.set_graph
    Agex.query("MATCH (p:movie) return p;")
    Agex.query("MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;")
    Agex.query("MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;")
  end


end

Postgrex.Types.define(Agex.PostgresTypes, [
  Agex.Extension.GraphId, 
  Agex.Extension.Vertex, 
  Agex.Extension.Edge, 
  Agex.Extension.Path], [])

  # Agex.start
  # Agex.set_graph
  # Agex.query("MATCH (p:movie) return p;")
  # Agex.query("MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;")
  # Agex.query("MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;")