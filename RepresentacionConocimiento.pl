%------------------------------------------------------------------------------
% Author: Viren S. Dhanwani Dhanwani
% alu0101230948@ull.edu.es
% Date: 2020 - 12 - 29
% Universidad de La Laguna
% Grado en Ingeniería Informática
% Tercer Curso
% Inteligencia Artificial (Artificial Intelligence)
% Práctica 2 Representación del Conocimiento
%------------------------------------------------------------------------------

:- use_module(library(lists)).

%------------------------------------------------------------------------------
% Declaring dynamic predicates

:- dynamic ([
  board_size/1,
  wumpus_location/1,
  pit_location/1,
  gold_location/1,
  player_location/1,
  exit_location/1,
  visited_cells/1,
  isPit/2,
  isWumpus/2,
  hasGold/1,
  exitFound/1
]).

%------------------------------------------------------------------------------
% Start the game
start :-
  writeln('Práctica 2 IA: Representación del Conocimiento'),
  writeln('¡Bienvenido al mundo del Wumpus!'),
  init,
  draw_map.

%------------------------------------------------------------------------------
% Initialize board

init :-
  (
    reset_map,
    set_map,
    % set_map_two,
    visit([1, 1]),
    assertz(isPit(no, [1, 1])),
    assertz(isWumpus(no, [1, 1])),
    explore([1, 1])
  )
  ;
  (
    hasGold(Q),
    exitFound(EL),
    format('~nSe encontró la salida en la celda ~p y ~p lingotes de oro~n', [EL, Q]),
    !
  ).

%------------------------------------------------------------------------------
% Reset the map 

reset_map :-
  retractall(pit_location(_)),
  retractall(wumpus_location(_)),
  retractall(gold_location(_)),
  retractall(player_location(_)),
  retractall(exit_location(_)),
  retractall(pit_location(_,_)),
  retractall(wumpus_location(_,_)),
  retractall(gold_location(_,_)),
  retractall(isPit(_,_)), 
  retractall(isWumpus(_,_)),
  retractall(hasGold(_)).

%------------------------------------------------------------------------------
% First test map  

set_map :-
  assertz(board_size(4)),
  assertz(wumpus_location([3, 1])),
  assertz(pit_location([1, 3])),
  assertz(pit_location([3, 4])),
  assertz(gold_location([3, 2])),
  assertz(gold_location([4, 1])),
  assertz(player_location([1, 1])),
  assertz(exit_location([4, 4])),
  assertz(visited_cells([])),
  assertz(hasGold(0)).

%------------------------------------------------------------------------------
% Second test map

set_map_two :-
  assertz(board_size(10)),
  assertz(wumpus_location([8, 7])),
  assertz(pit_location([1, 3])),
  assertz(pit_location([2, 5])),
  assertz(pit_location([4, 9])),
  assertz(pit_location([5, 4])),
  assertz(gold_location([1, 7])),
  assertz(gold_location([10, 3])),
  assertz(player_location([1, 1])),
  assertz(exit_location([10, 10])),
  assertz(visited_cells([])),
  assertz(hasGold(0)).

%------------------------------------------------------------------------------
% The player can exit the maze when he has found the exit and has picked all the gold ingots

exited :-
  exitFound(EL),
  hasGold(Q),
  Q = 2,
  retractall(player_location(_)),
  assertz(player_location(EL)). 

%------------------------------------------------------------------------------
% Visits a cell, marks it and checks if the agent has fallen or got eaten by the wumpus

visit(Cell) :-
  exited, !;
  visited_cells(List),
  retractall(visited_cells(_)),
  assertz(visited_cells([Cell|List])),
  retractall(player_location(_)),
  assertz(player_location(Cell)),
  format('~nMe muevo a ~p~n', [Cell]),
  (
    exit_location(Cell) -> assertz(exitFound(Cell)), format('¡Encontré la salida!~n'), !;
    gold_location(Cell) -> 
      hasGold(Q),
      Q1 is Q+1,
      retractall(hasGold(_)),
      assertz(hasGold(Q1)),
      format('¡Encontré oro!~n');
    pit_location(Cell) -> format('Me caí~n'), false;
    wumpus_location(Cell) -> format('Me comió el wumpus~n'), false;
    true
  ).

