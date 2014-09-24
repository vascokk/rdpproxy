%%
%% rdpproxy
%% remote desktop proxy
%%
%% Copyright (c) 2012, The University of Queensland
%% Author: Alex Wilson <alex@uq.edu.au>
%%

-module(http_api).
-export([start/0]).

start() ->
    Port = rdpproxy:config([http_api, port], 8080),
    Dispatch = cowboy_router:compile([
        {'_', [
            % legacy endpoints
            {"/status_update/:ip/:status", http_statupd_handler, []},
            {"/session_update/:ip", http_sessupd_handler, []},
            {"/session_update/:ip/:type/:user/:time", http_sessupd_handler, []},

            {"/[...]", cowboy_static,
                {priv_dir, rdpproxy, [<<"webroot">>], [
                    {mimetypes, cow_mimetypes, all}
            ]}}
        ]}
    ]),
    cowboy:start_http(http, 20, [{port, Port}],
        [{env, [{dispatch, Dispatch}]}]).
