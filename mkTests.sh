#!/bin/sh

#
# Generate testing code using the output of "mkExpressions.pl"
#
# Outputs two Perl scripts: expr-test.pl, dnf-test.pl
# expr-test.pl -- the original expressions
# dnf-test.pl  -- dnf transformed expressions

code='#!/usr/bin/env perl
use strict;
#
# This evaluates the expressions for all combinations
# of True/False (0/1) for 5 variables (a,b,c,d,e).
#
for (my $n = 0; $n < 32; $n++) {
    my $b = "";
    for (my $i=4; $i>=0; --$i) {
        $b .= ($n & (1<<$i)) ? "1" : "0";
    }
    my ($a,$b,$c,$d,$e) = split(//,$b);
    exprTest($a,$b,$c,$d,$e);
}

sub exprTest {
    my ($a,$b,$c,$d,$e) = @_;
    my $t = 0;
'

expr_code='expr-test.pl'
#
# Generate code to run expressions in their original form
#
echo "$code" > $expr_code
./mkExpressions.pl | sed -e '/^dnf:/d' -e 's/^> //' -e '/^> /d' -e 's/\([a-e]\)/$\1/g' -e 's/^/$t++; if (/' -e 's/$/) { print "$t\\tT\\n" } else { print "$t\\tF\\n"}/' >> $expr_code
echo 'print "Evaluated $t tests\\n";}' >> $expr_code


dnf_expr_code='dnf-test.pl'
#
# Generate code to run expressions in their dnf form
#
echo "$code" > $dnf_expr_code
./mkExpressions.pl | ./dnf | sed -e '/^dnf:/d' -e 's/^> //' -e '/^$/d' -e 's/\([a-e]\)/$\1/g' -e 's/^/$t++; if (/' -e 's/$/) { print "$t\\tT\\n" } else { print "$t\\tF\\n"}/' >> $dnf_expr_code
echo 'print "Evaluated $t tests\\n";}' >> $dnf_expr_code

chmod +x $expr_code $dnf_expr_code
