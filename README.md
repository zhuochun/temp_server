# Temp Server

Run a temp server that respond with static json, in `.json` or `.json.erb`.

## Usage

Put any of your json files under `static`.

- Filename could be `endpoint_{method}_{code}.json` or `endpoint_{method}_{code}.json.erb`.
  - `method` is lowercase: `get`, `post`, `put`, `patch`, `delete`.
- `GET` and `200` can be ignored, e.g. `endpoint.json` is the same as `endpoint_get_200.json`.
- Use format `{"header":...,"body":...}` to modify response header.

``` bash
$ ruby server.rb
$ curl localhost:4567/v1/me/scorecards
[{"id":1},{"id":2}]
$ curl localhost:4567/v1/me/scorecards/1
{"id":1}
```

There are default `/cfg` routes to provide some extra features:

- `/cfg/latency`, all requests that match the path, will incur a latency specified in `ms`.
- `/cfg/status`, all requests that match the path, will respond with this status code.

``` bash
$ curl -X POST -d '{"path":"scorecards","value":"1000"}' localhost:4567/cfg/latency
$ curl localhost:4567/cfg/latency
[{"path":"scorecards","value":"1000"}]
```

## Installation

```
$ git clone https://github.com/zhuochun/temp_server.git
$ cd temp_server
$ bundle install
```

## License

MIT 2016 @ [Zhuochun](https://github.com/zhuochun).
