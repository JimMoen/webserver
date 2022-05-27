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
	{ok, _Body, Req} = cowboy_req:read_body(Req0),
    io:format("====body: ~p~n", [_Body]),
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
