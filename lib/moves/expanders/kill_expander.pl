/* WIP: previously used to count threats and chain options */
expand_with_chain_effect([], _Color, _BoardTree, []).
expand_with_chain_effect([Move|Moves], Color, BoardTree, [ExpandedMove|ExpandedMoves]) :-
	check_if_kill_chains(Move, Color, BoardTree, ExpandedMove),
	expand_with_chain_effect(Moves, Color, BoardTree, ExpandedMoves).

% --- SEPARATE LOGIC FOR PAWNS AND KINGS --- %
check_if_kill_chains(move(pawn, From, To, effects(MoveEffect, kill(XDead, YDead, DeadPieceType), _ChainEffectPlaceholder)), Color, BoardTree, move(pawn, From, To, effects(MoveEffect, kill(XDead, YDead, DeadPieceType), NewChainEffect))) :- 
	check_pawn_kill_chains(From, dead(XDead, YDead), To, Color, BoardTree, DoesChain),
	((DoesChain == yes, NewChainEffect = chain_effect('WILL CHAIN')); (DoesChain == no, NewChainEffect = chain_effect('NIL'))).
check_if_kill_chains(move(king, From, To, effects(MoveEffect, kill(XDead, YDead, DeadPieceType), _ChainEffectPlaceholder)), Color, BoardTree, move(king, From, To, effects(MoveEffect, kill(XDead, YDead, DeadPieceType), NewChainEffect))) :-
	check_king_kill_chains(From, dead(XDead, YDead), To, Color, BoardTree, DoesChain),
	((DoesChain == yes, NewChainEffect = chain_effect('WILL CHAIN')); (DoesChain == no, NewChainEffect = chain_effect('NIL'))).
% ------------------------------------------ %

% ---------------- EXPAND KING KILL ------------------- %
check_king_kill_chains(From, Dead, To, Color, BoardTree, DoesChain) :-
	diagonal_traversal_ops(TraversalOps),
	check_king_kill_chains(TraversalOps, From, Dead, To, Color, BoardTree, DoesChain).

check_king_kill_chains([], _From, _Dead, _To, _Color, _BoardTree, DoesChain) :- DoesChain = no.
check_king_kill_chains([TraversalOp|TraversalOps], From, Dead, To, Color, BoardTree, DoesChain) :-
	check_king_kill_for_dir(TraversalOp, From, Dead, To, Color, BoardTree, DoesChainForDir), !,
	((DoesChainForDir == no, check_king_kill_chains(TraversalOps, From, Dead, To, Color, BoardTree, DoesChain)); DoesChain = yes).

% when checking reverse of movement direction we need to skip ahead
% (eliminating the dead piece and the distance we covered in order to kill it from scanning)
check_king_kill_for_dir(traversal_op(XsOp, YsOp), from(FromX, FromY), _Dead, to(ToX, ToY), Color, BoardTree, DoesChainForDir) :-
	movement_op(ToX, ToY, FromX, FromY, traversal_op(XsOp, YsOp)), !,
	apply_traversal_op(traversal_op(XsOp, YsOp), FromX, FromY, DirX, DirY),
	scan_dir_for_king(traversal_op(XsOp, YsOp), DirX, DirY, Color, BoardTree, DoesChainForDir).
% otherwise check the diagonal as usual
check_king_kill_for_dir(TraversalOp, from(FromX, FromY), _Dead, _To, Color, BoardTree, DoesChainForDir) :-
	apply_traversal_op(TraversalOp, FromX, FromY, DirX, DirY), % warning
	scan_dir_for_king(TraversalOp, DirX, DirY, Color, BoardTree, DoesChainForDir).

scan_dir_for_king(_TraversalOp, DirX, DirY, _Color, _BoardTree, DoesChainForDir) :-
	not(can_check_pos(DirX, DirY)), !,
	DoesChainForDir = no.
scan_dir_for_king(TraversalOp, DirX, DirY, Color, BoardTree, DoesChainForDir) :-
	board_rows_field_state(DirX, DirY, BoardTree, DirEntityState),
	check_dir_encounter_for_king(TraversalOp, DirEntityState, DirX, DirY, Color, BoardTree, DoesChainForDir).

% neighbor is one of ours --> return
check_dir_encounter_for_king(_TraversalOp, DirEntityState, _DirX, _DirY, Color, _BoardTree, DoesChainForDir) :-
	state_for_color(Color, DirEntityState, _PieceType), !,
	DoesChainForDir = no.
% neighbor is vacant --> continue.
check_dir_encounter_for_king(TraversalOp, DirEntityState, DirX, DirY, Color, BoardTree, DoesChainForDir) :-
	void_state(DirEntityState), !,
	apply_traversal_op(TraversalOp, DirX, DirY, NextX, NextY),
	scan_dir_for_king(TraversalOp, NextX, NextY, Color, BoardTree, DoesChainForDir).
check_dir_encounter_for_king(TraversalOp, DirEntityState, DirX, DirY, Color, BoardTree, DoesChainForDir) :-
	state_for_other_color(Color, DirEntityState, _PieceType), !,
	dir_king_opponent_encounter(TraversalOp, DirX, DirY, BoardTree, DoesChainForDir).

dir_king_opponent_encounter(TraversalOp, DirX, DirY, _BoardTree, DoesChainForDir) :-
	% opponent at edge of board: 
	would_traverse_beyond_board(TraversalOp, DirX, DirY), !, 
	DoesChainForDir = no.
dir_king_opponent_encounter(TraversalOp, DirX, DirY, BoardTree, DoesChainForDir) :-
	apply_traversal_op(TraversalOp, DirX, DirY, BehindOppX, BehindOppY),
	board_rows_field_state(BehindOppX, BehindOppY, BoardTree, BehindOppState),
	chainable_for_king(BehindOppState, DoesChainForDir).

