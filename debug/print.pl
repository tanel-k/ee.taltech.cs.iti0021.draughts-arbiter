print_board :-
	print_board(8, 1).
	
print_board(RowNum, MinRowNum) :- RowNum < MinRowNum, !, write_footer.
print_board(RowNum, MinRowNum) :- 
	write('|  '), write(RowNum), write('  |'),
	print_row(RowNum, 1, 8),
	print_sep,
	NewRowNum is RowNum - 1,
	print_board(NewRowNum, MinRowNum).

print_row(_RowNum, ColNum, MaxColNum) :- ColNum > MaxColNum, !.
print_row(RowNum, ColNum, MaxColNum) :- 
	print_square(ColNum, RowNum),
	NewColNum is ColNum + 1,
	print_row(RowNum, NewColNum, MaxColNum).
	
print_square(X, Y) :-
	arbiter:ruut(Y, X, XYState), !,
	print_state(XYState).

print_square(_X, _Y) :-
	print_state(0).

print_state(0) :-
	write('     |').
	%format('     |', []).
print_state(2) :- 
	write('  B  |').
	%format('  ~c  |', [9823]).
print_state(20) :- 
	write('  B" |').
	%format('  ~c  |', [9819]).
print_state(1) :- 
	write('  W  |').
	%format('  ~c  |', [9817]).
print_state(10) :- 
	write('  W" |').
	%format('  ~c  |', [9813]).

print_sep :-
	nl,
	print_sym('-', 55),
	nl.

print_sym(_Sym, 0) :- !.
print_sym(Sym, I) :-
	I > 0, !,
	write(Sym),
	I1 is I - 1,
	print_sym(Sym, I1).

write_footer :-
	write('|     '),
	write_footer(1, 8),
	nl.
write_footer(I, N) :- I > N, !, write('|').
write_footer(I, N) :- !,
	write('|  '), write(I), write('  '),
	I1 is I + 1,
	write_footer(I1, N).