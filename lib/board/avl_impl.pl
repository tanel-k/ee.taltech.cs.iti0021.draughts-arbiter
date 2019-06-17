% add_avl Adapted from I. Bratko's "Prolog Programming for Artificial Intelligence" (Pearson Education, 2012)
:- dynamic avl_gt/2.

avl_lookup(avl_tree(nil, nil, nil, 0), _KeyData, _Result) :- !, fail.
avl_lookup(avl_tree(_LeftSubTree, LocalRoot, RightSubTree, _Height), KeyData) :- 
	% Key > Root
	avl_gt(KeyData, LocalRoot), !,
	avl_lookup(RightSubTree, KeyData).
avl_lookup(avl_tree(LeftSubTree, LocalRoot, _RightSubTree, _Height), KeyData) :- 
	% Key < Root
	avl_gt(LocalRoot, KeyData), !,
	avl_lookup(LeftSubTree, KeyData).
avl_lookup(avl_tree(_LeftSubTree, KeyData, _RightSubTree, _Height), KeyData).
% Key = Root

% Use replace when you know the key whose data you are replacing is already in the tree (avoids unnecessary re-balancing)
replace_avl(avl_tree(LeftSubTree, LocalRootData, RightSubTree, Height), ReplaceData, avl_tree(NewLeftSubTree, LocalRootData, RightSubTree, Height)) :-
	avl_gt(LocalRootData, ReplaceData), !,
	replace_avl(LeftSubTree, ReplaceData, NewLeftSubTree).
replace_avl(avl_tree(LeftSubTree, LocalRootData, RightSubTree, Height), ReplaceData, avl_tree(LeftSubTree, LocalRootData, NewRightSubTree, Height)) :-
	avl_gt(ReplaceData, LocalRootData), !,
	replace_avl(RightSubTree, ReplaceData, NewRightSubTree).
replace_avl(avl_tree(LeftSubTree, _ReplacedData, RightSubTree, Height), ReplaceData, avl_tree(LeftSubTree, ReplaceData, RightSubTree, Height)).

% Empty tree
add_avl(avl_tree(nil, nil, nil, 0), AddData, avl_tree(avl_tree(nil, nil, nil, 0), AddData, avl_tree(nil, nil, nil, 0), 1)) :- !.
add_avl(avl_tree(LeftSubTree, LocalRootData, RightSubTree, _Height), AddData, ResultTree) :-
	% New < Root
	avl_gt(LocalRootData, AddData), !,
	add_avl(LeftSubTree, AddData, avl_tree(NewLeftLeftSub, NewLeftRoot, NewLeftRightSub, _SubHeight)),
	balance_locally(NewLeftLeftSub, NewLeftRoot, NewLeftRightSub, LocalRootData, RightSubTree, ResultTree).
add_avl(avl_tree(LeftSubTree, LocalRootData, RightSubTree, _Height), AddData, ResultTree) :-
	% New > Root
	avl_gt(AddData, LocalRootData), !,
	add_avl(RightSubTree, AddData, avl_tree(NewRightLeftSub, NewRightRoot, NewRightRightSub, _SubHeight)),
	balance_locally(LeftSubTree, LocalRootData, NewRightLeftSub, NewRightRoot, NewRightRightSub, ResultTree).
add_avl(avl_tree(LeftSubTree, _ReplacedRootData, RightSubTree, Height), ReplacementData, avl_tree(LeftSubTree, ReplacementData, RightSubTree, Height)) :- !.
% New = Root

balance_locally(
	avl_tree(Left1, Root1, Right1, H1), 
	A, 
	avl_tree(Left2, Root2, Right2, H2), 
	C, 
	avl_tree(Left3, Root3, Right3, H3),
	avl_tree(avl_tree(avl_tree(Left1, Root1, Right1, H1), A, Left2, Ha), Root2, avl_tree(Right2, C, avl_tree(Left3, Root3, Right3, H3), Hc), Hb)) :-
	H2 > H1, 
	H2 > H3, !,
	Ha is H1 + 1,
	Hc is H3 + 1,
	Hb is Ha + 1.

balance_locally(
	avl_tree(Left1, Root1, Right1, H1),
	A, 
	avl_tree(Left2, Root2, Right2, H2), 
	C, 
	avl_tree(Left3, Root3, Right3, H3),
	avl_tree(avl_tree(Left1, Root1, Right1, H1), A, avl_tree(avl_tree(Left2, Root2, Right2, H2), C, avl_tree(Left3, Root3, Right3, H3), Hc), Ha)) :-
	H1 >= H2, 
	H1 >= H3, !,
	max_height_succ(H2, H3, Hc),
	max_height_succ(H1, Hc, Ha).

balance_locally(
	avl_tree(Left1, Root1, Right1, H1), 
	A, 
	avl_tree(Left2, Root2, Right2, H2), 
	C, 
	avl_tree(Left3, Root3, Right3, H3),
	avl_tree(avl_tree(avl_tree(Left1, Root1, Right1, H1), A, avl_tree(Left2, Root2, Right2, H2), Ha), C, avl_tree(Left3, Root3, Right3, H3), Hc)) :-
	H3 >= H1, 
	H3 >= H2, !,
	max_height_succ(H1, H2, Ha),
	max_height_succ(Ha, H3, Hc).

max_height_succ(X, Y, Res) :-
	X > Y, !, Res is X + 1.
max_height_succ(X, Y, Res) :-
	X =< Y, !, Res is Y + 1.

% -------------- DEBUG -------------- %
avl_print(AVLTree) :-
	avl_print(AVLTree, 0).

avl_print(avl_tree(nil, nil, nil, _H), _RecursionDepth) :- !.
avl_print(avl_tree(Left, Root, Right, _H), RecursionDepth) :-
	NewRecursionDepth is RecursionDepth + 1,
	avl_dbg_print_spaces(RecursionDepth), write(Root), nl,
	avl_print(Left, NewRecursionDepth),
	avl_print(Right, NewRecursionDepth).

avl_dbg_print_spaces(0) :- !.
avl_dbg_print_spaces(Count) :-
	Count > 0, !,
	NextCount is Count - 1,
	write(' '),
	avl_dbg_print_spaces(NextCount).

/*
avl_gt((X, _XVal), (Y, _YVal)) :-
	number(X),
	number(Y),
	X > Y.
*/

% -------------- /DEBUG -------------- %