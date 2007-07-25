#!perl -w

use strict;
use warnings;

=head1 NAME

03-forRevoke.t : pass tests for revoking certificates using forms.

=cut

use Test::More no_plan => 1;

BEGIN {
    use_ok 'Catalyst::Test', 'App::CamelPKI';
    use_ok 'Test::Group';
    use_ok 'Catalyst::Utils';
    use_ok 'App::CamelPKI::CRL';
    use_ok 'App::CamelPKI::Test';
}

my $webserver = App::CamelPKI->model("WebServer")->apache;
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

=pod

The data structure to complete the form data.

=cut



my $reqSSLServer = {
		("template" => "SSLServer",
		"dns" => "test.foo.com")
};

my $reqSSLServerRevoke = {
	"type" => "dns",
	"data" => "test.foo.com",
};

my $reqSSLClient = {
		("template" => "SSLClient",
		"role" => "test.bar")
};

my $reqVPN = {
		("dns" => "test.foo.bar.com")
};

=pod

The expected response is also laid out in
L<App::CamelPKI::CertTemplate::SSL/certify>.

=cut

my ($CAcert, $CAkey) = App::CamelPKI->model("CA")->make_admin_credentials;

test "Revocation SSLServer" => sub {
	
	my $certSSL = certify("ssl", "SSLServer", "dns", "test.foo.com");
	
	ok(! cert_is_revoked($certSSL));
	
	revoke("ssl", "dns", "test.foo.com");

	ok(cert_is_revoked($certSSL));
};

test "Revocation SSLClient" => sub {
	
	my $certSSL = certify("ssl", "SSLClient", "role", "test.bar");
	
	ok(! cert_is_revoked($certSSL));
	
	revoke("ssl", "role", "test.bar");

	ok(cert_is_revoked($certSSL));
};

test "Revocation VPN" => sub {
	
	my $cert = certify("vpn", "VPN", "dns", "test.foo.com");
	
	ok(! cert_is_revoked($cert));
	
	revoke("vpn", "dns", "test.foo.com");

	ok(cert_is_revoked($cert));
};

=head2 certify($type_cert, $template, $type, $data)

Certify the certificate.

=cut

sub certify {
	my ($type_cert, $template, $type, $data) = @_;
	my $req;
	if ($template =~ qw/VPN/){
		$req = {
			$type => $data,
		};
	}else {
		$req = {
			"template" => $template,
			$type => $data,
		};
	}
	my $resp_server = formcall_remote
   		("https://localhost:$port/ca/template/$type_cert/certifyForm", $req, "Submit",
   	 		-certificate => $CAcert, -key => $CAkey);
   	return App::CamelPKI::Certificate->parse($resp_server);
}

=head2 revoke($type_cert, $type, $data)

revoke the certificate using forms

=cut

sub revoke{
	my ($type_cert, $type, $data) = @_;
	my $req = {
		"type" => $type,
		"data" => $data,
	};
	formcall_remote
   		("https://localhost:$port/ca/template/$type_cert/revokeForm", $req, "Submit",
   	 		-certificate => $CAcert, -key => $CAkey);
};

=head2 cert_is_revoked($certobj)

Returns true if $certobj is currently in the CRL.

=cut

sub cert_is_revoked {
    my $crl = App::CamelPKI::CRL->parse
        (plaintextcall_remote("https://localhost:$port/ca/current_crl"));
        
    return $crl->is_member(shift);
}