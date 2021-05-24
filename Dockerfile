FROM elixir:1.12

WORKDIR /app

RUN mix do local.hex --force, local.rebar --force
COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config ./config
COPY lib ./lib

ARG MIX_ENV=dev
RUN mix compile

COPY priv ./priv
COPY test ./test
