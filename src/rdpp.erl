%%
%% rdpproxy
%% remote desktop proxy
%%
%% Copyright (c) 2012, The University of Queensland
%% Author: Alex Wilson <alex@uq.edu.au>
%%

-module(rdpp).

-include("kbd.hrl").
-include("rdpp.hrl").

-export([encode_protocol_flags/1, decode_protocol_flags/1]).
-export([decode_basic/1, decode_sharecontrol/1]).
-export([encode_basic/1, encode_sharecontrol/1]).
-export([pretty_print/1]).

pretty_print(Record) ->
	io_lib_pretty:print(Record, fun pretty_print/2).
pretty_print(ts_security, N) ->
	N = record_info(size, ts_security) - 1,
	record_info(fields, ts_security);
pretty_print(ts_info, N) ->
	N = record_info(size, ts_info) - 1,
	record_info(fields, ts_info);
pretty_print(ts_demand, N) ->
	N = record_info(size, ts_demand) - 1,
	record_info(fields, ts_demand);
pretty_print(ts_confirm, N) ->
	N = record_info(size, ts_confirm) - 1,
	record_info(fields, ts_confirm);
pretty_print(ts_redir, N) ->
	N = record_info(size, ts_redir) - 1,
	record_info(fields, ts_redir);
pretty_print(ts_deactivate, N) ->
	N = record_info(size, ts_deactivate) - 1,
	record_info(fields, ts_deactivate);
pretty_print(ts_sharedata, N) ->
	N = record_info(size, ts_sharedata) - 1,
	record_info(fields, ts_sharedata);
pretty_print(ts_license_vc, N) ->
	N = record_info(size, ts_license_vc) - 1,
	record_info(fields, ts_license_vc);
pretty_print(ts_sync, N) ->
	N = record_info(size, ts_sync) - 1,
	record_info(fields, ts_sync);
pretty_print(ts_control, N) ->
	N = record_info(size, ts_control) - 1,
	record_info(fields, ts_control);
pretty_print(ts_fontlist, N) ->
	N = record_info(size, ts_fontlist) - 1,
	record_info(fields, ts_fontlist);
pretty_print(ts_fontmap, N) ->
	N = record_info(size, ts_fontmap) - 1,
	record_info(fields, ts_fontmap);
pretty_print(ts_input, N) ->
	N = record_info(size, ts_input) - 1,
	record_info(fields, ts_input);

pretty_print(ts_inpevt_sync, N) ->
	N = record_info(size, ts_inpevt_sync) - 1,
	record_info(fields, ts_inpevt_sync);
pretty_print(ts_inpevt_key, N) ->
	N = record_info(size, ts_inpevt_key) - 1,
	record_info(fields, ts_inpevt_key);
pretty_print(ts_inpevt_unicode, N) ->
	N = record_info(size, ts_inpevt_unicode) - 1,
	record_info(fields, ts_inpevt_unicode);
pretty_print(ts_inpevt_mouse, N) ->
	N = record_info(size, ts_inpevt_mouse) - 1,
	record_info(fields, ts_inpevt_mouse);
pretty_print(ts_inpevt_wheel, N) ->
	N = record_info(size, ts_inpevt_wheel) - 1,
	record_info(fields, ts_inpevt_wheel);

pretty_print(ts_cap_general, N) ->
	N = record_info(size, ts_cap_general) - 1,
	record_info(fields, ts_cap_general);
pretty_print(ts_cap_bitmap, N) ->
	N = record_info(size, ts_cap_bitmap) - 1,
	record_info(fields, ts_cap_bitmap);
pretty_print(ts_cap_share, N) ->
	N = record_info(size, ts_cap_share) - 1,
	record_info(fields, ts_cap_share);
pretty_print(ts_cap_order, N) ->
	N = record_info(size, ts_cap_order) - 1,
	record_info(fields, ts_cap_order);
pretty_print(ts_cap_input, N) ->
	N = record_info(size, ts_cap_input) - 1,
	record_info(fields, ts_cap_input);
pretty_print(ts_cap_font, N) ->
	N = record_info(size, ts_cap_font) - 1,
	record_info(fields, ts_cap_font);
pretty_print(ts_cap_pointer, N) ->
	N = record_info(size, ts_cap_pointer) - 1,
	record_info(fields, ts_cap_pointer);
pretty_print(0, _) ->
	no.

-spec encode_protocol_flags([atom()]) -> integer().
encode_protocol_flags(Protocols) ->
	CredSSPEarly = case lists:member(credssp_early, Protocols) of true -> 1; _ -> 0 end,
	CredSSP = case lists:member(credssp, Protocols) of true -> 1; _ -> 0 end,
	Ssl = case lists:member(ssl, Protocols) of true -> 1; _ -> 0 end,
	<<Prots:32/big>> = <<0:28, CredSSPEarly:1, 0:1, CredSSP:1, Ssl:1>>,
	Prots.

-spec decode_protocol_flags(integer()) -> [atom()].
decode_protocol_flags(Protocols) ->
	<<_:28, CredSSPEarly:1, _:1, CredSSP:1, Ssl:1>> = <<Protocols:32/big>>,
	Prots = if CredSSPEarly == 1 -> [credssp_early]; true -> [] end ++
			if CredSSP == 1 -> [credssp]; true -> [] end ++
			if Ssl == 1 -> [ssl]; true -> [] end,
	Prots.

