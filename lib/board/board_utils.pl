:- [board_facts, avl_impl, '../help/helpers'].

color_pieces_for_board(Color, BoardTree, ColorPiecesForBoard) :-
	extract_rows(1, 8, 1, Color, BoardTree, ColorPiecesForBoard).

extract_rows(Y, MaxY, _StartX, _Color, _BoardTree, []) :-
	Y > MaxY, !.
extract_rows(Y, MaxY, StartX, Color, BoardTree, ColorPiecesForBoardTail) :-
	extract_row_nodes(StartX, 8, Y, Color, BoardTree, ColorPiecesForBoardTail, NewColorPiecesForBoardTail), !,
	NewY is Y + 1,
	next_start_x(StartX, NextStartX),
	extract_rows(NewY, MaxY, NextStartX, Color, BoardTree, NewColorPiecesForBoardTail).

extract_row_nodes(X, MaxX, _Y, _Color, _BoardTree, ColorPiecesForBoardTail, ColorPiecesForBoardTail) :- 
	X > MaxX, !.
extract_row_nodes(X, MaxX, Y, Color, BoardTree, ColorPiecesForBoardTail, EndColorPiecesForBoardTail) :-
	avl_lookup(BoardTree, (X, Y, XYState)),
	extraction_tail_update(Color, (X, Y, XYState), ColorPiecesForBoardTail, NewColorPiecesForBoardTail),
	NewX is X + 2, !,
	extract_row_nodes(NewX, MaxX, Y, Color,  BoardTree, NewColorPiecesForBoardTail, EndColorPiecesForBoardTail).
extraction_tail_update(Color, (X, Y, XYState), [(X, Y, PieceType) | ColorPiecesForBoardTail], ColorPiecesForBoardTail) :-
	state_for_color(Color, XYState, PieceType), !.
extraction_tail_update(_Color, (_X, _Y, _XYState), ColorPiecesForBoardTail, ColorPiecesForBoardTail).

next_start_x(1, 2).
next_start_x(2, 1).

% --------- Use AVL tree instead of a 2-D list --------- %
avl_gt((X1, _Y1, _XYState1), (X2, _Y2, _XYState2)) :-
	X1 > X2, !.
avl_gt((X, Y1, _XYState1), (X, Y2, _XYState2)) :-
	Y1 > Y2.

board_rows_to_board_tree(BoardRows, BoardTree) :-
	board_rows_to_board_tree(BoardRows, avl_tree(nil, nil, nil, 0), BoardTree).

board_row_to_board_tree([], BoardTree, BoardTree).
board_row_to_board_tree([BoardNode|BoardRow], BoardTreeAcc, BoardTree) :-
	add_avl(BoardTreeAcc, BoardNode, NewBoardTreeAcc), !,
	board_row_to_board_tree(BoardRow, NewBoardTreeAcc, BoardTree).

board_rows_to_board_tree([], BoardTree, BoardTree).
board_rows_to_board_tree([(_RowIndex, Row)|BoardRows], BoardTreeAcc, BoardTree) :-
	board_row_to_board_tree(Row, BoardTreeAcc, NewBoardTreeAcc), !,
	board_rows_to_board_tree(BoardRows, NewBoardTreeAcc, BoardTree).
% --------- /Use AVL tree instead of a 2-D list --------- %

board_rows_field_state(X, Y, BoardTree, XYState) :-
	X >= 1, X =< 8,
	Y >= 1, Y =< 8,
	avl_lookup(BoardTree, (X, Y, XYState)).

% NB! Mängus on X ja Y vahetuses!
read_board_state(Color, BoardTree, state_counters(ColorPawnCnt, ColorKingCnt, OtherPawnCnt, OtherKingCnt, VoidCnt)) :-
	read_board_state_rows(1, 9, Color, BoardRows, 0, ColorPawnCnt, 0, ColorKingCnt, 0, OtherPawnCnt, 0, OtherKingCnt, 0, VoidCnt), !,
	board_rows_to_board_tree(BoardRows, BoardTree).

read_board_state_rows(N, N, _, [], ColorPawnCnt, ColorPawnCnt, ColorKingCnt, ColorKingCnt, OtherPawnCnt, OtherPawnCnt, OtherKingCnt, OtherKingCnt, VoidCnt, VoidCnt).
read_board_state_rows(I, N, Color, [(I, Row) | BoardRows], ColorPawnCntAcc, ColorPawnCnt, ColorKingCntAcc, ColorKingCnt, OtherPawnCntAcc, OtherPawnCnt, OtherKingCntAcc, OtherKingCnt, VoidCntAcc, VoidCnt) :-
	I < N,
	I1 is I + 1,
	other_color(Color, OtherColor),
	color_pawn(Color, ColorPawn),
	color_king(Color, ColorKing),
	color_pawn(OtherColor, OtherColorPawn),
	color_king(OtherColor, OtherColorKing),
	% Mängus on X ja Y koordinaadid vahetuses!
	find_all_dl_counting((X1, I, ColorPawn), arbiter:ruut(I, X1, ColorPawn), Row, ColorPawnsTail, ColorPawnRowCnt),
	find_all_dl_counting((X2, I, ColorKing), arbiter:ruut(I, X2, ColorKing), ColorPawnsTail, ColorKingsTail, ColorKingRowCnt),
	find_all_dl_counting((X3, I, OtherColorPawn), arbiter:ruut(I, X3, OtherColorPawn), ColorKingsTail, OpponentPawnsTail, OtherPawnRowCnt),
	find_all_dl_counting((X4, I, OtherColorKing), arbiter:ruut(I, X4, OtherColorKing), OpponentPawnsTail, OpponentKingsTail, OtherKingRowCnt),
	find_all_dl_counting((X5, I, 0), arbiter:ruut(I, X5, 0), OpponentKingsTail, [], VoidRowCnt),
	NewColorPawnCntAcc is ColorPawnRowCnt + ColorPawnCntAcc,
	NewColorKingCnt is ColorKingRowCnt + ColorKingCntAcc,
	NewOtherPawnCntAcc is OtherPawnRowCnt + OtherPawnCntAcc,
	NewOtherKingCntAcc is OtherKingRowCnt + OtherKingCntAcc,
	NewVoidCnt is VoidRowCnt + VoidCntAcc,
	read_board_state_rows(I1, N, Color, BoardRows, NewColorPawnCntAcc, ColorPawnCnt, NewColorKingCnt, ColorKingCnt, NewOtherPawnCntAcc, OtherPawnCnt, NewOtherKingCntAcc, OtherKingCnt, NewVoidCnt, VoidCnt), !.


% NB! Õppejõul on X ja Y vahetuses!
replace_board_state(BoardTree) :-
	abolish(arbiter:ruut/3),
	assert_board_tree(BoardTree).

assert_board_tree(avl_tree(nil, nil, nil, _H)) :- !.
assert_board_tree(avl_tree(Left, (X, Y, XYState), Right, _H)) :-
	assert_board_tree(Left), 
	% tagasipööramine:
	assert(arbiter:ruut(Y, X, XYState)),
	assert_board_tree(Right).