:- use_module(library('semweb/rdf_db')).
:- use_module(library('http/http_open')).
:- use_module(library('http/json')).
:- use_module(library(rdf_write)).

:- rdf_load('jamendo_t'), grab_lyrics, dump_lyrics.

grab_lyrics :-
    setof(A, rdf(A, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'http://purl.org/ontology/mo/MusicArtist'), Set),!,
    split_set(Set, 50, Subset),
    track_ids(Subset, Ids),
    jamendo_query(Ids, Query),
    get_json(Query, List),
    create_rdf(List),
    fail.
dump_lyrics :-
    bagof(rdf(A,B,C), (rdf(A,B,C,lyrics), C\==literal(@null)), RDF),
    open('jamendo-lyrics.rdf', 'write', S),
    rdf_write_xml(S, RDF),
    close(S).

split_set(Set, Num, Subset) :-
    append(Subset2, Rest, Set),
    length(Subset2, Num),
    (Subset=Subset2; split_set(Rest, Num, Subset)).

create_rdf([]).
create_rdf([json([id=_,text='@null'])|T]) :-
    !,
    create_rdf(T).
create_rdf([json([id=_,text=''])|T]) :-
    !,
    create_rdf(T).
create_rdf([json([id=ID,text=Text])|T]) :-
    atom_concat('http://dbtune.org/jamendo/track/', ID, Track),
    atom_concat('http://dbtune.org/jamendo/lyrics/', ID, Lyrics),
    rdf_assert(Track, 'http://purl.org/ontology/mo/lyrics', Lyrics, lyrics), 
    rdf_assert(Lyrics, 'http://purl.org/ontology/mo/text', literal(Text), lyrics),
    create_rdf(T).

track_ids([], []) :- !.
track_ids([H|T], [Id|T2]) :-
    atom_concat('http://dbtune.org/jamendo/artist/', Id, H),
    track_ids(T, T2).

jamendo_query(List, Query) :-
    atomic_list_concat(List, '+', Query).

get_json(Query, Json) :-
    atom_concat('http://api.jamendo.com/get2/id+text/track/json/?id=', Query, URL),
    write(URL),write('\n'),
    http_open(URL, In, []),
    json_read(In, Json),
    close(In).
