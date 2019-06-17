apply_move(Color, move(What, from(Fx, Fy), To, effects(MoveEffect, Kill, _ChainEffect)), BoardTree, ResultTree) :- 
	determine_state(Color, What, FromState),
	move_effect_result(MoveEffect, FromState, NewState),
	move(NewState, from(Fx, Fy), To, BoardTree, BoardTreeBeforeKill),
	apply_kill_effect(Kill, BoardTreeBeforeKill, ResultTree).
determine_state(Color, king, State) :-
	color_king(Color, State).
determine_state(Color, pawn, State) :-
	color_pawn(Color, State).

move_effect_result(move_effect('NIL'), State, State).
move_effect_result(move_effect('CROWN'), OldState, NewState) :-
	color_pawn(Color, OldState),
	color_king(Color, NewState), !.

move(State, from(Fx, Fy), to(Tx, Ty), BoardTree, Result) :-
	replace_pos_state(Fx, Fy, 0, BoardTree, BoardTree1),
	replace_pos_state(Tx, Ty, State, BoardTree1, Result).

replace_pos_state(X, Y, State, BoardTree, NewBoardTree) :-
	%add_avl(BoardTree, (X, Y, State), NewBoardTree).
	replace_avl(BoardTree, (X, Y, State), NewBoardTree).

apply_kill_effect(kill('NIL'), Result, Result).
apply_kill_effect(kill(Dx, Dy, _Type), BoardTree, Result) :-
	replace_pos_state(Dx, Dy, 0, BoardTree, Result).