pawn_moves(Color, X, Y, BoardRows, KillsTail, KillMovesResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :- 
	!, 
	findall((X1, Y1), immediately_around_pawn(X, Y, X1, Y1, DuplexForcedKillFlag), SurroundingPieces),
	check_surrounding_pieces_for_pawn(X, Y, Color, SurroundingPieces, BoardRows, KillsTail, KillMovesResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag).
	
check_surrounding_pieces_for_pawn(_, _, _, [], _, KillMovesTail, KillMovesTail, MovesTail, MovesTail, _NoForcedKill) :- !.
check_surrounding_pieces_for_pawn(XPawn, YPawn, Color, [(X1, Y1) | SurroundingPieces], BoardRows, KillMovesTail, KillMovesResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :-
	check_surrounding_piece_for_pawn(XPawn, YPawn, X1, Y1, Color, BoardRows, KillMovesTail, KillMovesTailAfterCheck, MovesTail, MovesTailAfterCheck, DuplexForcedKillFlag), !,
	check_surrounding_pieces_for_pawn(XPawn, YPawn, Color, SurroundingPieces, BoardRows, KillMovesTailAfterCheck, KillMovesResultTail, MovesTailAfterCheck, MovesResultTail, DuplexForcedKillFlag).

check_surrounding_piece_for_pawn(XPawn, YPawn, X, Y, Color, BoardRows, KillMovesTail, KillMovesResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :-
	board_rows_field_state(X, Y, BoardRows, XYState),
	check_piece_for_pawn(XPawn, YPawn, X, Y, XYState, Color, BoardRows, KillMovesTail, KillMovesResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag), !.

check_piece_for_pawn(XPawn, YPawn, XDead, YDead, XYState, Color, BoardRows, KillMovesTail, KillMovesResultTail, MovesResultTail, MovesResultTail, DuplexForcedKillFlag) :-
	state_for_other_color(Color, XYState, XYPieceType),
	% calculate target position:
	leap_over_coords_for_pawn(XPawn, YPawn, XDead, YDead, X1, Y1), !,
	board_rows_field_state(X1, Y1, BoardRows, X1Y1State),
	% register kill depending on vacancy of X1Y1State:
	check_legal_kill_for_pawn(Color, XPawn, YPawn, XDead, YDead, X1, Y1, X1Y1State, XYPieceType, KillMovesTail, KillMovesResultTail, DuplexForcedKillFlag).
check_piece_for_pawn(XPawn, YPawn, X, Y, XYState, Color, _BoardRows, KillMovesTail, KillMovesTail, MovesTail, NewMovesTail, DuplexForcedKillFlag) :- 
	void_state(XYState), !,
	adjust_moves_for_pawn(Color, XPawn, YPawn, X, Y, MovesTail, NewMovesTail, DuplexForcedKillFlag).
	%forward_move_for_pawn(Color, XPawn, YPawn, X, Y), !,
	%build_pawn_move(Color, XPawn, YPawn, X, Y, PawnMove).
check_piece_for_pawn(_, _, _, _, _XYState, _Color, _, KillMovesTail, KillMovesTail, MovesTail, MovesTail, _NoForcedKill).

check_legal_kill_for_pawn(Color, XPawn, YPawn, XDead, YDead, X1, Y1, 0, DeadPieceType, [move(pawn, from(XPawn, YPawn), to(X1, Y1), effects(move_effect('CROWN'), kill(XDead, YDead, DeadPieceType), chain_effect('NIL'))) | KillMovesTail], KillMovesTail, 'KILL') :- is_crowning_row(Color, Y1), !.
check_legal_kill_for_pawn(_Color, XPawn, YPawn, XDead, YDead, X1, Y1, 0, DeadPieceType, [move(pawn, from(XPawn, YPawn), to(X1, Y1), effects(move_effect('NIL'), kill(XDead, YDead, DeadPieceType), chain_effect('NIL'))) | KillMovesTail], KillMovesTail, 'KILL') :- !.
check_legal_kill_for_pawn(_Color, _XO, _YO, _XDead, _YDead, _X1, _Y1, _X1Y1State, _DeadPieceType, KillMovesTail, KillMovesTail, _NoForcedKill) :- !.
	% X1Y1State \= 0, !.

% avoid consing while in KILL mode
adjust_moves_for_pawn(_Color, _XPawn, _YPawn, _X, _Y, MovesTail, MovesTail, DuplexForcedKillFlag) :- DuplexForcedKillFlag == 'KILL', !.
adjust_moves_for_pawn(Color, XPawn, YPawn, X, Y, [PawnMove|MovesTail], MovesTail, _DuplexForcedKillFlag) :-
	% can only move in one direction as a pawn!
	forward_move_for_pawn(Color, XPawn, YPawn, X, Y), !,
	build_pawn_move(Color, XPawn, YPawn, X, Y, PawnMove).
adjust_moves_for_pawn(_Color, _XPawn, _YPawn, _X, _Y, MovesTail, MovesTail, _DuplexForcedKillFlag).

build_pawn_move(Color, XPawn, YPawn, X, Y, move(pawn, from(XPawn, YPawn), to(X, Y), effects(move_effect('CROWN'), kill('NIL'), chain_effect('NIL')))) :-
	is_crowning_row(Color, Y), !.
build_pawn_move(_Color, XPawn, YPawn, X, Y, move(pawn, from(XPawn, YPawn), to(X, Y), effects(move_effect('NIL'), kill('NIL'), chain_effect('NIL')))).
	
% black pawn moves downwards by default
forward_move_for_pawn(mustad, XPawn, YPawn, X, Y) :- 
	X is XPawn + 1, !, 
	Y is YPawn - 1.
forward_move_for_pawn(mustad, XPawn, YPawn, X, Y) :- 
	X is XPawn - 1, 
	Y is YPawn - 1, !.
% white pawn moves upwards by default
forward_move_for_pawn(valged, XPawn, YPawn, X, Y) :- 
	X is XPawn - 1, !,
	Y is YPawn + 1.
forward_move_for_pawn(valged, XPawn, YPawn, X, Y) :- 
	X is XPawn + 1,
	Y is YPawn + 1, !.

% if a kill is found, you need not check the edge of the board:
immediately_around_pawn(X, Y, X1, Y1, DuplexForcedKillFlag) :-
	DuplexForcedKillFlag \== 'KILL', !,
	immediately_around_pawn_with_edge(X, Y, X1, Y1).
immediately_around_pawn(X, Y, X1, Y1, _DuplexForcedKillFlag) :-
	immediately_around_pawn_skip_edge(X, Y, X1, Y1).

immediately_around_pawn_with_edge(X, Y, X1, Y1) :-
	X1 is X + 1,
	X1 =< 8,
	Y1 is Y + 1,
	Y1 =< 8.
immediately_around_pawn_with_edge(X, Y, X1, Y1) :-
	X1 is X + 1,
	X1 =< 8,
	Y1 is Y - 1,
	Y1 >= 1.
immediately_around_pawn_with_edge(X, Y, X1, Y1) :-
	X1 is X - 1,
	X1 >= 1,
	Y1 is Y + 1,
	Y1 =< 8.
immediately_around_pawn_with_edge(X, Y, X1, Y1) :-
	X1 is X - 1,
	X1 >= 1,
	Y1 is Y - 1,
	Y1 >= 1.

immediately_around_pawn_skip_edge(X, Y, X1, Y1) :-
	X1 is X + 1,
	X1 < 8,
	Y1 is Y + 1,
	Y1 < 8.
immediately_around_pawn_skip_edge(X, Y, X1, Y1) :-
	X1 is X + 1,
	X1 < 8,
	Y1 is Y - 1,
	Y1 > 1.
immediately_around_pawn_skip_edge(X, Y, X1, Y1) :-
	X1 is X - 1,
	X1 > 1,
	Y1 is Y + 1,
	Y1 < 8.
immediately_around_pawn_skip_edge(X, Y, X1, Y1) :-
	X1 is X - 1,
	X1 > 1,
	Y1 is Y - 1,
	Y1 > 1.

% target position for pawn when killing
leap_over_coords_for_pawn(XPawn, YPawn, X1, Y1, X2, Y2) :- !,
	X2 is (X1 - XPawn) + X1,
	X2 >= 1, X2 =< 8,
	Y2 is (Y1 - YPawn) + Y1,
	Y2 >= 1, Y2 =< 8.