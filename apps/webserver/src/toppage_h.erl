%% Feel free to use, reuse and abuse the code in this file.

%% @doc POST echo handler.
-module(toppage_h).

-export([init/2]).

init(Req0, Opts) ->
    Method = cowboy_req:method(Req0),
    HasBody = cowboy_req:has_body(Req0),
    Req = maybe_echo(Method, HasBody, Req0),
    ets:update_counter(req_counter, received, 1, {received, 0}),
    {ok, Req, Opts}.

maybe_echo(<<"POST">>, true, Req0) ->
    {ok, Body, Req} = cowboy_req:read_body(Req0),
    %% Headers = cowboy_req:headers(Req0),
    maybe_delay(),
    %% io:format("====headers: ~p, body: ~p~n", [Headers, _Body]),
    bulk_sub(Body),
    echo(<<"ok\n">>, Req);
maybe_echo(<<"POST">>, false, Req) ->
    io:format("request received without message body~n"),
    cowboy_req:reply(400, [], <<"Missing body.">>, Req);
maybe_echo(Method, Hasbody, Req) ->
    %% Method not allowed.
    io:format("Unexpected request received: ~p~n", [{Method, Hasbody, Req}]),
    cowboy_req:reply(405, Req).

echo(undefined, Req) ->
    cowboy_req:reply(400, [], <<"Missing echo parameter.">>, Req);
echo(Echo, Req) ->
    cowboy_req:reply(200, #{
        <<"content-type">> => <<"text/plain; charset=utf-8">>
    }, Echo, Req).


maybe_delay() ->
    case persistent_term:get(response_delay, undefined) of
        undefined -> ok;
        Delay when is_integer(Delay) -> timer:sleep(Delay)
    end.

bulk_sub(Body0) ->
    #{<<"clientid">> := ClientID} = jiffy:decode(Body0, [return_maps]),
    Topics = [#{topic => <<ClientID/binary, "/", (integer_to_binary(Seq))/binary>>, nl => 0, qos => 0, rap => 0, rh => 0} || Seq <- lists:seq(1, 10)],
    Url = "http://127.0.0.1:18083/api/v5/clients/" ++ binary_to_list(ClientID) ++ "/subscribe/bulk",
    {ok, {{_, 200, _}, _, _}} = 
        httpc:request(
          post,
          {Url,
           [{"Authorization", "YOUR API KEY HERE"}],
           "application/json",
           encode(Topics)
          },
          [],
          [{body_format, binary}]
         ).

encode(T) ->
    to_binary(jiffy:encode(T)).

to_binary(B) when is_binary(B) -> B;
to_binary(L) when is_list(L) ->
    iolist_to_binary(L).
