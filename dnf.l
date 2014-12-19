%{
/*
 * dnf.l
 * Dave Farnham -- initial
 * Fri Jun 21 21:36:05 MDT 2013
 *
 * Based on the white paper:
 *   "KeyNote Policy Files and Conversion to Disjunctive Normal Form for Use in IPsec"
 */
#include "const.h"
#include "y.tab.h"
%}

%option noyywrap
%option nounput

%%
[ \t] ;  /* Ignore spaces and tabs */

&&                     { return AND; }
\|\|                   { return OR;  }
!                      { return NOT; }
\<                     { return LT;  }
\<=                    { return LE;  }
\>                     { return GT;  }
\>=                    { return GE;  }
==                     { return EQ;  }
!=                     { return NE;  }
[a-zA-Z][a-zA-Z0-9_]*  { yylval.sval = strdup(yytext); return IDENT; }
[^ \t]                 { return((int)yytext[0]); } /* anything else just return it */
%%