-spec decode_sec_flags(integer()) -> {Type :: atom(), Flags :: [atom()]}.
decode_sec_flags(Flags) ->
	<<FlagsHiValid:1, _:1, AutodetectRsp:1, AutodetectReq:1, SaltedMAC:1, RedirectionPkt:1, EncryptLicense:1, _:1, LicensePkt:1, InfoPkt:1, IgnoreSeqno:1, ResetSeqno:1, Encrypt:1, MultitransRsp:1, MultitransReq:1, SecExchPkt:1>> = <<Flags:16/big>>,

	Type = if
		AutodetectRsp == 1 -> autodetect_rsp;
		AutodetectReq == 1 -> autodetect_req;
		RedirectionPkt == 1 -> redirection;
		LicensePkt == 1 -> license;
		InfoPkt == 1 -> info;
		MultitransRsp == 1 -> multitrans_rsp;
		MultitransReq == 1 -> multitrans_req;
		SecExchPkt == 1 -> security;
		true -> unknown
	end,

	FlagAtoms = if FlagsHiValid == 1 -> [flagshi_valid]; true -> [] end ++
				if SaltedMAC == 1 -> [salted_mac]; true -> [] end ++
				if EncryptLicense == 1 -> [encrypt_license]; true -> [] end ++
				if IgnoreSeqno == 1 -> [ignore_seqno]; true -> [] end ++
				if ResetSeqno == 1 -> [reset_seqno]; true -> [] end ++
				if Encrypt == 1 -> [encrypt]; true -> [] end,
	{Type, FlagAtoms}.

-spec encode_sec_flags({Type :: atom(), Flags :: [atom()]}) -> integer().
encode_sec_flags({Type, Flags}) ->
	{AutodetectRsp, AutodetectReq, RedirectionPkt, LicensePkt, InfoPkt, MultitransRsp, MultitransReq, SecExchPkt} = case Type of
		autodetect_rsp -> 	{1, 0, 0, 0, 0, 0, 0, 0};
		autodetect_req -> 	{0, 1, 0, 0, 0, 0, 0, 0};
		redirection -> 		{0, 0, 1, 0, 0, 0, 0, 0};
		license -> 			{0, 0, 0, 1, 0, 0, 0, 0};
		info -> 			{0, 0, 0, 0, 1, 0, 0, 0};
		multitrans_rsp -> 	{0, 0, 0, 0, 0, 1, 0, 0};
		multitrans_req -> 	{0, 0, 0, 0, 0, 0, 1, 0};
		security -> 		{0, 0, 0, 0, 0, 0, 0, 1};
		_ ->				{0, 0, 0, 0, 0, 0, 0, 0}
	end,

	FlagsHiValid = case lists:member(flagshi_valid, Flags) of true -> 1; _ -> 0 end,
	SaltedMAC = case lists:member(salted_mac, Flags) of true -> 1; _ -> 0 end,
	EncryptLicense = case lists:member(encrypt_license, Flags) of true -> 1; _ -> 0 end,
	IgnoreSeqno = case lists:member(ignore_seqno, Flags) of true -> 1; _ -> 0 end,
	ResetSeqno = case lists:member(reset_seqno, Flags) of true -> 1; _ -> 0 end,
	Encrypt = case lists:member(encrypt, Flags) of true -> 1; _ -> 0 end,

	<<Out:16/big>> = <<FlagsHiValid:1, 0:1, AutodetectRsp:1, AutodetectReq:1, SaltedMAC:1, RedirectionPkt:1, EncryptLicense:1, 0:1, LicensePkt:1, InfoPkt:1, IgnoreSeqno:1, ResetSeqno:1, Encrypt:1, MultitransRsp:1, MultitransReq:1, SecExchPkt:1>>,
	Out.

encode_sharecontrol(Pdu) ->
	{InnerType, Inner} = case Pdu of
		#ts_demand{} -> {16#1, encode_ts_demand(Pdu)};
		#ts_confirm{} -> {16#3, encode_ts_confirm(Pdu)};
		#ts_deactivate{} -> {16#6, encode_ts_deactivate(Pdu)};
		#ts_redir{} -> {16#a, encode_ts_redir(Pdu)};
		#ts_sharedata{} -> {16#7, encode_sharedata(Pdu)}
	end,
	Channel = element(2, Pdu),
	Length = byte_size(Inner) + 6,
	<<Type:16/big>> = <<0:8, 1:4, InnerType:4>>,
	{ok, <<Length:16/little, Type:16/little, Channel:16/little, Inner/binary>>}.

decode_sharecontrol(Bin) ->
	case Bin of
		<<Length:16/little, Type:16/little, Chan:16/little, Rest/binary>> ->
			<<_:7, 0:1, 1:4, InnerType:4>> = <<Type:16/big>>,
			RealLength = byte_size(Rest) + 6,
			if RealLength == Length ->
				case InnerType of
					16#1 -> decode_ts_demand(Chan, Rest);
					16#3 -> decode_ts_confirm(Chan, Rest);
					16#6 -> decode_ts_deactivate(Chan, Rest);
					16#7 -> decode_sharedata(Chan, Rest);
					16#a -> decode_ts_redir(Chan, Rest);
					_ -> {error, badpacket}
				end;
			true ->
				{error, badlength}
			end;
		_ ->
			{error, badpacket}
	end.

zero_pad(Bin, Len) when is_list(Bin) ->
	zero_pad(list_to_binary(Bin), Len);
zero_pad(Bin, Len) ->
	Rem = Len - byte_size(Bin),
	<<Bin/binary, 0:Rem/unit:8>>.

decode_tscaps(0, _) -> [];
decode_tscaps(N, Bin) ->
	<<Type:16/little, Size:16/little, Rest/binary>> = Bin,
	Len = Size - 4,
	<<Data:Len/binary-unit:8, Rem/binary>> = Rest,
	[decode_tscap(Type, Data) | decode_tscaps(N-1, Rem)].

