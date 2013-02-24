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
use "shuffledeck.sml";
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
	INFO: 		***Cactus Kev's Poker Hand Evaluator***
				Returns a value for every type of hand. 
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
	INFO: 		***Cactus Kev's Poker Hand Evaluator***
				Prints what type of hand n is. 
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
	INFO: 		***Cactus Kev's Poker Hand Evaluator***
				Returns a binary for every suit for a card.
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
	EXAMPLE: 	cardValue(5) = 4: int
*)
(*
	INFO: 		***Cactus Kev's Poker Hand Evaluator***
				Returns a value for every value of a card. 
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
	INFO: 		***Cactus Kev's Poker Hand Evaluator***
				Returns a value for every value of a card. 
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


val a = cardToWord("Ah");
val b = cardToWord("Kh");
val c = cardToWord("Qh");
val d = cardToWord("Jh");
val e = cardToWord("Th");
val f = cardToWord("Ac");
val g = cardToWord("As");

print("\nBest 5-hand:\n");
print(printHand(handRank(eval5Cards(a,b,c,d,e)))^", "^printTypeHand(a, b, c, d, e)^"\n");
print("\nBest 6-hand:\n");
printHand(handRank(eval_6hand(a,b,c,d,e,f)));
print("\nBest 7-hand:\n");
printHand(handRank(eval_7hand(a,b,c,d,e,f,g)));
print_eval_7hand(a,b,c,d,e,f,g);
print(Int.toString(eval_7hand(a,b,c,d,e,f,g))); 

print("\n\n");


val a = [1,2,3,4,5];
val b = ["a", "b", "c", "d", "e"];
 