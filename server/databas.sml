(* 
	REPRESENTATION CONVENTION: 	Dbplayer(name, money): Represents a player
	 							where name is the player's name and money
								is the player's money in a database.
								
	REPRESENTATION INVARIANT: 	No dublicates of name. 
								money >= 0 
*)
datatype Dbplayer = Dbplayer of string * int;

(*
	emptyPlayer
	TYPE: 		Dbplayer
	VALUE: 		An empty Dbplayer. 
*)
val emptyPlayer = Dbplayer("", 0);

(*
	db_Name
	TYPE: 		string
	VALUE: 		A file name. 
*)
val db_Name = "medlemsdatabas.txt";

(*
	db_readAll (h, a)
	TYPE: 			TextIO.instream * string -> string
	PRE:			h is a real file. 
	POST:			h as a string and a as start value.
	SIDE-EFFECTS: 	Writes a to h. 
	EXAMPLE:		db_readAll("medlemsdatabas.txt", "hej") = ()
*)
fun db_readAll (h, acc) = 
    let
        val s = TextIO.inputLine h
    in
        case s
            of SOME (s)   => db_readAll (h, acc ^ s)
             | NONE       => acc
    end

(*
	db_renderToFile(q, n)
	TYPE:			string * string -> unit
	PRE:			n is a real file. 
	POST:			()
	SIDE-EFFECTS: 	Flushes the file n and writes q to file. 
	EXAMPLE:		db_renderToFile("test", "test.txt") = ()
*)
fun db_renderToFile(qt, name) =
	    let
	        val h = TextIO.openOut name
	    in
	        TextIO.outputSubstr(h, Substring.full(qt));
	        TextIO.flushOut(h)
	    end;

(*
	db_chopJsonInt x
	TYPE: 		JSON.T -> int
	PRE: 		(none)
	POST:		x as an int. 
	EXAMPLE:	db_chopJsonInt[JSON.Int 2] = 2: int
*)
fun db_chopJsonInt (JSON.Int x) = x;
(*
	db_chopJsonString x
	TYPE: 		JSON.T -> string
	PRE: 		(none)
	POST:		x as a string. 
	EXAMPLE:	db_chopJsonString[JSON.String "hej"] = "hej": string
*)
fun db_chopJsonString (JSON.String x) = x; 
(*
	db_getMoney(db)
	TYPE: 		Dbplayer -> int
	PRE: 		(none)
	POST: 		An int.
	EXAMPLE: 	
*)
fun db_getMoney(Dbplayer(pl, m)) = m;
(*
	db_findPlayer p
	TYPE: 			string -> bool
	PRE: 			(none)
	POST: 			True if p exists in the database.
	EXAMPLE: 		db_findPlayer("Joel") = True: bool		
*)
fun db_findPlayer(pl) = 
	let 
		val player = pl
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val db = JSONEncoder.parse(db)
		val JSON.List users = JSON.get db "users"

		fun db_findPlayer'([]) = (TextIO.closeIn x;emptyPlayer)
		| db_findPlayer'(x'::xs') = 
			if JSON.toString(JSON.get x' "Name") = player then
				(TextIO.closeIn x;Dbplayer(JSON.toString(JSON.get x' "Name"), db_chopJsonInt(JSON.get x' "Cash")))
			else
				db_findPlayer'(xs')
		
	in
		db_findPlayer'(users)
	end;
(*
	db_addPlayer pl, pw
	TYPE: 			string * string -> unit
	PRE: 			(none)
	POST: 			()
	SIDE-EFFECTS: 	Reads a string, encodes it to JSON, adds pl and pw to it and outputs it
					back to the file.
	EXAMPLE: 		db_addPlayer("Joel", "12345") = ()
*)

fun db_addPlayer(pl, pw) = 
	let 
		val player = pl
		val password = SHA1.hash pw
		val money = 1000
		
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val db = JSONEncoder.parse(db)
		val JSON.List users = JSON.get db "users"
		
		val pid = db_chopJsonInt(JSON.get db "primaryid")
		val newid = pid + 1
		val db = JSON.update ("primaryid", (JSON.Int newid)) db
		
		val	y = JSON.empty
		val y = JSON.add ("ID", (JSON.Int pid)) y
		val y = JSON.add ("Name", (JSON.String player)) y
		val y = JSON.add ("Pwd", (JSON.String password)) y
		val y = JSON.add ("Cash", (JSON.Int money)) y
		val users = JSON.List (y::users)
		
		val db = JSON.update ("users", users) db
		val db = JSON.encode db
		
	in
		db_renderToFile(db, db_Name)
	end;
(*
	db_regPlayer pl, pw
	TYPE: 			string * string -> unit
	PRE: 			(none)
	POST: 			()
	SIDE-EFFECTS: 	If pl exists, reads a string, encodes it to JSON, adds pl and pw 
					to it and outputs it back to the file.
	EXAMPLE: 		db_regPlayer("Joel", "12345") = ()
*)
fun db_regPlayer(pl, pw) = 
	let 
		exception usernameExists
	in
		if db_findPlayer(pl) = emptyPlayer then
			db_addPlayer(pl, pw)
		else
			 raise usernameExists
	end;

