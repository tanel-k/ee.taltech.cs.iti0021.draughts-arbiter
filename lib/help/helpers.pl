find_all_dl_counting(X, Goal, _, _, _) :-
	asserta('#DL#'('#NULL#')),
	Goal,
	asserta('#DL#'(X)), 
	fail.
find_all_dl_counting(_Term, _Goal, Xs, XsTail, Count) :-
	retract('#DL#'(X)), !,
	collect_found_dl_counting(X, Xs, XsTail, 0, Count).

collect_found_dl_counting(X, [X|Xs], XsTail, CountAcc, Count) :-
	X \== '#NULL#', !,
	retract('#DL#'(X1)), !,
	NewCountAcc is CountAcc + 1,
	collect_found_dl_counting(X1, Xs, XsTail, NewCountAcc, Count).
collect_found_dl_counting('#NULL#', XsTail, XsTail, Count, Count) :- !.

first_member(X, [X|_Xs]) :- !.
first_member(X, [Y|Ys]) :-
	X \= Y, !,
	first_member(X, Ys).
	
unify_if_match(MatchVal, MatchVal, MatchVal, _OutVar) :- !.
unify_if_match(_MatchVal, _TestVal, OutVar, OutVar).

unify_if_nonvar(Var, _Target) :- var(Var), !.
unify_if_nonvar(Target, Target) :- !.