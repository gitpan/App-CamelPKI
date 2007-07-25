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



my $reqSSLServer = {
		("template" => "SSLServer",
		"dns" => "foo.foo.com")
};

my $reqSSLClient = {
		("template" => "SSLClient",
		"role" => "bar")
};

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::SSL/certify>.

=cut

my ($CAcert, $CAkey) = App::CamelPKI->model("CA")->make_admin_credentials;

my $response1 = formcall_remote
   	("https://localhost:$port/ca/template/ssl/certifyForm", $reqSSLServer, "Submit",
   	 -certificate => $CAcert, -key => $CAkey);
like($response1, qr/-----BEGIN CERTIFICATE-----/, "Certificate is in response (SSLServer)");
like($response1, qr/-----BEGIN RSA PRIVATE KEY-----/, "Private key is in the response (SSLServer)");

my ($cert, $key) = split(/-----END CERTIFICATE-----\n/,$response1);
$cert = $cert."-----END CERTIFICATE-----";

my $certificate = App::CamelPKI::Certificate->parse($cert);
like($certificate->get_subject_DN->to_string, qr/$reqSSLServer->{dns}/, "Dns present in certificate (SSLServer)");

my $PrivateKey = App::CamelPKI::PrivateKey->parse($key);
is ($certificate->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and keys fitted together (SSLServer)");





my $response2 = formcall_remote
   	("https://localhost:$port/ca/template/ssl/certifyForm", $reqSSLClient,  "Submit",
   	 -certificate => $CAcert, -key => $CAkey);
   	 
like($response2, qr/-----BEGIN CERTIFICATE-----/, "Certificate is in the answer (SSLCLient)");
like($response2, qr/-----BEGIN RSA PRIVATE KEY-----/, "Private Key is in the answer (SSLCLient)");

my ($cert2, $key2) = split(/-----END CERTIFICATE-----\n/,$response2);
$cert2 = $cert2."-----END CERTIFICATE-----";


my $certificate2 = App::CamelPKI::Certificate->parse($cert2);
like($certificate2->get_subject_DN->to_string, qr/$reqSSLClient->{role}/, "role is present in the certificate (SSLClient)");

my $PrivateKey2 = App::CamelPKI::PrivateKey->parse($key2);
is ($certificate2->get_public_key->get_modulus, $PrivateKey2->get_modulus, "Certificate and key fitted together (SSLCLient)");