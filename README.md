# Agex

Postgrex extension for the AgensGraph and AGE data types.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `agex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agex, "~> 0.1.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/agex](https://hexdocs.pm/agex).

## Examples

```elixir
# Create a new Postgrex Types module
Postgrex.Types.define(MyApp.PostgresTypes, [
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
# network is the offical example database of AgensGraph
Postgrex.query("set graph_path=network;", [])
Postgrex.query("MATCH (p:movie) return p;", [])
Postgrex.query("MATCH (:person {name: 'Tom'})-[r:knows]->(:person {name: 'Summer'}) return r;", [])
Postgrex.query("MATCH p=(:person {name: 'Tom'})-[:knows]->(:person) RETURN p;", [])

```

## TODO
- add ecto support
- add docs

