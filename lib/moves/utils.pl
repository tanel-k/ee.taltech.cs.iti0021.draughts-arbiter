diagonal_traversal_ops([traversal_op(+, +), traversal_op(+, -), traversal_op(-, -), traversal_op(-, +)]).

apply_traversal_op(traversal_op(XsOp, YsOp), X, Y, NextX, NextY) :-
	XsExpression =.. [XsOp, X, 1],
	YsExpression =.. [YsOp, Y, 1],
	NextX is XsExpression,
	NextY is YsExpression.

reverse_op(+, -).
reverse_op(-, +).

signum(X, -) :-
	X < 0, !.
signum(X, +) :-
	X >= 0, !.