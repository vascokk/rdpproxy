%%
%% rdpproxy
%% remote desktop proxy
%%
%% Copyright (c) 2012, The University of Queensland
%% Author: Alex Wilson <alex@uq.edu.au>
%%

-module(http_sessupd_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req, _Options) ->
    Method = cowboy_req:method(Req),
    {PeerIp, _PeerPort} = cowboy_req:peer(Req),
    case Method of
        <<"PUT">> ->
            IpBin = cowboy_req:binding(ip, Req),
            case http_api:peer_allowed(IpBin, PeerIp) of
                true ->
                    case cowboy_req:binding(user, Req) of
                        undefined ->
                            lager:info("~p cleared all sessions", [IpBin]),
                            {ok,_} = db_user_status:clear(IpBin),
                            Req2 = cowboy_req:reply(200, [], ["ok\n"], Req),
                            {ok, Req2, none};
                        UserBin ->
                            lager:info("~p register ONLY session for ~p", [IpBin, UserBin]),
                            {ok,_} = db_user_status:clear(IpBin),
                            ok = db_user_status:put(UserBin, IpBin),
                            Req2 = cowboy_req:reply(200, [], ["ok\n"], Req),
                            {ok, Req2, none}
                    end;
                false ->
                    lager:info("denying session update for ~p from ~p", [IpBin, PeerIp]),
                    Req2 = cowboy_req:reply(403, [], ["access denied\n"], Req),
                    {ok, Req2, none}
            end;
        <<"POST">> ->
            IpBin = cowboy_req:binding(ip, Req),
            case http_api:peer_allowed(IpBin, PeerIp) of
                true ->
                    UserBin = cowboy_req:binding(user, Req),
                    lager:info("~p register session for ~p", [IpBin, UserBin]),
                    ok = db_user_status:put(UserBin, IpBin),
                    Req2 = cowboy_req:reply(200, [], ["ok\n"], Req),
                    {ok, Req2, none};
                false ->
                    lager:info("denying session update for ~p from ~p", [IpBin, PeerIp]),
                    Req2 = cowboy_req:reply(403, [], ["access denied\n"], Req),
                    {ok, Req2, none}
            end
    end.