chainable_for_king(BehindOppState, DoesChainForDir) :-
	void_state(BehindOppState), !,
	DoesChainForDir = yes.
chainable_for_king(_BehindOppState, DoesChainForDir) :-
	DoesChainForDir = no.
% ---------------- /EXPAND KING KILL ------------------ %

% ---------------- EXPAND PAWN KILL ------------------ %
check_pawn_kill_chains(From, Dead, To, Color, BoardTree, DoesChain) :-
	diagonal_traversal_ops(TraversalOps),
	check_pawn_kill(TraversalOps, From, Dead, To, Color, BoardTree, DoesChain).

check_pawn_kill([], _From, _Dead, _To, _Color, _BoardTree, DoesChain) :-
	DoesChain = no.
check_pawn_kill([TraversalOp|TraversalOps], From, Dead, To, Color, BoardTree, DoesChain) :-
	check_pawn_kill_for_dir(TraversalOp, From, Dead, To, Color, BoardTree, DoesChainForDir), !,
	((DoesChainForDir == no, check_pawn_kill(TraversalOps, From, Dead, To, Color, BoardTree, DoesChain)); DoesChain = yes).

% if traversing would take us beyond the board, return
check_pawn_kill_for_dir(TraversalOp, _From, _Dead, to(ToX, ToY), _Color, _BoardTree, DoesChainForDir) :-
	would_traverse_beyond_board(TraversalOp, ToX, ToY), !, 
	DoesChainForDir = no.
% otherwise proceed as normal:
% when checking reverse of movement direction, 
% there can be no chaining because an empty field is left behind
check_pawn_kill_for_dir(traversal_op(XsOp, YsOp), from(FromX, FromY), _Dead, to(ToX, ToY), _Color, _BoardTree, DoesChainForDir) :-
	movement_op(ToX, ToY, FromX, FromY, traversal_op(XsOp, YsOp)), !,
	DoesChainForDir = no.
% check our first neighbor, then either look for a king or terminate
check_pawn_kill_for_dir(TraversalOp, _From, Dead, to(ToX, ToY), Color, BoardTree, DoesChainForDir) :-
	apply_traversal_op(TraversalOp, ToX, ToY, FirstX, FirstY),
	check_first_neighbor_for_pawn_wrapped(FirstX, FirstY, TraversalOp, Color, Dead, BoardTree, DoesChainForDir).

% check if position is valid:
check_first_neighbor_for_pawn_wrapped(FirstX, FirstY, TraversalOp, Color, Dead, BoardTree, DoesChainForDir) :-
	can_check_pos(FirstX, FirstY), !,
	board_rows_field_state(FirstX, FirstY, BoardTree, NeighborState),
	check_first_neighbor_for_pawn(FirstX, FirstY, NeighborState, TraversalOp, Color, Dead, BoardTree, DoesChainForDir).
% if not, return (no threats or chaining for positions beyond the board):
check_first_neighbor_for_pawn_wrapped(_FirstX, _FirstY, _TraversalOp, _Color, _Dead, _BoardTree, DoesChainForDir) :-
	DoesChainForDir = no.

% neighboring piece is one of the opponent's, check if it can be chained
check_first_neighbor_for_pawn(FirstX, FirstY, NeighborState, TraversalOp, Color, dead(DeadX, DeadY), BoardTree, DoesChainForDir) :-
	state_for_other_color(Color, NeighborState, _PieceType),
	% we may have a "dead" opponent as a neighbor
	% since we do not update the board state for filtering
	not((FirstX =:= DeadX, FirstY =:= DeadY)), !,
	%not(edge_of_board(FirstX, FirstY)),
	apply_traversal_op(TraversalOp, FirstX, FirstY, AfterNeighborX, AfterNeighborY),
	check_pawn_neighbor_chainable_wrapped(AfterNeighborX, AfterNeighborY, Color, BoardTree, DoesChainForDir).
% neighboring piece is (effectively) vacant or occupied by a friendly piece
check_first_neighbor_for_pawn(_FirstX, _FirstY, _EffectivelyVoid, _TraversalOp, _Color, _Dead, _BoardTree, DoesChainForDir) :-
	DoesChainForDir = no.

check_pawn_neighbor_chainable_wrapped(AfterNeighborX, AfterNeighborY, Color, BoardTree, DoesChainForDir) :-
	can_check_pos(AfterNeighborX, AfterNeighborY), !,
	board_rows_field_state(AfterNeighborX, AfterNeighborY, BoardTree, AfterNeighborState),
	check_pawn_neighbor_chainable(AfterNeighborState, Color, DoesChainForDir).
% opponent at edge:
check_pawn_neighbor_chainable_wrapped(_AfterNeighborX, _AfterNeighborY, _Color, _BoardTree, DoesChainForDir) :-
	DoesChainForDir = no.

check_pawn_neighbor_chainable(AfterNeighborState, _Color, DoesChainForDir) :-
	void_state(AfterNeighborState), !,
	DoesChainForDir = yes.
check_pawn_neighbor_chainable(_AfterNeighborState, _Color, DoesChainForDir) :-
	DoesChainForDir = no.
% ---------------- /CHECK PAWN KILL ------------------ %

% ---- SHARED PROCEDURES ---- %
can_check_pos(AtX, AtY) :-
	AtX =< 8,
	AtX >= 1,
	AtY =< 8,
	AtY >= 1.

% FIX for invalid positions
would_traverse_beyond_board(traversal_op(XsOp, YsOp), AtX, AtY) :-
	apply_traversal_op(traversal_op(XsOp, YsOp), AtX, AtY, NextX, NextY),
	not(can_check_pos(NextX, NextY)).
% ---- /SHARED PROCEDURES ---- %