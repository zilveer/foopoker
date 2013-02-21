(*
	REPRESENTATION CONVENTION: 	Card(x, y) where x is a play card value and y is a play card 
								color. 
	REPRESENTATION INVARIANT: 	x: 2, 3, 4, 5, 6, 7, 8, 9, T, J, Q, K, A
								y: s, c, d, h
*)
datatype card = Card of string * string;

datatype hand = ROYAL | STRAIGHT_FLUSH | FOUR_OF_A_KIND | FULL_HOUSE | FLUSH | STRAIGHT | THREE_OF_A_KIND | TWO_PAIR | ONE_PAIR | HIGH_CARD;

datatype color = CLUB | DIAMOND | HEART | SPADE;

datatype value = Deuce | Trey | Four | Five | Six | Seven | Eight | Nine | Ten | Jack | Queen | King | Ace;

use "vectors.sml";
use "queue.sml";
use "shuffle.sml";
use "showdown.sml";
use "evaluatecards.sml";
use "printtypehand.sml";
use "cardToWord.sml";

(*
	handValue h 
	TYPE: 		hand -> int
	PRE: 		(none)
	POST: 		handType as an integer.
	EXAMPLE: 	handValue(STRAIGHT_FLUSH) = 1; 
*)
(*
	INFO: 		Returns a value for every type of hand. 
	USED BY: 	handRank
*)
fun handValue 	ROYAL = 1
	| handValue STRAIGHT_FLUSH = 2
	| handValue	FOUR_OF_A_KIND = 3 
	| handValue	FULL_HOUSE = 4
	| handValue	FLUSH = 5
	| handValue	STRAIGHT = 6 
	| handValue	THREE_OF_A_KIND = 7 
	| handValue	TWO_PAIR = 8
	| handValue	ONE_PAIR = 9 
	| handValue	HIGH_CARD = 10;

(*
	printHand n 
	TYPE: 		int -> string
	PRE: 		1 <= n <= 9
	POST: 		n as a string. 
	EXAMPLE: 	printHand(1) = "Straight Flush"
*)	
(*
	INFO: 		Prints what type of hand n is. 
*)
fun printHand n = 
	let
		val hands = ["", "Royal Straight Flush", "Straight Flush", "Four of a Kind", "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "One Pair", "High Card"]
		val handList = Vector.fromList(hands)
	in
		Vector.sub(handList, n)
	end;
	
(*
	colorValue v 
	TYPE: 		color -> word
	PRE:		(none)
	POST:		v as word.
	EXAMPLE: 	colorValue(CLUB) = 0wx8000: Word32.word
*)
(*
	INFO: 		Returns a binary for every suit for a card.
*)
fun colorValue 		CLUB = 0wx8000		(*10000000 00000000*)
	| colorValue 	DIAMOND = 0wx4000	(*01000000 00000000*)
	| colorValue 	HEART = 0wx2000		(*00100000 00000000*)
	| colorValue 	SPADE = 0wx1000;	(*00010000 00000000*)
(*
	cardValue c
	TYPE:		value -> int
	PRE:		(none)
	POST:		An integer from 0-12.
	EXAMPLE: 	cardValue(5) = 4:int
*)
(*
	INFO: 		Returns a value for every value of a card. 
*)
fun cardValue 	Deuce = 0
	| cardValue	Trey = 1
	| cardValue	Four = 2 
	| cardValue	Five = 3 
	| cardValue	Six = 4
	| cardValue	Seven = 5 
	| cardValue	Eight = 6 
	| cardValue	Nine = 7
	| cardValue	Ten = 8
	| cardValue Jack = 9
	| cardValue Queen = 10
	| cardValue King = 11
	| cardValue Ace = 12;

(*
	handRank n
	TYPE:		int -> int
	PRE:		(none)
	POST:		An integer. 
	EXAMPLE: 	handRank(6186) = 9: int
*)
(*
	INFO: 		Returns a value for every value of a card. 
*)
fun handRank n = 
	if n > 6185 then
		handValue(HIGH_CARD)
	else if n > 3325 then
		handValue(ONE_PAIR)	
	else if n > 2467 then
		handValue(TWO_PAIR)
	else if n > 1609 then
		handValue(THREE_OF_A_KIND)
	else if n > 1599 then
		handValue(STRAIGHT)
	else if n > 322 then
		handValue(FLUSH)
	else if n > 166 then
		handValue(FULL_HOUSE)
	else if n > 10 then
		handValue(FOUR_OF_A_KIND)
	else if n > 1 then
		handValue(STRAIGHT_FLUSH)
	else
		handValue(ROYAL);

(* 
	Raise (r, playersMoney, bigBlind)
   	TYPE: 		int * int * int -> int * int
   	PRE: 		r, playersMoney, bigBlind >= 0.
   	POST: 		En tupel med totalsumman totalSum och den minsta
	 			tillåtna satsningen leastAcceptableRaise.
   	EXAMPLE: 	Raise (100, 50, 20) = Exception
	    		Raise (10, 50, 20) = Exception
	    		Raise (30, 50 ,20) = (50, 30)
*)

fun Raise (raiseWith, playersMoney, bigBlind) =
    let
		exception notEnoughMoney;
		exception toSmallRaise;
		val totalSum = raiseWith + bigBlind;
        val leastAcceptableRaise = raiseWith
    in
		if (raiseWith > playersMoney) then
	    	raise notEnoughMoney
		else if (raiseWith < bigBlind) then
	    	raise toSmallRaise
		else 
			(totalSum, leastAcceptableRaise)
    end;

(* 
	Call (call, playerMoney)
   	TYPE: 		int * int -> int
   	PRE: 		call, playerMoney >= 0
   	POST: 		Ger call efter jämförelse med playerMoney.
   	EXAMPLE: 	Call (60, 50) = Exception
	    		Call (40, 50) = 40
*)
fun Call (call, playerMoney) = 
    let
		exception notEnoughMoney;
    in
		if (call > playerMoney) then
	    	raise notEnoughMoney
		else 
			call
    end;

(*	
	bitDeck n 
	TYPE: 		int -> Word32.word list
	PRE: 		n = 52
	POST: 		A Word32.word list. 
	EXAMPLE: 	bitDeck(52) = [0wx2, 0wx3, 0wx5, 0wx7, 0wxB, 0wxD, 0wx11, 0wx13, 0wx17, 0wx1D, ...]:
	   			Word32.word list
*)
(*
	INFO: 		Returns a list of 52 cards which are represented by words. 
	
 				+--------+--------+--------+--------+
				|xxxbbbbb|bbbbbbbb|cdhsrrrr|xxpppppp|
				+--------+--------+--------+--------+

				p = prime number of rank (deuce=2,trey=3,four=5,...,ace=41)
				r = rank of card (deuce=0,trey=1,four=2,five=3,...,ace=12)
				cdhs = suit of card (bit turned on based on suit of card)
				b = bit turned on depending on rank of card

				Using such a scheme, here are some bit pattern examples:

				xxxAKQJT 98765432 CDHSrrrr xxPPPPPP
				00001000 00000000 01001011 00100101    King of Diamonds
				00000000 00001000 00010011 00000111    Five of Spades
				00000010 00000000 10001001 00011101    Jack of Clubs
*)
fun bitDeck 0 = []
| bitDeck n = 
	let 
		val orb = Word32.orb
		val w32Int = Word32.fromInt
		val wInt = Word.fromInt
		val wLeft = Word32.<<
		val wRight = Word32.>>
		val suit = 0wx8000
		
		fun bitDeck' (0, _, _) = []
		 | bitDeck' (n', j, suit) = 	
			if j < 12 then				(*Populate a card[0-12] with the form above*)
				orb(orb(orb(w32Int(getPrime(j)), wLeft(w32Int(j), wInt(8))), suit), wLeft(w32Int(1), wInt(16+j)))::bitDeck'(n'-1, j+1, suit)
			else						(*Change suit*)
				orb(orb(orb(w32Int(getPrime(j)), wLeft(w32Int(j), wInt(8))), suit), wLeft(w32Int(1), wInt(16+j)))::bitDeck'(n'-1, 0, wRight(suit, Word.fromInt(1)))	
	in
		bitDeck' (n, 0, suit)
	end;

