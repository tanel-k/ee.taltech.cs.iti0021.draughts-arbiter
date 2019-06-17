:- module(kabetaja, [iapb134526/3, user_iapb134526/3]).
:- [
		'lib/intelligence/minimax',
		'debug/print',
		'lib/moves/moves'
	].
% breakpoint.

% :- spy(breakpoint).
% TODO: implement alpha-beta pruning

/*
 WARNING: strange behavior
 noticed with high depth levels
*/
time_to_think(9950).
eval_depth(6).
eval_depth_fixed_starting(6).

iapb134526(ColorNr, X, Y) :-
	X == Y, Y == 0, !,
	color_code(ColorNr, Color),
	write('continue?'), get_char(_), nl, !,
	statistics(walltime, [TimeSinceStart, _TimeSinceLastCall]),
	read_board_state(Color, BoardTree, BoardCounters), !,
	color_pieces_for_board(Color, BoardTree, ColorPiecesForBoard),
	color_moves(Color, ColorPiecesForBoard, BoardTree, Moves),
	%((Moves = [], write('No moves!'), nl); true),
	eval_depth(EvalDepth),
	time_to_think(TimeToThink),
	eval_choose_master(EvalDepth, TimeToThink, Moves, Color, Color, BoardTree, BoardCounters, 1, (nil, nil), (Move, Value)),
	(
		(
			Move == nil, write('No moves left!'), nl
		)
		;
		(
			write(Move), write(' = '), write(Value), nl,
			apply_move(Color, Move, BoardTree, NewBoardTree),
			replace_board_state(NewBoardTree), !,
			statistics(walltime, [NewTimeSinceStart, _NewTimeSinceLastCall]), 
			ExecutionTime is NewTimeSinceStart - TimeSinceStart,
			write('Execution took '), write(ExecutionTime), write(' ms.'), nl, 
			print_board
		)
	).

iapb134526(ColorNr, X, Y) :-
	X =\= 0, Y =\= 0, !,
	color_code(ColorNr, Color),
	write('continue?'), get_char(_), nl, !,
	statistics(walltime, [TimeSinceStart, _TimeSinceLastCall]),
	read_board_state(Color, BoardTree, BoardCounters),
	arbiter:ruut(X, Y, XYState), !,
	state_for_color(Color, XYState, PieceType),
	color_moves(Color, [(Y, X, PieceType)], BoardTree, Moves, 'KILL'),
	%((Moves = [], write('No moves!'), nl); true),
	eval_depth_fixed_starting(EvalDepth),
	time_to_think(TimeToThink),
	eval_choose_master(EvalDepth, TimeToThink, Moves, Color, Color, BoardTree, BoardCounters, 1, (nil, nil), (Move, Value)),
	(	
		(
			Move == nil, write('No moves left!'), nl
		)
		;
		(
			write(Move), write(' = '), write(Value), nl,
			apply_move(Color, Move, BoardTree, NewBoardTree), !,
			replace_board_state(NewBoardTree), !,
			statistics(walltime, [NewTimeSinceStart, _NewTimeSinceLastCall]), 
			ExecutionTime is NewTimeSinceStart - TimeSinceStart, 
			write('Execution took '), write(ExecutionTime), write(' ms.'), nl,
			print_board
		)
	).

user_iapb134526(ColorNr, X, Y) :-
	color_code(ColorNr, Color),
	write('Your move for X='), write(Y), write(' Y='), write(X), nl,
	read(Move),
	read_board_state(Color, BoardTree, _BoardCounters),
	apply_move(Color, Move, BoardTree, NewBoardTree), !,
	replace_board_state(NewBoardTree), !,
	print_board.