#!perl -w

use strict;

=head1 NAME

acceptance-issue-certificates.t - Query a live Camel-PKI CA server over
a form using an administrator certificate, and have it issue some
new certificates.

=cut

use Test::More no_plan => 1;

use App::CamelPKI::Certificate;
use App::CamelPKI::PrivateKey;
use App::CamelPKI;
use App::CamelPKI::Test;

my $webserver = App::CamelPKI->model("WebServer")->apache;
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

=pod

The data structure to complete the form data.

=cut

my $reqVPN = {
		("dns" => "foo.bar.com")
};

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::VPN/certify>.

=cut

my ($certCA, $keyCA) = App::CamelPKI->model("CA")->make_admin_credentials;

my $response = formcall_remote
   	("https://localhost:$port/ca/template/vpn/certifyForm", $reqVPN,  "Submit",
   	 -certificate => $certCA, -key => $keyCA);
    
like($response, qr/-----BEGIN CERTIFICATE-----/, "Certificate is in the answer (VPN)");
like($response, qr/-----BEGIN RSA PRIVATE KEY-----/, "Private Key is in the answer (VPN)");


my ($cert, $key) = split(/-----END CERTIFICATE-----\n/,$response);
$cert = $cert."-----END CERTIFICATE-----";

my $certificate = App::CamelPKI::Certificate->parse($cert);
like($certificate->get_subject_DN->to_string, qr/$reqVPN->{dns}/, "Dns is present inthe certificate (VPN)");

my $PrivateKey = App::CamelPKI::PrivateKey->parse($key);
is ($certificate->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate an dkey fitted together (VPN)");