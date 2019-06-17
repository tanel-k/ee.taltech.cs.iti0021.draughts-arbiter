void_state(0).

color_code(1, valged).
color_code(2, mustad).
color_code(valged, valged).
color_code(mustad, mustad).

other_pawn(mustad, 1).
other_pawn(valged, 2).

other_king(valged, 20).
other_king(mustad, 10).

color_pawn(mustad, 2).
color_pawn(valged, 1).

color_king(valged, 10).
color_king(mustad, 20).

other_color(valged, mustad).
other_color(mustad, valged).

piece_type(2, pawn).
piece_type(20, king).
piece_type(1, pawn).
piece_type(10, king).

state_for_color(valged, 1, pawn).
state_for_color(valged, 10, king).
state_for_color(mustad, 2, pawn).
state_for_color(mustad, 20, king).

state_for_other_color(valged, 2, pawn).
state_for_other_color(valged, 20, king).
state_for_other_color(mustad, 1, pawn).
state_for_other_color(mustad, 10, king).

is_crowning_row(mustad, 1).
is_crowning_row(valged, 8).

edge_of_board(X, _Y) :-
	is_edge_coord(X), !.
edge_of_board(_X, Y) :-
	is_edge_coord(Y), !.

is_edge_coord(1).
is_edge_coord(8).