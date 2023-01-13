import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :archethic, ArchethicPlaygroundWeb.Endpoint,
  http: [port: 4002],
  server: false

config :archethic, Archethic.Networking.PortForwarding, port_range: 49_152..65_535
