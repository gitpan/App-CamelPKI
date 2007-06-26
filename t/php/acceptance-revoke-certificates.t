#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

acceptance-revoke-certificates.t - Launch acceptance-revoke-certificates.php

=head1 DESCRIPTION

C<acceptance-revoke-certificates.php> generates certificates using a
JSON-RPC call, and revoke them, just like
C<../acceptance-revoke-certificates.t> does in Perl. This Perl script
checks that the PHP code actually works.

=cut

use Test::More no_plan => 1;
use App::CamelPKI;
use App::CamelPKI::Test qw(create_camel_pki_conf_php run_php_script);
use File::Slurp;

my $webserver = App::CamelPKI->model("WebServer")->apache;

$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

create_camel_pki_conf_php();
my $hello = run_php_script("acceptance-revoke-certificates.php");
like($hello, qr/ok/);
#unlike($hello, qr/require_once/,
#       "not interested in the PHP source code :-)");
#like($hello, qr/BEGIN CERTIFICATE/)
#    or diag $webserver->tail_error_logfile;