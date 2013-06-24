CC     = gcc
CFLAGS = -O2 -Wall
LEXER  = flex 
PARSER = bison -y -d
RM     = /bin/rm -f

dnf: dnf.y dnf.l const.h tree.h
	$(LEXER) dnf.l
	$(PARSER) dnf.y
	$(CC) $(CFLAGS) y.tab.c lex.yy.c -o $@

test: dnf
	mkTests.sh
	expr-test.pl | md5
	dnf-test.pl | md5

clean:
	$(RM) dnf y.tab.[ch] lex.yy.c expr-test.pl dnf-test.pl