decode_tscap(1, Bin) ->
	<<MajorNum:16/little, MinorNum:16/little, _:16, _:16, _:16, ExtraFlags:16/little, _:16, _:16, _:16, RefreshRect:8, SuppressOutput:8>> = Bin,
	<<0:5, ShortBitmapHdr:1, 0:5, SaltedMac:1, AutoRecon:1, LongCreds:1, 0:1, FastPath:1>> = <<ExtraFlags:16/big>>,

	Major = case MajorNum of 1 -> windows; 2 -> os2; 3 -> macintosh; 4 -> unix; _ -> other end,
	Minor = case MinorNum of 1 -> win31x; 2 -> win95; 3 -> winnt; 4 -> os2v21; 5 -> powerpc; 6 -> macintosh; 7 -> native_x11; 8 -> pseudo_x11; _ -> other end,

	Flags = if RefreshRect == 1 -> [refresh_rect]; true -> [] end ++
			if SuppressOutput == 1 -> [suppress_output]; true -> [] end ++
			if ShortBitmapHdr == 1 -> [short_bitmap_hdr]; true -> [] end ++
			if SaltedMac == 1 -> [salted_mac]; true -> [] end ++
			if AutoRecon == 1 -> [autoreconnect]; true -> [] end ++
			if LongCreds == 1 -> [long_creds]; true -> [] end ++
			if FastPath == 1 -> [fastpath]; true -> [] end,

	#ts_cap_general{os = [Major, Minor], flags = Flags};

decode_tscap(2, Bin) ->
	<<Bpp:16/little, _:16, _:16, _:16, Width:16/little, Height:16/little, _:16, Resize:16/little, Compression:16/little, _:8, DrawingFlags:8, Multirect:16/little, _:16>> = Bin,
	<<_:4, SkipAlpha:1, Subsampling:1, DynamicBpp:1, _:1>> = <<DrawingFlags:8>>,

	Flags = if Resize == 1 -> [resize]; true -> [] end ++
			if Compression == 1 -> [compression]; true -> [] end ++
			if DynamicBpp == 1 -> [dynamic_bpp]; true -> [] end ++
			if Subsampling == 1 -> [subsampling]; true -> [] end ++
			if SkipAlpha == 1 -> [skip_alpha]; true -> [] end ++
			if Multirect == 1 -> [multirect]; true -> [] end,

	#ts_cap_bitmap{bpp = Bpp, flags = Flags, width = Width, height = Height};

decode_tscap(3, Bin) ->
	<<_:30/unit:8, BaseFlags:16/little, OrderSupport:32/binary-unit:8, _/binary>> = Bin,

	<<_:8, ExtraFlags:1, SolidPatternBrushOnly:1, ColorIndex:1, _:1, ZeroBoundsDeltas:1, _:1, NegotiateOrders:1, _:1>> = <<BaseFlags:16/big>>,

	<<DstBlt, PatBlt, ScrBlt, MemBlt, Mem3Blt, 0, 0, DrawNineGrid, LineTo, MultiDrawNineGrid, 0, SaveBitmap, 0, 0, 0, MultiDstBlt, MultiPatBlt, MultiScrBlt, MultiOpaqueRect, FastIndex, PolygonSC, PolygonCB, Polyline, 0, FastGlyph, EllipseSC, EllipseCB, Index, 0, 0, 0, _>> = OrderSupport,

	Flags = if SolidPatternBrushOnly == 1 -> [solid_pattern_brush_only]; true -> [] end ++
			if ColorIndex == 1 -> [colorindex]; true -> [] end ++
			if ZeroBoundsDeltas == 1 -> ['zeroboundsdeltas']; true -> [] end ++
			if NegotiateOrders == 1 -> [negotiate]; true -> [] end,

	Orders = if DstBlt == 1 -> [dstblt]; true -> [] end ++
			 if PatBlt == 1 -> [patblt]; true -> [] end ++
			 if ScrBlt == 1 -> [scrblt]; true -> [] end ++
			 if MemBlt == 1 -> [memblt]; true -> [] end ++
			 if Mem3Blt == 1 -> [mem3blt]; true -> [] end ++
			 if DrawNineGrid == 1 -> [drawninegrid]; true -> [] end ++
			 if LineTo == 1 -> [lineto]; true -> [] end ++
			 if MultiDrawNineGrid == 1 -> [multidrawninegrid]; true -> [] end ++
			 if SaveBitmap == 1 -> [savebitmap]; true -> [] end ++
			 if MultiDstBlt == 1 -> [multidstblt]; true -> [] end ++
			 if MultiPatBlt == 1 -> [multipatblt]; true -> [] end ++
			 if MultiScrBlt == 1 -> [multiscrblt]; true -> [] end ++
			 if MultiOpaqueRect == 1 -> [multiopaquerect]; true -> [] end ++
			 if FastIndex == 1 -> [fastindex]; true -> [] end ++
			 if PolygonSC == 1 -> [polygonsc]; true -> [] end ++
			 if PolygonCB == 1 -> [polygoncb]; true -> [] end ++
			 if Polyline == 1 -> [polyline]; true -> [] end ++
			 if FastGlyph == 1 -> [fastglyph]; true -> [] end ++
			 if EllipseSC == 1 -> [ellipsesc]; true -> [] end ++
			 if EllipseCB == 1 -> [ellipsecb]; true -> [] end ++
			 if Index == 1 -> [index]; true -> [] end,

	#ts_cap_order{flags = Flags, orders = Orders};

decode_tscap(9, Bin) ->
	<<Chan:16/little, _:16>> = Bin,
	#ts_cap_share{channel = Chan};

decode_tscap(14, Bin) ->
	<<Fontlist:16/little, _:16>> = Bin,
	Flags = if Fontlist == 1 -> [fontlist]; true -> [] end,
	#ts_cap_font{flags = Flags};

decode_tscap(8, Bin) ->
	<<Color:16/little, _:16, CacheSize:16/little>> = Bin,
	Flags = if Color == 1 -> [color]; true -> [] end,
	#ts_cap_pointer{flags = Flags, cache_size = CacheSize};

