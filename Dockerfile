FROM elixir:1.12

WORKDIR /app

RUN mix do local.hex --force, local.rebar --force
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

COPY config ./config
COPY lib ./lib
RUN mix compile

COPY priv ./priv
COPY test ./test
