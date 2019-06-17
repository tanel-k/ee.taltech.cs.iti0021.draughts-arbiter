movement_op(FromX, FromY, ToX, ToY, traversal_op(XsOp, YsOp)) :-
	XDiff is ToX - FromX,
	YDiff is ToY - FromY,
	signum(XDiff, XsOp),
	signum(YDiff, YsOp).

can_threat_check(AtX, AtY) :-
	AtX =< 8,
	AtX >= 1,
	AtY =< 8,
	AtY >= 1.
