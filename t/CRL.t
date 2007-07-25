#!perl -w

use strict;
use warnings;

=head1 NAME

CRL.t - test the CRL in a various way.
=cut

use Test::More no_plan => 1;

BEGIN {
    use_ok 'Catalyst::Test', 'App::CamelPKI';
    use_ok 'Test::Group';
    use_ok 'Catalyst::Utils';
    use_ok 'App::CamelPKI::Test';
}

my $webserver = App::CamelPKI->model("WebServer")->apache;
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();
my ($CAcert, $CAkey) = App::CamelPKI->model("CA")->make_admin_credentials;

test "CRL in plain text" => sub {
	my $response = call_remote
   		("https://localhost:$port/ca/gen_crl",
   			-certificate => $CAcert, -key => $CAkey);
	like($response, qr/-----BEGIN X509 CRL-----/);
	like($response, qr/-----END X509 CRL-----/);
};



