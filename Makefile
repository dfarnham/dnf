CC     = gcc
CFLAGS = -O2 -Wall -Wno-unneeded-internal-declaration
LEXER  = flex 
PARSER = bison -y -d
RM     = rm -f

dnf: dnf.y dnf.l const.h tree.h
	$(LEXER) dnf.l
	$(PARSER) dnf.y
	$(CC) $(CFLAGS) y.tab.c lex.yy.c -o $@

test: dnf
	mkTests.sh
	@echo "MD5 of original expressions"
	expr-test.pl | md5
	@echo "MD5 of expressions in DNF"
	dnf-test.pl | md5

clean:
	$(RM) dnf y.tab.[ch] lex.yy.c expr-test.pl dnf-test.pl
