king_moves(Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :- !,
	traverse_diagonals_for_king(Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag).

traverse_diagonals_for_king(Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :-
	diagonal_traversal_ops(Ops), 
	traverse_diagonals_for_king(Ops, Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag).

traverse_diagonals_for_king([], _Color, _X, _Y, _BoardRows, KillsResultTail, KillsResultTail, MovesResultTail, MovesResultTail, _DuplexForcedKillFlag) :- !.
traverse_diagonals_for_king([TraversalOp|Ops], Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :- !,
	traverse_diagonal_for_king(TraversalOp, Color, XKing, YKing, BoardRows, KillsTail, NewKillsTail, MovesTail, NewMovesTail, DuplexForcedKillFlag),
	traverse_diagonals_for_king(Ops, Color, XKing, YKing, BoardRows, NewKillsTail, KillsResultTail, NewMovesTail, MovesResultTail, DuplexForcedKillFlag).
	
traverse_diagonal_for_king(TraversalOp, Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :-
	apply_traversal_op(TraversalOp, XKing, YKing, NextX, NextY),
	traverse_diagonal_for_king(NextX, NextY, TraversalOp, Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, 'CONTINUE', DuplexForcedKillFlag).

traverse_diagonal_for_king(AtX, AtY, _TraversalOp, _Color, _X, _Y, _BoardRows, KillsResultTail, KillsResultTail, MovesResultTail, MovesResultTail, ContinuationFlag, DuplexForcedKillFlag) :-
	not(continue_diagonal_traversal(ContinuationFlag, AtX, AtY, DuplexForcedKillFlag)), !.
traverse_diagonal_for_king(AtX, AtY, TraversalOp, Color, XKing, YKing, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, 'CONTINUE', DuplexForcedKillFlag) :- 
	board_rows_field_state(AtX, AtY, BoardRows, XYState),
	check_piece_for_king(TraversalOp, AtX, AtY, XYState, XKing, YKing, Color, BoardRows, KillsTail, NewKillsTail, MovesTail, NewMovesTail, NewContinuationFlag, DuplexForcedKillFlag),
	apply_traversal_op(TraversalOp, AtX, AtY, NextX, NextY), !,
	traverse_diagonal_for_king(NextX, NextY, TraversalOp, Color, XKing, YKing, BoardRows, NewKillsTail, KillsResultTail, NewMovesTail, MovesResultTail, NewContinuationFlag, DuplexForcedKillFlag).

% stop traversing if ContinuationFlag == 'BREAK'
continue_diagonal_traversal('BREAK', _X, _Y, _DuplexForcedKillFlag) :- !, fail.
% if we found a kill there is no sense in checking the edge of the board
% (anything on the edge of the board cannot be killed)
continue_diagonal_traversal('CONTINUE', X, Y, DuplexForcedKillFlag) :- 
	DuplexForcedKillFlag == 'KILL', !,
	X < 8, X > 1, Y < 8, Y > 1.
continue_diagonal_traversal('CONTINUE', X, Y, _DuplexForcedKillFlag) :- 
	X =< 8, X >= 1, Y =< 8, Y >= 1.

% stop looking at the diagonal if we meet our own piece
check_piece_for_king(_TraversalOp, _AtX, _AtY, XYState, _XKing, _YKing, Color, _BoardRows, KillsResultTail, KillsResultTail, MovesResultTail, MovesResultTail, 'BREAK', _DuplexForcedKillFlag) :-
	state_for_color(Color, XYState, _Type), !.
check_piece_for_king(_TraversalOp, AtX, AtY, XYState, XKing, YKing, _Color, _BoardRows, KillsResultTail, KillsResultTail, MovesTail, MovesResultTail, 'CONTINUE', DuplexForcedKillFlag) :-
	void_state(XYState), !,
	adjust_moves_for_king(XKing, YKing, AtX, AtY, DuplexForcedKillFlag, MovesTail, MovesResultTail).
% stop looking at the diagonal if we meet an opponent
check_piece_for_king(TraversalOp, XDead, YDead, DeadState, XKing, YKing, Color, BoardRows, KillsTail, KillsResultTail, MovesResultTail, MovesResultTail, 'BREAK', DuplexForcedKillFlag) :- 
	state_for_other_color(Color, DeadState, DeadPieceType), !,
	% find target positions up to first void after dead piece:
	apply_traversal_op(TraversalOp, XDead, YDead, XAfterKill, YAfterKill),
	collect_king_kills_on_diagonal(XAfterKill, YAfterKill, TraversalOp, XDead, YDead, DeadPieceType, XKing, YKing, Color, BoardRows, KillsTail, KillsResultTail, 'CONTINUE', DuplexForcedKillFlag).

collect_king_kills_on_diagonal(XAfterKill, YAfterKill, _TrvOp, _XDead, _YDead, _DeadPieceType, _XKing, _YKing, _Color, _BoardRows, KillsResultTail, KillsResultTail, ContinuationFlag, _DuplexForcedKillFlag) :- 
	not(continue_collecting_kills(ContinuationFlag, XAfterKill, YAfterKill)), !.
collect_king_kills_on_diagonal(XAfterKill, YAfterKill, TraversalOp, XDead, YDead, DeadPieceType, XKing, YKing, Color, BoardRows, KillsTail, KillsResultTail, _PrevContinuationFlag, DuplexForcedKillFlag) :-
	board_rows_field_state(XAfterKill, YAfterKill, BoardRows, XYAfterState),
	check_legal_kill_for_king(XKing, YKing, XDead, YDead, XAfterKill, YAfterKill, XYAfterState, DeadPieceType, KillsTail, NewKillsTail, ContinuationFlag, DuplexForcedKillFlag),
	apply_traversal_op(TraversalOp, XAfterKill, YAfterKill, NewXAfterKill, NewYAfterKill),
	collect_king_kills_on_diagonal(NewXAfterKill, NewYAfterKill, TraversalOp, XDead, YDead, DeadPieceType, XKing, YKing, Color, BoardRows, NewKillsTail, KillsResultTail, ContinuationFlag, DuplexForcedKillFlag).

continue_collecting_kills('BREAK', _ToX, _ToY) :- 
	!, fail.
continue_collecting_kills(_XYAfterState, ToX, ToY) :- 
	ToX >= 1,
	ToX =< 8,
	ToY >= 1,
	ToY =< 8.

check_legal_kill_for_king(XKing, YKing, XDead, YDead, XAfterKill, YAfterKill, 0, DeadPieceType, [move(king, from(XKing, YKing), to(XAfterKill, YAfterKill), effects(move_effect('NIL'), kill(XDead, YDead, DeadPieceType), chain_effect('NIL'))) | KillsTail], KillsTail, 'CONTINUE', 'KILL') :- !.
check_legal_kill_for_king(_XO, _YO, _XDead, _YDead, _XAfterKill, _YAfterKill, _X1Y1State, _DeadPieceType, KillsTail, KillsTail, 'BREAK', _DuplexForcedKillFlag) :- !.
	% X1Y1State \= 0, !.

% avoid consing while in KILL mode:
adjust_moves_for_king(_XKing, _YKing, _X, _Y, DuplexForcedKillFlag, MovesResultTail, MovesResultTail) :-
	DuplexForcedKillFlag == 'KILL', !.
adjust_moves_for_king(XKing, YKing, X, Y, _DuplexForcedKillFlag, [move(king, from(XKing, YKing), to(X, Y), effects(move_effect('NIL'), kill('NIL'), chain_effect('NIL'))) | MovesTail], MovesTail).

