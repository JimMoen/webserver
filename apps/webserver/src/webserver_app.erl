%%%-------------------------------------------------------------------
%% @doc webserver public API
%% @end
%%%-------------------------------------------------------------------

-module(webserver_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Port = 9901,
    %% PortTls = 9902,
    io:format("Setup a testing web server on ~p~n", [Port]),
    %% io:format("Setup a testing tls web server on ~p~n", [PortTls]),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/[...]", toppage_h, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(http, [{port, Port}], #{
        env => #{dispatch => Dispatch}
    }),
    %% {ok, _} = cowboy:start_tls(example, [
    %%         {port, PortTls},
    %%         {certfile, "./certs/cert.pem"},
    %%         {cacertfile, "./certs/cacert.pem"},
    %%         {keyfile, "./certs/key.pem"}
    %%     ], #{
    %%     env => #{dispatch => Dispatch}
    %% }),
    webserver_sup:start_link().

stop(_State) ->
    ok = cowboy:stop_listener(http).

%% internal functions
