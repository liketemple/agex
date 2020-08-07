defmodule AgexTest do
  use ExUnit.Case, async: false
  require Logger
  doctest Agex

  def query(conn, query, params \\ []) do
    case Postgrex.query(conn, query, params) do
      {:ok, response} ->
        Logger.debug("response: #{inspect(response)}")
        :ok

      result ->
        Logger.warn("query error: #{result}")
        :error
    end
  end

  def execute(conn, query, params \\ []) do
    case Postgrex.execute(conn, query, params) do
      {:ok, _q, response} ->
        Logger.debug("response: #{inspect(response)}")
        :ok

      {:error, result} ->
        Logger.warn("query error: #{result}")
        :error
    end
  end

  def set_graph(conn, graph \\ "network") do
    query(conn, "set graph_path=#{graph};")
  end

  setup_all do
    Logger.debug("setup all.")
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

    # query(pid, "LOAD 'age';")

    q = """
    SET search_path = ag_catalog, "$user", public;
    """

    query(pid, "CREATE GRAPH network;")
    set_graph(pid)
    query(pid, q)

    {:ok, conn: pid}
  end

  # test "create graph", context do
  #   assert query(context[:conn], "CREATE GRAPH network;", []) == :ok
  # end

  # test "set graph", context do
  #   assert query(context[:conn], "SET graph_path=network;", []) == :ok
  # end

  test "create vlabel", context do
    assert query(context[:conn], "CREATE VLABEL person;", []) == :ok
  end

  test "create elabel", context do
    assert query(context[:conn], "CREATE ELABEL knows;", []) == :ok
  end

  test "create movie", context do
    assert query(context[:conn], "CREATE (n:movie {title:'Matrix'});", []) == :ok
  end

  test "create person Tom", context do
    assert query(
             context[:conn],
             "CREATE (:person {name: 'Tom'})-[:knows {fromdate:'2011-11-24'}]->(:person {name: 'Summer'});",
             []
           ) == :ok
  end

  test "create person Pat", context do
    assert query(
             context[:conn],
             "CREATE (:person {name: 'Pat'})-[:knows {fromdate:'2013-12-25'}]->(:person {name: 'Nikki'});",
             []
           ) == :ok
  end

  test "create person Olive", context do
    assert query(
             context[:conn],
             "CREATE (:person {name: 'Olive'})-[:knows {fromdate:'2015-01-26'}]->(:person {name: 'Todd'});",
             []
           ) == :ok
  end

  test "match create", context do
    q = """
    MATCH (p:person {name: 'Tom'}),(k:person{name: 'Pat'}) 
    CREATE (p)-[:knows {fromdate:'2017-02-27'} ]->(k);
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "query 1", context do
    Logger.debug("query 1")

    q = """
    MATCH (n:person {name: 'Tom'})-[:knows]->(m:person) RETURN n.name AS n, m.name AS m;
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "query 2", context do
    Logger.debug("query 2")

    q = """
    MATCH (p:person {name: 'Tom'})-[:knows]->(f:person)
    RETURN f.name
    UNION ALL
    MATCH (p:person {name: 'Tom'})-[:knows]->()-[:knows]->(f:person)
    RETURN f.name;
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "query 3", context do
    Logger.debug("query 3")

    q = """
    MATCH (p:person {name: 'Tom'})-[r:knows*1..2]->(f:person)
    RETURN f.name, r[1].fromdate;
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "query 4", context do
    Logger.debug("query 4")

    q = """
    MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'})
    SET r.since = '2009-01-08';
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "query 5", context do
    Logger.debug("query 5")

    q = """
    MATCH (n:person {name: 'Pat'}) DETACH DELETE (n);
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "query 6", context do
    Logger.debug("query 6")

    q = """
    MATCH (n)-[r]->(m) RETURN n.name AS n, properties(r) AS r, m.name AS m;
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "merge 1", context do
    Logger.debug("merge 1")

    Postgrex.transaction(context[:conn], fn conn ->
      q = """
      CREATE (:customer {name:'Tom', city:'santa clara'}),
       (:customer {name:'Summer ', city:'san jose'}),
       (:customer {name:'Pat', city:'santa clara'}),
       (:customer {name:'Nikki', city:'san jose'}),
       (:customer {name:'Olive', city:'san francisco'});
      """

      assert query(conn, "CREATE VLABEL customer;", []) == :ok
      assert query(conn, "CREATE VLABEL city;", []) == :ok
      assert query(conn, q, []) == :ok
      assert query(conn, "MATCH (a:customer) MERGE (c:city {name:a.city});", []) == :ok
      assert query(conn, "MATCH (c:city) RETURN properties(c);", []) == :ok
    end)
  end

  test "merge 2", context do
    Logger.debug("merge 2")

    Postgrex.transaction(context[:conn], fn conn ->
      q = """
      MATCH (a:customer)
      MERGE (c:city {name:a.city})
      ON MATCH SET c.matched = 'true'
      ON CREATE SET c.created = 'true';
      """

      assert query(conn, "CREATE (:customer {name:'Todd', city:'palo alto'});", []) == :ok
      assert query(conn, q, []) == :ok
      assert query(conn, "MATCH (c:city) RETURN properties(c);", []) == :ok
    end)
  end

  test "merge 3", context do
    Logger.debug("merge 3")

    Postgrex.transaction(context[:conn], fn conn ->
      q = """
      MATCH (a:customer)
      MERGE (c:city {name:a.city});
      """

      assert query(conn, "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;", []) == :ok
      assert query(conn, q, []) == :ok
    end)
  end

  test "merge 4", context do
    Logger.debug("merge 4")

    Postgrex.transaction(context[:conn], fn conn ->
      q = """
      MATCH (p1:person {name: 'Tom'}), (p2:person {name: 'Todd'}), 
       path=shortestpath((p1)-[:knows*1..5]->(p2)) RETURN path;
      """

      assert query(
               conn,
               "MATCH (p:person {name:'Tom'}), (f:person {name:'Olive'}) CREATE (p)-[:knows]->(f);",
               []
             ) == :ok

      assert query(conn, q, []) == :ok
    end)
  end

  test "hybird query 1 create", context do
    Logger.debug("hybird 1")

    Postgrex.transaction(context[:conn], fn conn ->
      q = """
      CREATE TABLE history (year, event)
      AS VALUES (1996, 'PostgreSQL'), (2016, 'AgensGraph');
      """

      assert query(conn, "CREATE GRAPH bitnine;", []) == :ok
      assert query(conn, "CREATE VLABEL dev;", []) == :ok
      assert query(conn, "CREATE (:dev {name: 'someone', year: 2015});", []) == :ok
      assert query(conn, "CREATE (:dev {name: 'somebody', year: 2016});", []) == :ok
      assert query(conn, q, []) == :ok
    end)
  end

  test "hybird query 2 Cypher in SQL", context do
    Logger.debug("hybird 2 Cypher in SQL")
    q = """
    SELECT n->>'name' as name 
    FROM history, (MATCH (n:dev) RETURN n) as dev 
    WHERE history.year > (n->>'year')::int;
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "hybird query 3 SQL in Cypher", context do
    Logger.debug("hybird 3 SQL in Cypher")
    q = """
    MATCH (n:dev)
    WHERE n.year < (SELECT year FROM history WHERE event = 'AgensGraph')
    RETURN properties(n) AS n;
    """

    assert query(context[:conn], q, []) == :ok
  end

  test "basic vertex", context do
    Logger.debug("basic vertex")
    assert query(context[:conn], "MATCH (v:movie) return v;", []) == :ok
  end

  test "basic edge", context do
    Logger.debug("basic edge")
    assert query(
             context[:conn],
             "MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;",
             []
           ) == :ok
  end

  test "basic path", context do
    Logger.debug("basic path")
    assert query(
             context[:conn],
             "MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;",
             []
           ) == :ok
  end

  test "clean", context do
    Logger.debug("clean")
    assert query(context[:conn], "DROP GRAPH network CASCADE;", [])
    assert query(context[:conn], "DROP GRAPH bitnine CASCADE;", [])
    assert query(context[:conn], "drop table history CASCADE;", [])
  end
end

Postgrex.Types.define(
  Agex.PostgresTypes,
  [
    Agex.Extension.GraphId,
    Agex.Extension.Vertex,
    Agex.Extension.Edge,
    Agex.Extension.Path
  ],
  []
)
