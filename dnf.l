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

/*
 * Local functions
 */
void    copystr (struct _Buffer *, char *);
%}

%option noyywrap
%option nounput

%%
[ \t] ;  /* Ignore spaces and tabs */

\&\&                   { return AND; }
\|\|                   { return OR;  }
\!                     { return NOT; }
\<                     { return LT;  }
\<\=                   { return LE;  }
\>                     { return GT;  }
\>\=                   { return GE;  }
\=\=                   { return EQ;  }
\!\=                   { return NE;  }
[a-zA-Z][a-zA-Z0-9_]*  { copystr(&Ident, yytext); return IDENT; }
[^ \t]                 { return((int)yytext[0]); } /* anything else just return it */
%%

void
copystr(struct _Buffer *b, char *str) {
    if (strlen(str) > b->len) {
        b->len = strlen(str);
        if (b->buf)
            free(b->buf);
        if (!(b->buf = (char *)malloc(b->len+1))) {
            perror("copystr:out of memory");
            exit(1);
        }
    }
    strcpy(b->buf, str);
}
