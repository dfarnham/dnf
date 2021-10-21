## dnf
 
Lex/Yacc command line "Disjunctive Normal Form" tool

Information
===========
Lex/Yacc command line "Disjunctive Normal Form" tool

Example
-------
$ dnf<br/>
dnf: Quit with ^D<br/>
&gt; (a || b) && (c || d)<br/>
(((c && a) || (d && a)) || ((c && b) || (d && b)))<br/>

&gt; !(a || b) && (c || d)<br/>
((c && ((!a) && (!b))) || (d && ((!a) && (!b))))<br/>
