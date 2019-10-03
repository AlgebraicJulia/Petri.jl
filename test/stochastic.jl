using Petri


seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])