(*
	db_loginPlayer pl, pw
	TYPE: 			string * string -> bool
	PRE: 			(none)
	POST: 			True if pl and pw is the same as in the database.
	EXAMPLE: 		db_regPlayer("Joel", "12345") = true
*)
fun db_loginPlayer(pl, pw) =
	let 
		val player = pl
		val password = SHA1.hash pw
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val db = JSONEncoder.parse(db)
		val JSON.List users = JSON.get db "users"
		
		(*
			db_loginPlayer' l
			TYPE:		JSON list -> bool
			PRE:
			POST:
			EXAMPLE:
		*)
		fun db_loginPlayer'([]) = (TextIO.closeIn x;false)
		| db_loginPlayer'(x'::xs') = 
			if JSON.toString(JSON.get x' "Name") = player then
				if JSON.toString(JSON.get x' "Pwd") = password then
					(TextIO.closeIn x;true)
				else
					(TextIO.closeIn x;false)
			else
				db_loginPlayer'(xs')
			
	in
		db_loginPlayer'(users)
	end;


(*
	db_updateMoney pl, m
	TYPE: 			string * int -> unit
	PRE: 			(none)
	POST: 			()
	SIDE-EFFECTS: 	Reads a string, encodes it to JSON and outputs it
					back to the file. 
	EXAMPLE: 		db_updateMoney("Joel", 1500) = ()
*)
fun db_updateMoney(pl, m) = 
	let 
		val player = pl
		val money = m
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val db = JSONEncoder.parse(db)
		val JSON.List users = JSON.get db "users"

		fun db_updateMoney'([], db') = ()
		| db_updateMoney'(x::xs, db') = 
			if JSON.toString(JSON.get x "Name") = player then
				let
					val users' = JSON.List ((JSON.update("Cash", (JSON.Int money)) x)::db'@xs)
					val db = JSON.update ("users", users') db
					val db = JSON.encode db
				in
					db_renderToFile(db, db_Name)
				end
			else
				db_updateMoney'(xs, x::db')
			
	in
		db_updateMoney'(users, [])
	end;

(*
	db_dropTable()
	TYPE: 			unit -> unit
	PRE: 			(none)
	POST: 			()
	SIDE-EFFECTS: 	Reads a string, change it to a new string and outputs it
					back to the file.
	ExAMPLE: 		db_dropTable() = (): unit
*)
fun db_dropTable() = 
	let
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val freshTable = "{\"primaryid\":1,\"users\":[]}\n"
	in
		db_renderToFile(freshTable, db_Name)
	end;
	
(*
	db_deletePlayer(pl)
	TYPE: 			string -> unit
	PRE: 			(none)
	POST: 			()
	SIDE-EFFECTS: 	Reads a string, encodes it to JSON, removes pl
					from it and outputs it back to the file.
	EXAMPLE: 		db_deletePlayer("Joel") = (): unit
*)
fun db_deletePlayer(pl) = 
	let 
		val player = pl
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val db = JSONEncoder.parse(db)
		val JSON.List users = JSON.get db "users"

		fun db_deletePlayer'([], db') = 
			let 
				val db' = JSON.List db'
				val db = JSON.update ("users", db') db
				val db = JSON.encode db
			in
				db_renderToFile(db, db_Name)
			end
				
		| db_deletePlayer'(x'::xs', db') = 
			if JSON.toString(JSON.get x' "Name") = player then
				db_deletePlayer'(xs', db')
			else
				db_deletePlayer'(xs', x'::db')
		
	in
		db_deletePlayer'(users, [])
	end;


(*
	db_jsonToList()
	TYPE: 		unit -> dbplayer list
	PRE: 		(none)
	POST: 		A dbplayer list out of all posts in the database. 
	EXAMPLE: 	db_jsonToList() = [Dbplayer ("Joel", 1000), Dbplayer ("Krille", 1000)]: (string * int) list
*)
fun db_jsonToList() = 
	let 
		val x = TextIO.openIn db_Name
		val db = db_readAll (x, "")
		val db = JSONEncoder.parse(db)
		val JSON.List users = JSON.get db "users"
		
		fun db_jsonToList'([], _) = (TextIO.closeIn x;[])
		| db_jsonToList'(x'::xs', n) =
			let
				val jName = db_chopJsonString(JSON.get x' "Name")
				val jCash = db_chopJsonInt(JSON.get x' "Cash")
			in
				Dbplayer (jName, jCash)::db_jsonToList'(xs', n+1)
			end
	in 
		db_jsonToList'(users, 1)
	end; 

(*
	db_topList n 
	TYPE:		int -> dbplayer list
	PRE:		n > 0 
	POST:		A dbplayer list with n elements. 	
	EXAMPLE: 	db_topList(10) = [Dbplayer ("Joel", 1500), Dbplayer (Krille, 1000), Dbplayer (Jocke, 1000)]
*)
fun db_topList(0) = []
| db_topList(n) = 
	let
		fun quickSort (nil) = nil
		|   quickSort (l) = 
			let 
				val Dbplayer (p, m) = List.nth(l, length(l) div 2)
	        in
				quickSort(List.filter(fn Dbplayer (x, y) => y > m)(l)) @ (Dbplayer (p, m) :: quickSort(List.filter(fn Dbplayer (x, y) => y < m)(l)))
			end;
		
		(* Grab the database*)
		val db = quickSort(db_jsonToList())
		val lDb = length db
	in
		if n > lDb then
			db
		else
			List.take(db, n)
	end;