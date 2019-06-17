% -------- BROKEN MINIMAX ---------%
% Sterling & Shapiro, Program 20.10
broken_eval_choose([Move|Moves], Position, D, MaxMin, Record, Best) :-
	move(Move, Position, Position1),
	broken_minimax(D, Position1, MaxMin, _MoveX, Value),
	broken_update(Move, Value, Record, Record1),
	broken_eval_choose(Moves, Position, D, MaxMin, Record1, Best).
broken_eval_choose([], _Position, _D, _MaxMin, Record, Record).

broken_minimax(0, Position, MaxMin, _Move, Value) :-
	value(Position, V),
	Value is V * MaxMin.
broken_minimax(D, Position, MaxMin, Move, Value) :-
	D > 0,
	findall(M, move(Position, M), Moves),
	D1 is D - 1,
	MinMax is -MaxMin,
	broken_eval_choose(Moves, Position, D1, MinMax, (nil, -1000), (Move, Value)).

% Sterling & Shapiro, Program 20.9
broken_update(_Move, Value, (Move1, Value1), (Move1, Value1)) :-
	Value =< Value1.
broken_update(Move, Value, (_Move1, Value1), (Move, Value)) :-
	Value > Value1.
% -------- /BROKEN MINIMAX ---------%

% -------- FIX PROPOSAL ---------%
eval_choose([Move|Moves], Position, D, MaxMin, Record, Best) :-
	move(Move, Position, Position1),
	minimax(D, Position1, MaxMin, _MoveX, Value),
	update(Move, Value, Record, Record1, MaxMin),
	eval_choose(Moves, Position, D, MaxMin, Record1, Best).
eval_choose([], _Position, _D, _MaxMin, Record, Record).

minimax(0, Position, _MaxMin, _Move, Value) :-
	value(Position, V),
	% do NOT multiply with MaxMin here
	% negative minima are converted to maxima otherwise
	% (as per Figure 20.2, negative minima are allowed)
	Value is V.
minimax(D, Position, MaxMin, Move, Value) :-
	D > 0, !,
	findall(M, move(Position, M), Moves),
	D1 is D - 1,
	MinMax is -MaxMin,
	eval_choose(Moves, Position, D1, MinMax, (nil, -1000), (Move, Value)).

% immediately replace the Nil move:
update(Move, Value, (nil, _), (Move, Value), _MaxMin) :- !.

% maximize when MaxMin is positive:
update(_Move, Value, (M1, V1), (M1, V1), MaxMin) :-
	MaxMin > 0, Value =< V1, !.
update(Move, Value, (_M1, V1), (Move, Value), MaxMin) :-
	MaxMin > 0, Value > V1.

% minimize when MaxMin is negative:
update(_Move, Value, (M1, V1), (M1, V1), MaxMin) :-
	MaxMin < 0, Value > V1, !.
update(Move, Value, (_M1, V1), (Move, Value), MaxMin) :-
	MaxMin < 0, Value =< V1.
% -------- /FIX PROPOSAL ---------%

% -------- SAMPLE GAME TREE ---------%
move(m1, x0, y1). 
move(m2, x0, y2).

move(m3, y1, z1).		
move(m4, y1, z2).		

move(m5, y2, w1).
move(m6, y2, w2).
 
move(m7, z1, k1).
move(m8, z1, k2).

move(m9, k1, l1). 

move(m10, z2, o1).
move(m11, o1, r1).

move(m12, k2, s1).

move(m13, w1, p1).
move(m14, p1, e1).

move(m15, w2, f1).
move(m16, f1, g1).

value(l1, -80).
value(s1, -3).
value(r1, 1).
value(e1, 5).
value(g1, 2).
% -------- /SAMPLE GAME TREE ---------%


% ------------ UTILITIES -------------%
test :- test_fix, test_broken, !.

test_fix :- eval_choose([m1, m2], x0, 3, 1, (nil, -1000), Best), 
	write(Best), write(' was deemed the best move using the fixed version'), nl.

test_broken :- broken_eval_choose([m1, m2], x0, 3, 1, (nil, -1000), Best), 
	write(Best), write(' was deemed the best move using the broken version'), nl.

% for findall
move(Position, Move) :- move(Move, Position, _Position1).
% ------------ /UTILITIES -------------%