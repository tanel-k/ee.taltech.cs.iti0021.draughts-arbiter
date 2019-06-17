eval_choose_master(D, TimeToThink, Moves, InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best) :-
	statistics(walltime, [TimeSinceStart, _TimeSinceLastCall]),
	CutOffTime is TimeSinceStart + TimeToThink,
	eval_choose_switch(D, CutOffTime, Moves, InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best).

eval_choose_switch(D, CutOffTime, kills(Kills), InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best) :-
	eval_choose_slave(kill, D, CutOffTime, Kills, InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best).
eval_choose_switch(D, CutOffTime, moves(Moves), InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best) :-
	eval_choose_slave(move, D, CutOffTime, Moves, InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best).

%------------------- eval choose loop -------------------%
eval_choose_slave(_MoveType, _D, _CutOffTime, [], _InitialColor, _Color, _BoardTree, BoardCounters, _MaxMin, (Move, Value), (Move, ValidValue)) :-
	(Value == nil, state_value(BoardCounters, ValidValue)); (ValidValue = Value).
eval_choose_slave(MoveType, D, CutOffTime, [Move|Moves], InitialColor, Color, BoardTree, BoardCounters, MaxMin, Record, Best) :-
	apply_move(Color, Move, BoardTree, NewBoardTree),
	update_board_counters(MoveType, InitialColor, Color, Move, BoardCounters, NewBoardCounters),
	retr_chain_effect(Move, ChainEffect),
	minimax_switch_accd_to_chain_effect(ChainEffect, Color, MaxMin, NextColor, NextMaxMin, StayAtDepth),
	forced_starting_position(Move, ForcedStartingPosition),
	minimax(D, StayAtDepth, CutOffTime, ForcedStartingPosition, InitialColor, NextColor, 
		NewBoardTree, NewBoardCounters, NextMaxMin, _LastMove, Value),
	update_record(MaxMin, Move, Value, Record, NewRecord),
	/*((Record \= NewRecord,
	write('update: '), nl, 
	write('MaxMin = '), write(MaxMin), nl,
	write(Record), write(' -> '), write(NewRecord), nl) ; true),*/
	!,
	eval_choose_slave(MoveType, D, CutOffTime, Moves, InitialColor, Color, BoardTree, BoardCounters, MaxMin, NewRecord, Best).
%------------------- /eval choose loop -------------------%

%------------------- minimax loop -------------------%
minimax(_Depth, _StayAtDepth, CutOffTime, _ForcedStartingPosition, _InitialColor, _Color, _BoardTree, BoardCounters, _MaxMin, _Move, Value) :-
	% cutoff time
	statistics(walltime, [TimeSinceStart, _TimeSinceLastCall]),
	TimeSinceStart >= CutOffTime, !, 
	state_value(BoardCounters, Value).
minimax(_Depth, _StayAtDepth, _CutOffTime, _ForcedStartingPosition, _InitialColor, _Color, _BoardTree, BoardCounters, _MaxMin, _Move, Value) :-
	% terminal node
	game_over(BoardCounters), !,
	state_value(BoardCounters, Value).
minimax(0, _StayAtDepth, _CutOffTime, _ForcedStartingPosition, _InitialColor, _Color, _BoardTree, BoardCounters, _MaxMin, _Move, Value) :-
	% maximum depth
	state_value(BoardCounters, Value).
minimax(D, StayAtDepth, CutOffTime, ForcedStartingPosition, InitialColor, Color, BoardTree, BoardCounters, MaxMin, Move, Value) :-
	D > 0,
	color_pieces(ForcedStartingPosition, Color, BoardTree, ColorPieces),
	color_moves(Color, ColorPieces, BoardTree, Moves),
	((StayAtDepth == no, D1 is D - 1); (D1 is D)),
	((no_more_moves(Moves), state_value(BoardCounters, Value)) ; 
	eval_choose_switch(D1, CutOffTime, Moves, InitialColor, Color, BoardTree, BoardCounters, MaxMin, (nil, nil), (Move, Value))).