decode_tscap(13, Bin) ->
	<<InputFlags:16/little, _:16, Layout:32/little, Type:32/little, SubType:32/little, FunKeys:32/little, ImeBin:64/binary-unit:8>> = Bin,
	<<_:10, FastPath2:1, Unicode:1, FastPath:1, MouseX:1, _:1, Scancodes:1>> = <<InputFlags:16/big>>,

	Flags = if Scancodes == 1 -> [scancodes]; true -> [] end ++
			if MouseX == 1 -> [mousex]; true -> [] end ++
			if FastPath == 1 -> [fastpath]; true -> [] end ++
			if Unicode == 1 -> [unicode]; true -> [] end ++
			if FastPath2 == 1 -> [fastpath2]; true -> [] end,

	#ts_cap_input{flags = Flags, ime = ImeBin, kbd_layout = Layout, kbd_type = Type, kbd_sub_type = SubType, kbd_fun_keys = FunKeys};

decode_tscap(Type, Bin) ->
	{Type, Bin}.

encode_tscap(#ts_cap_general{os = [Major,Minor], flags=Flags}) ->
	MajorNum = case Major of windows -> 1; os2 -> 2; macintosh -> 3; unix -> 4; _ -> 0 end,
	MinorNum = case Minor of win31x -> 1; win95 -> 2; winnt -> 3; os2v21 -> 4; powerpc -> 5; macintosh -> 6; native_x11 -> 7; pseudo_x11 -> 8; _ -> 0 end,

	FastPath = case lists:member(fastpath, Flags) of true -> 1; _ -> 0 end,
	ShortBitmapHdr = case lists:member(short_bitmap_hdr, Flags) of true -> 1; _ -> 0 end,
	LongCreds = case lists:member(long_creds, Flags) of true -> 1; _ -> 0 end,
	AutoRecon = case lists:member(autoreconnect, Flags) of true -> 1; _ -> 0 end,
	SaltedMac = case lists:member(salted_mac, Flags) of true -> 1; _ -> 0 end,

	RefreshRect = case lists:member(refresh_rect, Flags) of true -> 1; _ -> 0 end,
	SuppressOutput = case lists:member(suppress_output, Flags) of true -> 1; _ -> 0 end,

	<<ExtraFlags:16/big>> = <<0:5, ShortBitmapHdr:1, 0:5, SaltedMac:1, AutoRecon:1, LongCreds:1, 0:1, FastPath:1>>,
	Inner = <<MajorNum:16/little, MinorNum:16/little, 16#200:16/little, 0:16, 0:16, ExtraFlags:16/little, 0:16, 0:16, 0:16, RefreshRect:8, SuppressOutput:8>>,
	Size = byte_size(Inner) + 4,
	<<1:16/little, Size:16/little, Inner/binary>>;

encode_tscap(#ts_cap_bitmap{bpp = Bpp, flags = Flags, width = Width, height = Height}) ->
	Resize = case lists:member(resize, Flags) of true -> 1; _ -> 0 end,
	Compression = case lists:member(compression, Flags) of true -> 1; _ -> 0 end,
	DynamicBpp = case lists:member(dynamic_bpp, Flags) of true -> 1; _ -> 0 end,
	Subsampling = case lists:member(subsampling, Flags) of true -> 1; _ -> 0 end,
	SkipAlpha = case lists:member(skip_alpha, Flags) of true -> 1; _ -> 0 end,
	Multirect = case lists:member(multirect, Flags) of true -> 1; _ -> 0 end,

	<<DrawingFlags:8>> = <<0:4, SkipAlpha:1, Subsampling:1, DynamicBpp:1, 0:1>>,

	Inner = <<Bpp:16/little, 1:16/little, 1:16/little, 1:16/little, Width:16/little, Height:16/little, 0:16, Resize:16/little, Compression:16/little, 0:8, DrawingFlags:8, Multirect:16/little, 0:16>>,
	Size = byte_size(Inner) + 4,
	<<2:16/little, Size:16/little, Inner/binary>>;

encode_tscap(#ts_cap_order{flags = Flags, orders = Orders}) ->
	DstBlt = case lists:member(dstblt, Orders) of true -> 1; _ -> 0 end,
	DstBlt = case lists:member(dstblt, Orders) of true -> 1; _ -> 0 end,
	PatBlt = case lists:member(patblt, Orders) of true -> 1; _ -> 0 end,
	ScrBlt = case lists:member(scrblt, Orders) of true -> 1; _ -> 0 end,
	MemBlt = case lists:member(memblt, Orders) of true -> 1; _ -> 0 end,
	Mem3Blt = case lists:member(mem3blt, Orders) of true -> 1; _ -> 0 end,
	DrawNineGrid = case lists:member(drawninegrid, Orders) of true -> 1; _ -> 0 end,
	LineTo = case lists:member(lineto, Orders) of true -> 1; _ -> 0 end,
	MultiDrawNineGrid = case lists:member(multidrawninegrid, Orders) of true -> 1; _ -> 0 end,
	SaveBitmap = case lists:member(savebitmap, Orders) of true -> 1; _ -> 0 end,
	MultiDstBlt = case lists:member(multidstblt, Orders) of true -> 1; _ -> 0 end,
	MultiPatBlt = case lists:member(multipatblt, Orders) of true -> 1; _ -> 0 end,
	MultiScrBlt = case lists:member(multiscrblt, Orders) of true -> 1; _ -> 0 end,
	MultiOpaqueRect = case lists:member(multiopaquerect, Orders) of true -> 1; _ -> 0 end,
	FastIndex = case lists:member(fastindex, Orders) of true -> 1; _ -> 0 end,
	PolygonSC = case lists:member(polygonsc, Orders) of true -> 1; _ -> 0 end,
	PolygonCB = case lists:member(polygoncb, Orders) of true -> 1; _ -> 0 end,
	Polyline = case lists:member(polyline, Orders) of true -> 1; _ -> 0 end,
	FastGlyph = case lists:member(fastglyph, Orders) of true -> 1; _ -> 0 end,
	EllipseSC = case lists:member(ellipsesc, Orders) of true -> 1; _ -> 0 end,
	EllipseCB = case lists:member(ellipsecb, Orders) of true -> 1; _ -> 0 end,
	Index = case lists:member(index, Orders) of true -> 1; _ -> 0 end,

	OrderSupport = <<DstBlt, PatBlt, ScrBlt, MemBlt, Mem3Blt, 0, 0, DrawNineGrid, LineTo, MultiDrawNineGrid, 0, SaveBitmap, 0, 0, 0, MultiDstBlt, MultiPatBlt, MultiScrBlt, MultiOpaqueRect, FastIndex, PolygonSC, PolygonCB, Polyline, 0, FastGlyph, EllipseSC, EllipseCB, Index, 0, 0, 0, 0>>,

	SolidPatternBrushOnly = case lists:member(solid_pattern_brush_only, Orders) of true -> 1; _ -> 0 end,
	ColorIndex = case lists:member(colorindex, Orders) of true -> 1; _ -> 0 end,
	ZeroBoundsDeltas = case lists:member(zeroboundsdeltas, Orders) of true -> 1; _ -> 0 end,
	NegotiateOrders = case lists:member(negotiate, Orders) of true -> 1; _ -> 0 end,

	<<BaseFlags:16/big>> = <<0:8, 0:1, SolidPatternBrushOnly:1, ColorIndex:1, 0:1, ZeroBoundsDeltas:1, 0:1, NegotiateOrders:1, 0:1>>,

	Inner = <<0:30/unit:8, BaseFlags:16/little, OrderSupport/binary, 0:20/unit:8>>,
	Size = byte_size(Inner) + 4,
	<<3:16/little, Size:16/little, Inner/binary>>;

encode_tscap(#ts_cap_share{channel = Chan}) ->
	Inner = <<Chan:16/little, 0:16>>,
	Size = byte_size(Inner) + 4,
	<<9:16/little, Size:16/little, Inner/binary>>;

encode_tscap(#ts_cap_font{flags = Flags}) ->
	Fontlist = case lists:member(fontlist, Flags) of true -> 1; _ -> 0 end,
	Inner = <<Fontlist:16/little, 0:16>>,
	Size = byte_size(Inner) + 4,
	<<14:16/little, Size:16/little, Inner/binary>>;

encode_tscap(#ts_cap_pointer{flags = Flags, cache_size = CacheSize}) ->
	Color = case lists:member(color, Flags) of true -> 1; _ -> 0 end,
	Inner = <<Color:16/little, 0:16, CacheSize:16/little>>,
	Size = byte_size(Inner) + 4,
	<<8:16/little, Size:16/little, Inner/binary>>;

encode_tscap(#ts_cap_input{flags=Flags, kbd_layout=Layout, kbd_type=Type, kbd_sub_type=SubType, kbd_fun_keys=FunKeys, ime=Ime}) ->
	Scancodes = case lists:member(scancodes, Flags) of true -> 1; _ -> 0 end,
	MouseX = case lists:member(mousex, Flags) of true -> 1; _ -> 0 end,
	FastPath = case lists:member(fastpath, Flags) of true -> 1; _ -> 0 end,
	Unicode = case lists:member(unicode, Flags) of true -> 1; _ -> 0 end,
	FastPath2 = case lists:member(fastpath2, Flags) of true -> 1; _ -> 0 end,
	ImeBin = zero_pad(Ime, 64),

	<<InputFlags:16/big>> = <<0:10, FastPath2:1, Unicode:1, FastPath:1, MouseX:1, 0:1, Scancodes:1>>,

	Inner = <<InputFlags:16/little, 0:16, Layout:32/little, Type:32/little, SubType:32/little, FunKeys:32/little, ImeBin/binary>>,
	Size = byte_size(Inner) + 4,
	<<13:16/little, Size:16/little, Inner/binary>>;

encode_tscap({Type, Bin}) ->
	Size = byte_size(Bin) + 4,
	<<Type:16/little, Size:16/little, Bin/binary>>.

decode_ts_demand(Chan, Bin) ->
	case Bin of
		<<ShareId:32/little, _:16, SDLen:16/little, Len:16/little, Rest/binary>> ->
			case Rest of
				<<SD:SDLen/binary-unit:8, N:16/little, _:16, CapsBin/binary>> ->
					RealLen = byte_size(CapsBin) + 4,
					if (Len == RealLen) or (Len + 4 == RealLen) ->
						Caps = decode_tscaps(N, CapsBin),
						{ok, #ts_demand{channel = Chan, shareid = ShareId, sourcedesc = SD, capabilities = Caps}};
					true ->
						{error, badlength}
					end;
				_ ->
					{error, badpacket}
			end;
		_ ->
			{error, badpacket}
	end.

encode_ts_demand(#ts_demand{shareid = ShareId, sourcedesc = SourceDesc, capabilities = Caps}) ->
	N = length(Caps),
	CapsBin = lists:foldl(fun(Next, Bin) -> NextBin = encode_tscap(Next), <<Bin/binary, NextBin/binary>> end, <<>>, Caps),
	SDLen = byte_size(SourceDesc) + 1,
	Sz = byte_size(CapsBin) + 4,
	<<ShareId:32/little, SDLen:16/little, Sz:16/little, SourceDesc/binary, 0, N:16/little, 0:16, CapsBin/binary, 0:32>>.

decode_ts_confirm(Chan, Bin) ->
	case Bin of
		<<ShareId:32/little, _:16, SDLen:16/little, Len:16/little, Rest/binary>> ->
			case Rest of
				<<SD:SDLen/binary-unit:8, N:16/little, _:16, CapsBin/binary>> ->
					RealLen = byte_size(CapsBin) + 4,
					if (Len == RealLen) ->
						Caps = decode_tscaps(N, CapsBin),
						{ok, #ts_confirm{channel = Chan, shareid = ShareId, sourcedesc = SD, capabilities = Caps}};
					true ->
						{error, badlength}
					end;
				_ ->
					{error, badpacket}
			end;
		_ ->
			{error, badpacket}
	end.

encode_ts_confirm(#ts_confirm{}) ->
	<<>>.

decode_ts_deactivate(Chan, Bin) ->
	{ok, #ts_deactivate{channel = Chan}}.

encode_ts_deactivate(#ts_confirm{}) ->
	<<>>.

decode_ts_redir(Chan, Bin) ->
	{ok, #ts_redir{channel = Chan}}.

encode_ts_redir(#ts_confirm{}) ->
	<<>>.

decode_sharedata(Chan, Bin) ->
	case Bin of
		<<ShareId:32/little, _:8, Priority:8, Length:16/little, PduType:8, Flags:4, CompType:4, CompressedLength:16/little, Rest/binary>> ->
			<<Flushed:1, AtFront:1, Compressed:1, _:1>> = <<Flags:4>>,
			FlagAtoms = if Flushed == 1 -> [flushed]; true -> [] end ++
						if AtFront == 1 -> [at_front]; true -> [] end ++
						if Compressed == 1 -> [compressed]; true -> [] end,
			Prio = case Priority of 1 -> low; 2 -> medium; 4 -> high; _ -> unknown end,
			CompTypeAtom = case CompType of 0 -> '8k'; 1 -> '64k'; 2 -> 'rdp6'; 3 -> 'rdp61'; _ -> 'unknown' end,
			RealSize = byte_size(Rest),
			if (Compressed == 1) and (CompressedLength == RealSize) ->
				{ok, #ts_sharedata{channel = Chan, shareid = ShareId, priority = Prio, flags = FlagAtoms, comptype = CompTypeAtom, data = {PduType, Rest}}};
			(Compressed == 0) and (Length == RealSize) ->
				Inner = case PduType of
					%16#02 -> decode_update(Rest);
					31 -> decode_ts_sync(Rest);
					20 -> decode_ts_control(Rest);
					39 -> decode_ts_fontlist(Rest);
					40 -> decode_ts_fontmap(Rest);
					28 -> decode_ts_input(Rest);
					_ -> {PduType, Rest}
				end,
				{ok, #ts_sharedata{channel = Chan, shareid = ShareId, priority = Prio, flags = FlagAtoms, data = Inner}};
			true ->
				{error, {badlength, Length, CompressedLength, RealSize}}
			end;
		_ ->
			{error, badpacket}
	end.

encode_sharedata(#ts_sharedata{shareid = ShareId, data = Pdu, priority = Prio, comptype = CompTypeAtom, flags = FlagAtoms}) ->
	{PduType, Inner} = case Pdu of
		%#ts_update{} -> {16#02, encode_ts_update(Pdu)};
		#ts_sync{} -> {31, encode_ts_sync(Pdu)};
		#ts_control{} -> {20, encode_ts_control(Pdu)};
		#ts_fontlist{} -> {39, encode_ts_fontlist(Pdu)};
		#ts_fontmap{} -> {40, encode_ts_fontmap(Pdu)};
		#ts_update_orders{} -> {2, encode_ts_update(Pdu)};
		{N, Data} -> {N, Data}
	end,
	CompType = case CompTypeAtom of '8k' -> 0; '64k' -> 1; 'rdp6' -> 2; 'rdp61' -> 3; _ -> 4 end,
	Priority = case Prio of low -> 1; medium -> 2; high -> 4; _ -> 0 end,

	Flushed = case lists:member(flushed, FlagAtoms) of true -> 1; _ -> 0 end,
	AtFront = case lists:member(at_front, FlagAtoms) of true -> 1; _ -> 0 end,
	Compressed = case lists:member(compressed, FlagAtoms) of true -> 1; _ -> 0 end,
	<<Flags:4>> = <<Flushed:1, AtFront:1, Compressed:1, 0:1>>,

	Size = byte_size(Inner) + 6 + 12,
	<<ShareId:32/little, 0:8, Priority:8, Size:16/little, PduType:8, Flags:4, CompType:4, Size:16/little, Inner/binary>>.

decode_ts_sync(Bin) ->
	<<1:16/little, User:16/little>> = Bin,
	#ts_sync{user = User}.

encode_ts_sync(#ts_sync{user = User}) ->
	<<1:16/little, User:16/little>>.

decode_ts_control(Bin) ->
	<<Action:16/little, GrantId:16/little, ControlId:32/little>> = Bin,
	ActionAtom = case Action of 1 -> request; 2 -> granted; 3 -> detach; 4 -> cooperate end,
	#ts_control{action = ActionAtom, grantid = GrantId, controlid = ControlId}.

encode_ts_control(#ts_control{action = ActionAtom, grantid = GrantId, controlid = ControlId}) ->
	Action = case ActionAtom of request -> 1; granted -> 2; detach -> 3; cooperate -> 4 end,
	<<Action:16/little, GrantId:16/little, ControlId:32/little>>.

decode_ts_fontlist(Bin) ->
	#ts_fontlist{}.

encode_ts_fontlist(#ts_fontlist{}) ->
	<<0:16, 0:16, 3:16/little, 50:16/little>>.

decode_ts_fontmap(Bin) ->
	#ts_fontmap{}.

encode_ts_fontmap(#ts_fontmap{}) ->
	<<0:16, 0:16, 3:16/little, 4:16/little>>.

encode_ts_update(Rec) ->
	{Type, Inner} = case Rec of
		#ts_update_orders{} -> {0, encode_ts_update_orders(Rec)}
	end,
	<<Type:16/little, Inner/binary>>.

ceil(X) ->
    T = erlang:trunc(X),
    case (X - T) of
        Neg when Neg < 0 -> T;
        Pos when Pos > 0 -> T + 1;
        _ -> T
    end.

encode_ts_order_head(Type, Fields, Flags) ->
	Standard = 1,
	TypeChange = 1,
	Bounds = 0,
	Delta = case lists:member(delta, Flags) of true -> 1; _ -> 0 end,
	ZeroBoundsDelta = 0,
	FieldZeros = 0,

	<<ControlFlags:8>> = <<FieldZeros:2, ZeroBoundsDelta:1, Delta:1, TypeChange:1, Bounds:1, 0:1, Standard:1>>,
	FieldBits = ceil((length(Fields) + 1.0) / 8.0) * 8,
	Shortfall = FieldBits - length(Fields),
	FieldShort = lists:foldl(fun(Next, Bin) ->
		<<Next:1, Bin/bitstring>>
	end, <<>>, Fields),
	<<FieldN:FieldBits/big>> = <<0:Shortfall, FieldShort/bitstring>>,

	<<ControlFlags:8, Type:8, FieldN:FieldBits/little>>.

encode_ts_order(#ts_order_opaquerect{flags = Flags, dest=[X,Y], size=[W,H], color=[R,G,B]}) ->
	Inner = <<X:16/little-signed, Y:16/little-signed, W:16/little-signed, H:16/little-signed, R:8, G:8, B:8>>,
	Head = encode_ts_order_head(16#0a, [1,1,1,1,1,1,1], Flags),
	<<Head/binary, Inner/binary>>;
encode_ts_order(#ts_order_srcblt{flags = Flags, dest = [X1,Y1], src = [X2, Y2], size = [W,H], rop = Rop}) ->
	Inner = <<X1:16/little-signed, Y1:16/little-signed, W:16/little-signed, H:16/little-signed, Rop:8, X2:16/little, Y2:16/little>>,
	Head = encode_ts_order_head(16#02, [1,1,1,1,1,1,1], Flags),
	<<Head/binary, Inner/binary>>;
encode_ts_order(#ts_order_line{start = [X1,Y1], finish = [X2,Y2], flags = Flags, rop = Rop, color = [R,G,B]}) ->
	Inner = <<X1:16/little-signed, Y1:16/little-signed, X2:16/little-signed, Y2:16/little-signed, Rop:8, R:8, G:8, B:8>>,
	Head = encode_ts_order_head(16#09, [0,1,1,1,1,0,1,0,0,1], Flags),
	<<Head/binary, Inner/binary>>.

encode_ts_update_orders(#ts_update_orders{orders = Orders}) ->
	OrdersBin = lists:foldl(fun(Next, Bin) ->
		Encode = encode_ts_order(Next),
		<<Bin/binary, Encode/binary>>
	end, <<>>, Orders),
	N = length(Orders),
	<<0:16, N:16/little, 0:16, OrdersBin/binary>>.

decode_ts_inpevt(16#0000, Bin) ->
	<<_:16, Flags:16/little, Rest/binary>> = Bin,
	<<_:12, KanaLock:1, CapsLock:1, NumLock:1, ScrollLock:1>> = <<Flags:16/big>>,
	FlagAtoms = if KanaLock == 1 -> [kanalock]; true -> [] end ++
				if CapsLock == 1 -> [capslock]; true -> [] end ++
				if NumLock == 1 -> [numlock]; true -> [] end ++
				if ScrollLock == 1 -> [scrolllock]; true -> [] end,
	{#ts_inpevt_sync{flags=FlagAtoms}, Rest};

decode_ts_inpevt(16#0004, Bin) ->
	<<Flags:16/little, KeyCode:16/little, _:16, Rest/binary>> = Bin,
	<<Release:1, AlreadyDown:1, _:5, Extended:1, _:8>> = <<Flags:16/big>>,
	Action = if Release == 1 -> up; true -> down end,
	FlagAtoms = if AlreadyDown == 1 -> [already_down]; true -> [] end ++
				if Extended == 1 -> [extended]; true -> [] end,
	{#ts_inpevt_key{code = KeyCode, action = Action, flags = FlagAtoms}, Rest};

decode_ts_inpevt(16#0005, Bin) ->
	<<Flags:16/little, KeyCode:16/little, _:16, Rest/binary>> = Bin,
	<<Release:1, _:15>> = <<Flags:16/big>>,
	Action = if Release == 1 -> up; true -> down end,
	{#ts_inpevt_unicode{code = KeyCode, action = Action}, Rest};

decode_ts_inpevt(16#8001, Bin) ->
	<<Flags:16/little, X:16/little, Y:16/little, Rest/binary>> = Bin,
	<<Down:1, Button3:1, Button2:1, Button1:1, Move:1, _:1, Wheel:1, WheelNegative:1, Clicks:8>> = <<Flags:16/big>>,
	if Wheel == 1 ->
		SignedClicks = if WheelNegative == 1 -> (0 - Clicks); true -> Clicks end,
		{#ts_inpevt_wheel{point = [X,Y], clicks = SignedClicks}, Rest};
	true ->
		Action = if Move == 1 -> move; Down == 1 -> down; true -> up end,
		Buttons = if Button3 == 1 -> [3]; true -> [] end ++
				  if Button2 == 1 -> [2]; true -> [] end ++
				  if Button1 == 1 -> [1]; true -> [] end,
		{#ts_inpevt_mouse{point = [X,Y], action = Action, buttons = Buttons}, Rest}
	end;

decode_ts_inpevt(16#8002, Bin) ->
	<<Flags:16/little, X:16/little, Y:16/little, Rest/binary>> = Bin,
	<<Down:1, _:13, Button5:1, Button4:1>> = <<Flags:16/big>>,
	Action = if Down == 1 -> down; true -> up end,
	Buttons = if Button4 == 1 -> [4]; true -> [] end ++
			  if Button5 == 1 -> [5]; true -> [] end,
	{#ts_inpevt_mouse{point = [X,Y], action = Action, buttons = Buttons}, Rest};

decode_ts_inpevt(_, _) ->
	error(not_implemented).

decode_ts_inpevts(_, <<>>) -> [];
decode_ts_inpevts(0, _) -> [];
decode_ts_inpevts(N, Bin) ->
	<<Time:32/little, Type:16/little, Rest/binary>> = Bin,
	{Next, Rem} = decode_ts_inpevt(Type, Rest),
	[Next | decode_ts_inpevts(N - 1, Rem)].

decode_ts_input(Bin) ->
	<<N:16/little, _:16, Evts/binary>> = Bin,
	#ts_input{events = decode_ts_inpevts(N, Evts)}.

encode_basic(Rec) ->
	SecFlags = element(2, Rec),
	{Type, Inner} = case Rec of
		#ts_security{} -> {security, encode_ts_security(Rec)};
		#ts_license_vc{} -> {license, encode_ts_license_vc(Rec)}
	end,
	Flags = encode_sec_flags({Type, SecFlags}),
	{ok, <<Flags:16/little, 0:16, Inner/binary>>}.

decode_basic(Bin) ->
	case Bin of
		<<Flags:16/little, _:16, Rest/binary>> ->
			case decode_sec_flags(Flags) of
				{security, Fl} -> decode_ts_security(Fl, Rest);
				{info, Fl} -> decode_ts_info(Fl, Rest);
				_ -> {error, badpacket}
			end;
		_ ->
			{error, badpacket}
	end.

encode_ts_security(#ts_security{random = Random}) ->
	Len = byte_size(Random),
	<<Len:32/little, Random/binary>>.

encode_ts_license_vc(#ts_license_vc{}) ->
	Inner = <<16#7:32/little, 16#2:32/little, 16#04:16/little, 0:16>>,
	Len = byte_size(Inner) + 4,
	<<16#ff, 16#83, Len:16/little, Inner/binary>>.

decode_ts_security(Fl, Bin) ->
	case Bin of
		<<Length:32/little, Rest/binary>> ->
			RealSize = byte_size(Rest),
			if Length == RealSize ->
				{ok, #ts_security{secflags = Fl, random = Rest}};
			true ->
				{error, badlength}
			end;
		_ ->
			{error, badpacket}
	end.

decode_ts_info(Fl, Bin) ->
	case Bin of
		<<CodePage:32/little, Flags:32/little, DomainLen:16/little, UserNameLen:16/little, PasswordLen:16/little, ShellLen:16/little, WorkDirLen:16/little, Rest/binary>> ->

			<<_:10, VideoDisable:1, AudioCapture:1, SavedCreds:1, NoAudio:1, SmartcardPin:1, MouseWheel:1, LogonErrors:1, Rail:1, ForceEncrypt:1, RemoteConsoleAudio:1, CompLevel:4, WindowsKey:1, Compression:1, LogonNotify:1, MaximizeShell:1, Unicode:1, AutoLogon:1, DisableSalute:1, Mouse:1>> = <<Flags:32/big>>,
			FlagAtoms = if VideoDisable == 1 -> [novideo]; true -> [] end ++
						if AudioCapture == 1 -> [audio_in]; true -> [] end ++
						if SavedCreds == 1 -> [saved_creds]; true -> [] end ++
						if NoAudio == 1 -> [noaudio]; true -> [] end ++
						if SmartcardPin == 1 -> [smartcard_pin]; true -> [] end ++
						if MouseWheel == 1 -> [mouse_wheel]; true -> [] end ++
						if LogonErrors == 1 -> [logon_errors]; true -> [] end ++
						if Rail == 1 -> [rail]; true -> [] end ++
						if ForceEncrypt == 1 -> [force_encrypt]; true -> [] end ++
						if RemoteConsoleAudio == 1 -> [remote_console_audio]; true -> [] end ++
						if WindowsKey == 1 -> [windows_key]; true -> [] end ++
						if Compression == 1 -> [compression]; true -> [] end ++
						if LogonNotify == 1 -> [logon_notify]; true -> [] end ++
						if MaximizeShell == 1 -> [maximize_shell]; true -> [] end ++
						if Unicode == 1 -> [unicode]; true -> [] end ++
						if AutoLogon == 1 -> [autologon]; true -> [] end ++
						if DisableSalute == 1 -> [disable_salute]; true -> [] end ++
						if Mouse == 1 -> [mouse]; true -> [] end,
			CompLevelAtom = case CompLevel of
				16#0 -> '8k';
				16#1 -> '64k';
				16#2 -> 'rdp6';
				16#3 -> 'rdp61';
				_ -> unknown
			end,

			case Rest of
				<<Domain:DomainLen/binary-unit:8, 0:8, UserName:UserNameLen/binary-unit:8, 0:8, Password:PasswordLen/binary-unit:8, 0:8, Shell:ShellLen/binary-unit:8, 0:8, WorkDir:WorkDirLen/binary-unit:8, Rest2/binary>> ->
					{ok, #ts_info{secflags = Fl, codepage = CodePage, flags = FlagAtoms, compression = CompLevelAtom, domain = Domain, username = UserName, password = Password, shell = Shell, workdir = WorkDir}};
				_ ->
					{error, badlength}
			end;
		_ ->
			{error, badpacket}
	end.
