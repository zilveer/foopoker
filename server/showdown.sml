abstype sidepot = Sidepot of (int * int * int) list * int
	with
	
	(*
		emptyPot
		TYPE: 		sidepot
		VALUE: 		An empty sidepot. 
	*)
	val emptyPot = Sidepot ([], 0);

	(*	
		winners l
		TYPE:		('a * int * 'b) list -> ('a * int * 'b) list
		PRE:		(none)
		POST:		
		EXAMPLE:	winners([(0, 1, 500), (3, 1600, 700), (7, 5068, 700)]) = [(0, 1, 500)] 
	*)
	(*
		INFO:		Collects all winners (from a list of players p contributed to the pot) to a list.
		USED BY: 	winnersMinPot(w), cashToWinners(w, l)
	*)
	fun winners [] = [] 
	| winners ((x as (p, h, m))::xs) =
		let 
			fun winners'([], bestPl, _) = bestPl
			| winners'((x' as (p', h', m'))::xs, bestPl, bestHa) =
				if h' < bestHa then
					winners'(xs, [x'], h')
				else if h' = bestHa then
					winners'(xs, x'::bestPl, bestHa)
				else
					winners'(xs, bestPl, bestHa)
		in
			winners'(xs, [x], h)
		end;
	(*
		winnersMinPot l
		TYPE: 		(int * int * int) list -> sidepot
		PRE:		(none)
		POST:		A new Sidepot. 
		EXAMPLE: 	winnersMinPot([(0, 1, 500), (1, 1, 1500)]) = Sidepot ([(0, 1, 500)], 500): sidepot 
	*)
	(*
		INFO:		Get all the winners from winners(l) with minimum pot into a sidepot.
		USED BY: 	cashFromLosers(l, p), rmMinPotWinner(m, l)
	*)
	fun winnersMinPot([]) = []
	| winnersMinPot((x as (p, h, m))::xs) =
		let
			fun winnersMinPot'([], leastPl, _) = leastPl
			| winnersMinPot'((x' as (p', h', m'))::xs, leastPl, least) =
				if m' < least then
					winnersMinPot'(xs, [x'], m')
				else if m' = least then
					winnersMinPot'(xs, x'::leastPl, least)
				else
					winnersMinPot'(xs, leastPl, least)
		in
			winnersMinPot'(xs, [x], m)
		end;
	
	(*
		cashFromLosers 
		TYPE:		('a * ''b * int) list * ('c * ''b * int) list -> int
		PRE:
		POST:
		EXAMPLE:
	*)
	fun cashFromLosers([], _) = 0
	| cashFromLosers((p, h, m)::xs, org) = 
		let
			fun cashFromLosers'([], _, _, totMoney) = totMoney
			| cashFromLosers'((p', h', m')::xs', hand, money, totMoney) =
				if hand <> h' then
					if m' >= money then
						cashFromLosers'(xs', hand, money, totMoney+money)
					else 
						cashFromLosers'(xs', hand, money, totMoney+m')
				else
					cashFromLosers'(xs', hand, money, totMoney)
		in
			cashFromLosers'(org, h, m,  0)
		end;
	(*
		mkSidePot
		TYPE:		(int * int * int) list * int -> sidepot
		PRE:
		POST:
		EXAMPLE:
	*)		
	fun mkSidePot([], _) = emptyPot 
	| mkSidePot(winners, tot) =
		let
			val players = length winners
			val cashEach = tot div players
			
			fun mkSidePot'([], _, winners, tot) = Sidepot(winners, tot)
			| mkSidePot'((p, h, m)::xs, cashEach, winners, tot) =
				mkSidePot'(xs, cashEach, (p, h, m+cashEach)::winners, tot)
		in
			mkSidePot'(winners, cashEach, [], tot)
		end;

	(*
		mkNewList
		TYPE:		('a * 'b * int) list * ('c * 'd * int) list -> ('a * 'b * int) list
		PRE:		(none)
		POST:
		EXAMPLE:
	*)
	fun mkNewList(org, (p, h, m)::xs) = 
		let
			fun mkNewList'([], _) = [] 
			| mkNewList'((p', h', m')::xs', money) =
				if m' <= money then
					mkNewList'(xs', money)
				else
					(p', h', m'-money)::mkNewList'(xs', money)				
		in
			mkNewList'(org, m)
		end;
	(*
		showDown
		TYPE:		(int * int * int) list -> sidepot list 
		PRE:
		POST:
		EXAMPLE:
	*)
	fun showDown([]) = []
	| showDown p = 
		let
			val winners = winners(p)							(*Winners -> list*)
			val minPot = winnersMinPot(winners)					(*Takes the winner's min pot*)
			val loserCash = cashFromLosers(minPot, p)			(*Grabs losers money-minPot*)
			val mkSidepot = mkSidePot(winners, loserCash)		(*Makes a sidepot out of the winners*)
			val mkNewList = mkNewList(p, minPot)				(*Subtract minPot from original list, remove players with money = 0 *)
		in
			mkSidepot::showDown(mkNewList)						(*Cons Sidepot and repeat process.*)
		end;
	
	(*
		printShowDown l
		TYPE:		sidepot list -> string
		PRE:		(none)
		POST:		l in text as a string. 
		EXAMPLE:	showDown([(0, 1, 500), (1, 1, 700), (3, 1600, 2500), (7, 5068, 2000)]) =
		 			"0 and 1 split a pot of $1000.\n1 won a pot of $400.\n3 won a pot of $1300.\n": string
	*)
	(*
		INFO: 		Returns information of all the players involved in the sidepot. 
	*)

	fun printShowDown([]) = ""
	| printShowDown(Sidepot(players as (p, h, m)::xs, t)::rest) = 
		let 
			val antPlayers = length players
			val intStr = Int.toString

			fun printShowDown'([], t, rest) = "split a pot of $"^intStr(t)^".\n"^printShowDown(rest)
			| printShowDown'(player as (p, h, m)::xs, t, rest) =
				if xs = [] then
					intStr(p)^" "^printShowDown'(xs, t, rest)
				else
					intStr(p)^" and "^printShowDown'(xs, t, rest)
		in
			if antPlayers = 1 then
				intStr(p)^" won a pot of $"^intStr(t)^".\n"^printShowDown(rest)
			else
				printShowDown'(players, t, rest)
		end;

end;