%------------------------------------------------------------------------------
% Given a Cell [X0, Y0], checks if [X1, Y1] is adjacent
adjacent_cells([X0, Y0], [X1, Y1]) :-
  board_size(Size),
  (
    (X1 is X0 + 1; X1 is X0 - 1), Y1 is Y0, X1 > 0, X1 =< Size;
    (Y1 is Y0 + 1; Y1 is Y0 - 1), X1 is X0, Y1 > 0, Y1 =< Size
  ).

%------------------------------------------------------------------------------
% Stench (Sl) and Breeze (Bl)
% The stench is assigned to the cells adjacent to the wumpus

stench(Sl) :-
  wumpus_location(Ls),
  adjacent_cells(Ls, Sl), !.

% The breeze if assigned to the cells adjacent to a pit

breeze(Bl) :-
  pit_location(Ls),
  adjacent_cells(Ls, Bl), !.

%------------------------------------------------------------------------------
% Adding information about threats to the knowledge base of the agent

% assume_wumpus(maybe, X, Y) checks whether there is stench in X and 
% assumes there may be a wumpus in Y
% If the Y cell was already assumed as maybe by a previous cell, assumes there 
% will not be a wumpus in the cell AC adjacent to X, and explores it  

assume_wumpus(maybe, X, Y) :-
  stench(X),
  isWumpus(maybe, Y) ->
    adjacent_cells(X, AC),
    AC \= Y,
    retractall(isWumpus(_, AC)),
    assertz(isWumpus(no, AC)),
    visited_cells(VC),
    \+ member(AC, VC),
    visit(AC),
    explore(AC);
  visited_cells(Z),
  \+ member(Y, Z),
  retractall(isWumpus(maybe, Y)),
  assertz(isWumpus(maybe, Y)).

% assume_wumpus(no, X, Y) checks if there is no stench in X and assumes there
% will not be a wumpus in Y

assume_wumpus(no, X, Y) :-
  \+ stench(X),
  retractall(isWumpus(_, Y)),
  assertz(isWumpus(no, Y)).

% Same idea as in assume_wumpus(maybe, X, Y) but there may be more than 
% one pit in the map and it checks if there is breeze in X

assume_pit(maybe, X, Y) :-
  breeze(X),
  visited_cells(Z),
  \+ member(Y, Z),
  (
    isPit(no, Y) -> true;
    retractall(isPit(maybe, Y)),
    assertz(isPit(maybe, Y))
  ).

assume_pit(no, X, Y) :-
  \+ breeze(X),
  retractall(isPit(_, Y)),
  assertz(isPit(no, Y)).

%------------------------------------------------------------------------------
% Exploring the map

explore(X) :-
  adjacent_cells(X, Y),
  (
    (assume_wumpus(maybe, X, Y) ; assume_wumpus(no, X, Y)),
    (assume_pit(maybe, X, Y) ; assume_pit(no, X, Y))
  ),
  visited_cells(VC),
  \+ member(Y, VC),
  isWumpus(no, Y),
  isPit(no, Y),
  visit(Y),
  \+ exited,
  explore(Y).

%------------------------------------------------------------------------------
% Drawing the map

draw_map :-
  draw_row([1, 1]) ; true.

draw_row([X, Y]) :-
  board_size(Size),
  (
    Y =< Size ->
      print_element([X, Y]),
      Yp1 is Y+1,
      draw_row([X, Yp1]);

    X < Size ->
      Xp1 is X+1,
      nl,
      draw_row([Xp1, 1])
  ).

print_element(Pos) :-
  player_location(PL),
  Pos = PL -> format(' p ');
  isWumpus(maybe, Pos) -> format(' w?');
  isPit(maybe, Pos) -> format(' o?');
  format(' . ').