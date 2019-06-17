select_move(MovesWrapped, Move) :-	
	select_first_kill_or_move(MovesWrapped, Move).

select_first_kill_or_move(kills([Kill|_Kills]), Kill).
select_first_kill_or_move(moves([Move|_Moves]), Move).

% TODO : alpha-beta minimax