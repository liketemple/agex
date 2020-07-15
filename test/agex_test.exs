defmodule AgexTest do
  use ExUnit.Case
  doctest Agex

  test "greets the world" do
    env = Application.get_env(:agex, :agensdb)
    {:ok, conn} =
      Postgrex.start_link(
        hostname: env[:ip],
        port: env[:port],
        username: env[:user],
        password: env[:password],
        database: env[:db],
        types: Agex.PostgresTypes
      )
      Postgrex.query("LOAD 'age';", [])
      q = """
        SET search_path = ag_catalog, "$user", public;
        """
      Postgrex.query(q, [])
      # network is the offical example database of AgensGraph
      Postgrex.query("set graph_path=network;", [])
      Postgrex.query("MATCH (p:movie) return p;", [])
      Postgrex.query("MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;", [])
      Postgrex.query("MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;", [])
  end
end

Postgrex.Types.define(MyApp.PostgresTypes, [
  Agex.Extension.GraphId, 
  Agex.Extension.Vertex, 
  Agex.Extension.Edge, 
  Agex.Extension.Path], [])