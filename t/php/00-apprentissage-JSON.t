#!/usr/bin/perl -w

use strict;

use App::CamelPKI::Test qw(run_php);

=pod

We are using PHP with JSON. For details, have a look at LISEZMOI
in the same directory and L<App::CamelPKI::Test/run_php>.

=cut

print "1..3\n";

my $json = run_php(<<"SCRIPT");
<?php

print json_encode(Array("zoinx"));

?>
SCRIPT

print "ok 1\n" if ($json =~ m/\[/);
print "ok 2\n" if ($json =~ m/zoinx/);
print "ok 3\n" if ($json !~ m/json_encode/);
