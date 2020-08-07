# Agex

Postgrex extension for the AgensGraph and AGE data types.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `agex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agex, "~> 0.1.2"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/agex](https://hexdocs.pm/agex).

## Examples

```elixir
# Create new Postgrex Types Modules
Postgrex.Types.define(Agex.PostgresTypes, [
  Agex.Extension.GraphId, 
  Agex.Extension.Vertex, 
  Agex.Extension.Edge, 
  Agex.Extension.Path], [])

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

# for Apache AGE, need to load the age extension
Postgrex.query("LOAD 'age';", [])

q = """
 SET search_path = ag_catalog, "$user", public;
 """
Postgrex.query(q, [])

# network is an offical example database of AgensGraph
Postgrex.query("CREATE GRAPH network;", [])
Postgrex.query("set graph_path=network;", [])
Postgrex.query("CREATE VLABEL person;", [])
Postgrex.query("CREATE ELABEL knows;", [])
Postgrex.query("CREATE (n:movie {title:'Matrix'});", [])
Postgrex.query("CREATE (:person {name: 'Tom'})-[:knows {fromdate:'2011-11-24'}]->(:person {name: 'Summer'});")
Postgrex.query("CREATE (:person {name: 'Pat'})-[:knows {fromdate:'2013-12-25'}]->(:person {name: 'Nikki'});")
Postgrex.query("CREATE (:person {name: 'Olive'})-[:knows {fromdate:'2015-01-26'}]->(:person {name: 'Todd'});")
Postgrex.query("MATCH (p:Person {name: 'Tom'}),(k:Person{name: 'Pat'})") 
Postgrex.query("CREATE (p)-[:KNOWS {fromdate:'2017-02-27'} ]->(k);")
Postgrex.query("MATCH (p:movie) return p;", [])
Postgrex.query("MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;", [])
Postgrex.query("MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;", [])

```

## Test
Edit the database config in config/config.exs
```shell
mix test --seed 0
```

## TODO
- add ecto support
- add docs