%------------------- /minimax loop -------------------%

no_more_moves(kills([])).
no_more_moves(moves([])).

%------------------- current best -------------------%
% immediately replace the Nil move:
update_record(_MaxMin, Move, Value, (nil, nil), (Move, Value)) :- !.

% maximize when MaxMin is positive:
update_record(MaxMin, _Move, Value, (RcdMove, RcdValue), (RcdMove, RcdValue)) :-
	MaxMin > 0, Value =< RcdValue, !.
update_record(MaxMin, Move, Value, (_RcdMove, RcdValue), (Move, Value)) :-
	MaxMin > 0, Value > RcdValue.

% minimize when MaxMin is negative:
update_record(MaxMin, _Move, Value, (RcdMove, RcdValue), (RcdMove, RcdValue)) :-
	MaxMin < 0, Value >= RcdValue, !.
update_record(MaxMin, Move, Value, (_RcdMove, RcdValue), (Move, Value)) :-
	MaxMin < 0, Value < RcdValue.
%------------------- /current best -------------------%

%------------------- forced starting pos. extraction -------------------%
forced_starting_position(move(_What, _From, _To, effects(_MoveEffect, _KillEffect, chain_effect('NIL'))), nil).
forced_starting_position(move(What, _From, to(Tx, Ty), effects(MoveEffect, _KillEffect, chain_effect('WILL CHAIN'))), (Tx, Ty, PieceType)) :-
	det_next_piece_type(What, MoveEffect, PieceType).

% no effect + pawn --> pawn
det_next_piece_type(pawn, move_effect('NIL'), pawn) :- !.
% any effect + king --> king, crown effect + pawn --> king
det_next_piece_type(_Prior, _MoveEffect, king).
%------------------- /forced starting pos. extraction -------------------%
	
%------------------- piece listing logic -------------------%
color_pieces((X, Y, PieceType), _Color, _BoardTree, [(X, Y, PieceType)]).
color_pieces(nil, Color, BoardTree, ColorPiecesForBoard) :-
	color_pieces_for_board(Color, BoardTree, ColorPiecesForBoard).
%------------------- /piece listing logic -------------------%

%------------------ min <-> max switch logic ------------------%
minimax_switch_accd_to_chain_effect(chain_effect('NIL'), Color, MaxMin, NextColor, NextMaxMin, no) :- 
	other_color(Color, NextColor),
	NextMaxMin is -MaxMin.
% chained moves should be handled at the same depth and with the same MaxMin value:
minimax_switch_accd_to_chain_effect(chain_effect('WILL CHAIN'), Color, MaxMin, Color, MaxMin, yes).
%------------------ /min <-> max switch logic ------------------%

% ---------------- board counter update for moves ---------------- %
% just a repositioned piece
update_board_counters(move, _, _, move(_, _, _, effects(move_effect('NIL'), _, _)), BoardCounters, BoardCounters) :- !.
% we crowned a piece
update_board_counters(move, Color, Color, move(_, _, _, effects(move_effect('CROWN'), _, _)), BoardCounters, NewBoardCounters) :- !,
	BoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt),
	NewColorPawnCnt is ColorPawnCnt - 1,
	NewColorKingCnt is ColorKingCnt + 1,
	NewBoardCounters = state_counters(NewColorPawnCnt, NewColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt).
% opponent crowned a piece
update_board_counters(move, Color, OtherColor, move(_, _, _, effects(move_effect('CROWN'), _, _)), BoardCounters, NewBoardCounters) :-
	other_color(Color, OtherColor), !,
	BoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt),
	NewOtherPawnCnt is OtherPawnCnt - 1,
	NewOtherKingCnt is OtherKingCnt + 1,
	NewBoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, NewOtherPawnCnt, NewOtherKingCnt, VoidCnt).
% ---------------- /board counter update for moves ---------------- %

