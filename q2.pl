%clears database before game is launched
:- abolish(suspects/1).
:- abolish(rooms/1).
:- abolish(weapons/1).
:- abolish(numplayers/1).
:- abolish(myturnposition/1).
:- abolish(turncounter/1).
:- abolish(suggestedsuspect/1).
:- abolish(suggestedroom/1).
:- abolish(suggestedweapon/1).

%required for assert and retract
:-dynamic suspects/1.
:-dynamic rooms/1.
:-dynamic weapons/1.
:-dynamic numplayers/1.
:-dynamic myturnposition/1.
:-dynamic turncounter/1.
:-dynamic suggestedsuspect/1.
:-dynamic suggestedroom/1.
:-dynamic suggestedweapon/1.

%launch game by typing play
play :- writeln('Welcome to Clue Assistant!'), setSuspects, setRooms, setWeapons, setMySuspects, setMyRooms, 
		setMyWeapons, getNumPlayers, getYourTurnPosition, startGame.

%adds initial suspects to database
setSuspects :- writeln('Please enter all of the SUSPECTS in this version of Clue. When you are done, enter done.'),
			   read(Suspect),
			   (Suspect \= done -> 
			        assert(suspects(Suspect)),
		            setSuspects); true.

%adds initial rooms to database
setRooms :- writeln('Please enter all of the ROOMS in this version of Clue. When you are done, enter done.'),
			read(Room),
			(Room \= done -> 
			     assert(rooms(Room)),
		         setRooms); true.

%adds initial rooms to database
setWeapons :- writeln('Please enter all of the WEAPONS in this version of Clue. When you are done, enter done.'),
			  read(Weapons),
			  (Weapons \= done -> 
			     assert(weapons(Weapons)),
		         setWeapons); true.

%prompts user for the suspect cards in hand, then removes them from the suspects db.
setMySuspects :- writeln('Please enter all of the SUSPECTS in your hand. When you are done, enter done.'),
			  read(Suspect),
			  (Suspect \= done -> 
			     retract(suspects(Suspect)),
		         setMySuspects); true.

%prompts user for the room cards in hand, then removes them from the rooms db.
setMyRooms :- writeln('Please enter all of the ROOMS in your hand. When you are done, enter done.'),
			  read(Room),
			  (Room \= done -> 
			     retract(rooms(Room)),
		         setMyRooms); true.

%prompts user for the weapon cards in hand, then removes them from the rooms db.
setMyWeapons :- writeln('Please enter all of the WEAPONS in your hand. When you are done, enter done.'),
			  read(Weapon),
			  (Weapon \= done -> 
			     retract(weapons(Weapon)),
		         setMyWeapons); true.


getNumPlayers :- writeln('How many number of players are there?'), read(NumPlayers), assert(numplayers(NumPlayers)).

%works. also assert first element of turncounter database.
getYourTurnPosition :- writeln('When is it your turn?'), 
					   read(YourTurnPosition),
			           assert(myturnposition(YourTurnPosition)),
			           assert(turncounter(1)),
			           writeln('Ok, we are all set. Time to play!').

%end of board setup.

%start of game play
%need to add control at beginning to take care of turn taking.
%need to pass NumPlayers into isItYourTurn
startGame :-  aggregate_all(count, turncounter(Y), I), 
			 (findall(W, myturnposition(W), W), getFirst(J, W)),
			 (findall(X, numplayers(X), X), getFirst(K, X)),
			 (not(isItYourTurn(I, J, K)) ->
			      didPrevPlayerMakeSuggestion); usersTurn.

usersTurn :- writeln('Now it is your turn.'), writeln('Are you in a room?'),
		     read(InRoom),
		     (InRoom = y ->
		     	writeln('Which room are you in?'),
		     	read(CurrRoom),
		     	genSuggestion, writeln(CurrRoom),
		     	wereYouProvenWrong

		     	);writeln('END TURN'). %end InRoom

wereYouProvenWrong :- writeln('Was your suggestion proven WRONG?'),
			   		  read(SuggestionProven),
			   		  (SuggestionProven = y	->
					       elimCard); winCheck.


%if there is 1 item in each of the suspects, rooms, and weapons databases, then an accusation should be made.
winCheck :- aggregate_all(count, suspects(X), Count), aggregate_all(count, rooms(Y), Count), aggregate_all(count, weapons(Z), Count),
			(((X=1),(Y=1),(Z=1)) -> makeAccusation); endOppsTurn.

makeAccusation :- findall(X, suspects(X), X), getFirst(A, X),
				  findall(Y, rooms(Y), Y), getFirst(B, Y),
				  findall(Z, weapons(Z), Z), getFirst(C, Z),
				  write('I accuse that '), write(A), write(' did it in the '), write(B), write(' with the '), writeln(C),
				  writeln('Was your accusation correct? (y/n)'), read(MyAcc),
				  (MyAcc = y ->
				  	 youWin	); youLose.