val test = [(0, 1, 500), (1, 1, 700), (3, 1600, 2500), (7, 5068, 2000)];
val b = showDown(test);

(*
	printShowDown l
	TYPE:		sidepot list -> string
	PRE:		(none)
	POST:		l in text as a string. 
	EXAMPLE:	showDown([(0, 1, 500), (1, 1, 700), (3, 1600, 2500), (7, 5068, 2000)]) =
	 			"1 and 0 split a pot of 1000. \n1 won a pot of $2400.\n3 won a pot of $300.\n": string
*)
(*
	INFO: 		Returns information of all the players involved in the sidepot. 
*)

fun printShowDown([]) = ""
| printShowDown(Sidepot(players as (p, h, m)::xs, t)::rest) = 
	let 
		val antPlayers = length players
		val intStr = Int.toString
		
		fun printShowDown'([], t, rest) = "split a pot of $"^intStr(t)^".<br>"^printShowDown(rest)
		| printShowDown'(player as (p, h, m)::xs, t, rest) =
			if xs = [] then
				intStr(p)^" "^printShowDown'(xs, t, rest)
			else
				intStr(p)^" and "^printShowDown'(xs, t, rest)
	in
		if antPlayers = 1 then
			intStr(p)^" won a pot of $"^intStr(t)^".<br>"^printShowDown(rest)
		else
			printShowDown'(players, t, rest)
	end;


val a = cardToWord(Card("A", "h"));
val b = cardToWord(Card("T", "h"));
val c = cardToWord(Card("Q", "h"));
val d = cardToWord(Card("J", "h"));
val e = cardToWord(Card("8", "c"));
val f = cardToWord(Card("T", "s"));
val g = cardToWord(Card("K", "h"));

print("\nBest 5-hand:\n");
print(printHand(handRank(eval5Cards(a,b,c,d,e)))^", "^printTypeHand(a, b, c, d, e)^"\n");
print("\nBest 6-hand:\n");
printHand(handRank(eval_6hand(a,b,c,d,e,f)));
print("\nBest 7-hand:\n");
printHand(handRank(eval_7hand(a,b,c,d,e,f,g)));
print_eval_7hand(a,b,c,d,e,f,g);
print(Int.toString(eval_7hand(a,b,c,d,e,f,g))); 
