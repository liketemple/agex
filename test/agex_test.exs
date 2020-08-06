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

    query(pid, "LOAD 'age';")
    q = """
    SET search_path = ag_catalog, "$user", public;
    """
    {:ok, conn: pid}
  end

  test "create graph" do
    assert query(context[:conn], "CREATE GRAPH network;", []) == :ok
  end

  test "set graph" do
    assert query(context[:conn], "SET graph_path = network;", []) == :ok
  end

  test "create vlabel" do
    assert query(context[:conn], "CREATE VLABEL person;", []) == :ok
  end

  test "create elabel" do
    assert query(context[:conn], "CREATE ELABEL knows;", []) == :ok
  end

  test "create movie" do
    assert query(context[:conn], "CREATE (n:movie {title:'Matrix'});", []) == :ok
  end

  test "create person Tom" do
    assert query(context[:conn], "CREATE (:person {name: 'Tom'})-[:knows {fromdate:'2011-11-24'}]->(:person {name: 'Summer'});", []) == :ok
  end

  test "create person Pat" do
    assert query(context[:conn], "CREATE (:person {name: 'Pat'})-[:knows {fromdate:'2013-12-25'}]->(:person {name: 'Nikki'});", []) == :ok
  end

  test "create person Olive" do
    assert query(context[:conn], "CREATE (:person {name: 'Olive'})-[:knows {fromdate:'2015-01-26'}]->(:person {name: 'Todd'});", []) == :ok
  end

  test "match create", context do
    q = """
    MATCH (p:Person {name: 'Tom'}),(k:Person{name: 'Pat'}) 
    CREATE (p)-[:KNOWS {fromdate:'2017-02-27'} ]->(k);
    """
    assert query(context[:conn], q, []) == :ok
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