%this can be refactored by saving the suggestion you made. after you get CardType, you can automatically retract the card you suggested.
elimCard :- writeln('Was the card that proved you wrong a suspect, room, or weapon?'), read(CardType),
			(CardType = suspect -> elimSuspect;
			 CardType = room -> elimRoom;
			 CardType = weapon -> elimWeapon
			); true.

elimSuspect :- writeln('Which suspect was shown to you?'), read(ShownCard),
			   retract(suspects(ShownCard)),endOppsTurn.

elimRoom :- writeln('Which room was shown to you?'), read(ShownCard),
			retract(rooms(ShownCard)),endOppsTurn.

elimWeapon :- writeln('Which weapon was shown to you?'), read(ShownCard),
			  retract(weapons(ShownCard)),endOppsTurn.

%takes the first element in the suspects and weapons database to generate a suggestion.
genSuggestion :- findall(X, suspects(X), X), getFirst(A, X),
				 findall(Y, weapons(Y), Y), getFirst(B, Y),
				 write('I suggest that '), write(A), write(' did it with the '), write(B), write(' in the ').

%works.
%Refactor when turn-taking controls are implemented.
didPrevPlayerMakeSuggestion :- writeln('Did the other player make a suggestion? (y/n)'),
							   read(PrevPlayerSugg),
							   (PrevPlayerSugg = y -> 
			    
			           		   (getOpponentSuggestion ->
			           		   	provenWrong

			           		   %ends getOpponentSuggestion
			           		   ); didPrevMakeAccusation

			           		   ); false. %ends PrevPlayerSugg

%works
didPrevMakeAccusation :- writeln('Did the other player make an accusation? (y/n)'), 
						 read(PrevAcc),
						 (PrevAcc = y -> 
						 	(writeln('Was the accusation correct? (y/n)'), 
						 	read(AccCheck),
						 	(AccCheck = y -> 
						 		youLose); 
						 		(findall(X, numplayers(X), X), getFirst(K, X)), (Y is K-1), asserta(numplayers(Y)),endOppsTurn  )); 
						 endOppsTurn.


%used to record suggestions from other players
%need to retract at the end of each turn

getOpponentSuggestion :- getOppSuspect, getOppRoom, getOppWeapon.


getOppSuspect :- writeln('Who was the suggested SUSPECT?'),
			   read(Suspect),
			   assert(suggestedsuspect(Suspect)).


getOppRoom :- writeln('Who was the suggested ROOM?'),
			   read(Room),
			   assert(suggestedroom(Room)).


getOppWeapon :- writeln('Who was the suggested WEAPON?'),
			    read(Weapon),
			    assert(suggestedweapon(Weapon)).

provenWrong :- writeln('Was the suggestion proven WRONG?'),
			   read(SuggestionProven),
			   evalSuggestionProven(SuggestionProven).

evalSuggestionProven(SuggestionProven) :- (SuggestionProven = y	->
										   elimSuspectIfPossible, elimRoomIfPossible, elimWeaponIfPossible, endOppsTurn); writeln('Suggestion was NOT proven wrong').

%retract a suggested card from the database only if it is guaranteed that the card can be removed.
%Example: elimSuspectIfPossible: if the suggested suspect was in the suspects database && (the suggested room was not in the rooms database && the suggested weapon was not in the weapons database),
%then retract the suggested suspect from the suspects db.

elimSuspectIfPossible :- (((findall(X, suspects(X), X), 
				  		 (suggestedsuspect(Y), member(Y, X))), 
				  		 ((findall(A, rooms(A), A),
				  		 not((suggestedroom(B), member(B, A)))),
				  		 (findall(C, weapons(C), C),
				  		 not((suggestedweapon(D), member(D, C)))))) -> retract(suspects(Y))); true.

elimRoomIfPossible :- (((findall(X, rooms(X), X), 
				      (suggestedroom(Y), member(Y, X))), 
				  	  ((findall(A, suspects(A), A),
				  	  not((suggestedsuspect(B), member(B, A)))),
				  	  (findall(C, weapons(C), C),
				  	  not((suggestedweapon(D), member(D, C)))))) -> retract(rooms(Y))); true.

elimWeaponIfPossible :- (((findall(X, weapons(X), X), 
				  	    (suggestedweapon(Y), member(Y, X))), 
				  	    ((findall(A, rooms(A), A),
				  	    not((suggestedroom(B), member(B, A)))),
				  		(findall(C, suspects(C), C),
				  		not((suggestedsuspect(D), member(D, C)))))) -> retract(weapons(Y))); true.

endOppsTurn :- writeln('TURN OVER'),assert(turncounter(1)), clearSuggestions, startGame.

clearSuggestions :- retractall(suggestedsuspect(X)), retractall(suggestedroom(X)), retractall(suggestedweapon(X)).

member(X,[X|T]).
member(X,[H|T]) :- member(X,T).

getFirst(X, [X|T]).

youLose :- writeln('Sorry. You Did Not Win').
youWin :- writeln('Yay! You won!').

%NEED TO FIX. SHOULD FACTOR IN NUMPLAYERS.
isItYourTurn(I, J, K) :- ((I =< K), (I == J));((Y is (I mod K)), Y == J, I>K).