:- [	
		'../board/board_utils', 
		pawn_moves, 
		king_moves,
		apply,
		select,
		'expanders/expander',
		utils
	].

color_moves(Color, ColorPiecesForBoard, BoardRows, ExpandedMoves) :-
	color_moves(Color, ColorPiecesForBoard, BoardRows, ResultMoves, _DuplexForcedKillFlag),
	expand_moves(ResultMoves, Color, BoardRows, ExpandedMoves).
color_moves(Color, ColorPiecesForBoard, BoardRows, ResultMoves, DuplexForcedKillFlag) :- !,
	% for each piece, find the KillMoves and the regular Moves
	% additionally, unify DuplexForcedKillFlag with the atom 'KILL' if a kill was found
	moves_for_pieces(ColorPiecesForBoard, Color, BoardRows, KillMoves, [], Moves, [], DuplexForcedKillFlag),
	% return kills or moves depending on whether DuplexForcedKillFlag was unified with 'KILL'
	select_kills_if_forced(DuplexForcedKillFlag, KillMoves, Moves, ResultMoves).

select_kills_if_forced(DuplexForcedKillFlag, _KillMoves, Moves, moves(Moves)) :- DuplexForcedKillFlag \== 'KILL', !.	
select_kills_if_forced('KILL', KillMoves, _Moves, kills(KillMoves)).

moves_for_pieces([], _, _, KillsTail, KillsTail, MovesTail, MovesTail, _) :- !.
moves_for_pieces([(X, Y, PieceType) | ColorPieces], Color, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :-
	piece_moves(PieceType, Color, X, Y, BoardRows, KillsTail, KillsTailAfterPieceMoves, MovesTail, MovesTailAfterPieceMoves, DuplexForcedKillFlag),
	moves_for_pieces(ColorPieces, Color, BoardRows, KillsTailAfterPieceMoves, KillsResultTail, MovesTailAfterPieceMoves, MovesResultTail, DuplexForcedKillFlag).

piece_moves(pawn, Color, X, Y, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :- !,
	pawn_moves(Color, X, Y, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag).
piece_moves(king, Color, X, Y, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag) :- !,
	king_moves(Color, X, Y, BoardRows, KillsTail, KillsResultTail, MovesTail, MovesResultTail, DuplexForcedKillFlag).