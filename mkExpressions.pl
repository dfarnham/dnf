#!/usr/bin/env perl

#
# Expression generator
# Generates permutations of sets extracted from @features with AND,OR,NOT

use strict;
use Data::PowerSet;

my @features =  ('a','b','c','d','e');
my @operators = ('&&','||');

my $ps = Data::PowerSet->new({ min => 1 }, \@features);
while (my $r = $ps->next) {
    my @diff = grep { not $_ ~~ @$r } @features;
    
    my @fs1 = ();
    my @fs2 = ();
    genExpressions($r, [], \@fs1);
    if (@diff > 0) {
        genExpressions(\@diff, [], \@fs2);
    }

    foreach my $f1 (@fs1) {
        my $f1str = join(' ', @$f1);

        if (@fs2 > 0) {
            my @final = ();
            foreach my $f2 (@fs2) {
                my $f2str = join(' ', @$f2);
                genExpressions([ "($f1str)", "($f2str)" ], [], \@final);
            }

            foreach my $stmt (@final) {
                print join(' ', @$stmt), "\n";
            }
        } else {
            print $f1str, "\n";
        }
    }
}
exit 0;


sub genExpressions {
    my ($feat, $expr, $results) = @_;

    for (my $i=0; $i<2; $i++) {
        push (@$expr, ( ($i % 2) ? "!" : "" ) . $feat->[0]);

        if (@$feat > 1) {
            foreach my $o (@operators) {
                push (@$expr, $o);
                genExpressions([ @$feat[1..$#$feat] ], $expr, $results);
                pop (@$expr);
            }
        } else {
            push(@$results, [@$expr]);
        }

        pop (@$expr);
    }
}
