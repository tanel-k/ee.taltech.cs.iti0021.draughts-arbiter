:- [kill_expander, utils].

expand_moves(kills(Kills), Color, BoardRows, kills(ExpandedKills)) :- !,
	expand_with_chain_effect(Kills, Color, BoardRows, ExpandedKills).
expand_moves(moves(Moves), _Color, _BoardRows, moves(Moves)). 
/*
 NOTE: Move filtering deprecated as of 09/10/2016.
 Certain "suicide" moves are useful.
 Certain "lowest threat count" moves are terrible.
*/