% ---------------- board counter update for kills ---------------- %
% killed an opponent and crowned a piece:
update_board_counters(kill, Color, Color, move(_, _, _, effects(move_effect('CROWN'), kill(_X, _Y, DeadPieceType), _)), BoardCounters, NewBoardCounters) :- !,
	BoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt),
	pawn_or_king_removed(DeadPieceType, OtherPawnCnt, OtherKingCnt, NewOtherPawnCnt, NewOtherKingCnt),
	NewColorPawnCnt is ColorPawnCnt - 1,
	NewColorKingCnt is ColorKingCnt + 1,
	NewVoidCnt is VoidCnt + 1,
	NewBoardCounters = state_counters(NewColorPawnCnt, NewColorKingCnt, NewOtherPawnCnt, NewOtherKingCnt, NewVoidCnt).
% killed an opponent:
update_board_counters(kill, Color, Color, move(_, _, _, effects(move_effect('NIL'), kill(_X, _Y, DeadPieceType), _)), BoardCounters, NewBoardCounters) :- !,
	BoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt),
	pawn_or_king_removed(DeadPieceType, OtherPawnCnt, OtherKingCnt, NewOtherPawnCnt, NewOtherKingCnt),
	NewVoidCnt is VoidCnt + 1,
	NewBoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, NewOtherPawnCnt, NewOtherKingCnt, NewVoidCnt).
% opponent killed one of ours and crowned a piece:
update_board_counters(kill, Color, OtherColor, move(_, _, _, effects(move_effect('CROWN'), kill(_X, _Y, DeadPieceType), _)), BoardCounters, NewBoardCounters) :-
	other_color(Color, OtherColor), !,
	BoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt),
	pawn_or_king_removed(DeadPieceType, ColorPawnCnt, ColorKingCnt, NewColorPawnCnt, NewColorKingCnt),
	NewOtherPawnCnt is OtherPawnCnt - 1,
	NewOtherKingCnt is OtherKingCnt + 1,
	NewVoidCnt is VoidCnt + 1,
	NewBoardCounters = state_counters(NewColorPawnCnt, NewColorKingCnt, NewOtherPawnCnt, NewOtherKingCnt, NewVoidCnt).
% opponent killed one of ours:
update_board_counters(kill, Color, OtherColor, move(_, _, _, effects(move_effect('NIL'), kill(_X, _Y, DeadPieceType), _)), BoardCounters, NewBoardCounters) :-
	other_color(Color, OtherColor), !,
	BoardCounters = state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt),
	pawn_or_king_removed(DeadPieceType, ColorPawnCnt, ColorKingCnt, NewColorPawnCnt, NewColorKingCnt),
	NewVoidCnt is VoidCnt + 1,
	NewBoardCounters = state_counters(NewColorPawnCnt, NewColorKingCnt, OtherPawnCnt, OtherKingCnt, NewVoidCnt).

pawn_or_king_removed(pawn, PawnCnt, KingCnt, NewPawnCnt, KingCnt) :-
	NewPawnCnt is PawnCnt - 1.
pawn_or_king_removed(king, PawnCnt, KingCnt, PawnCnt, NewKingCnt) :-
	NewKingCnt is KingCnt - 1.
% ---------------- /board counter update for kills ---------------- %

game_over(state_counter(0, 0, _OtherPawnCnt, _OtherKingCnt, _VoidCnt)).
game_over(state_counter(_ColorPawnCnt, _ColorKingCnt, 0, 0, _VoidCnt)).

state_value(state_counters(0, 0, _OtherPawnCnt, _OtherKingCnt, _VoidCnt), -1000) :- !. 
state_value(state_counters(_ColorPawnCnt, _ColorKingCnt, 0, 0, _VoidCnt), 1000) :- !. 
state_value(state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, _VoidCnt), Value) :-
	Value is ColorPawnCnt + ColorKingCnt - OtherPawnCnt - OtherKingCnt.

retr_chain_effect(move(_What, _From, _To, effects(_MoveEffect, _KillEffect, ChainEffect)), ChainEffect).