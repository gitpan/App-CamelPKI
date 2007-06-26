#!perl -w

use strict;
use warnings;

use Test::More no_plan => 1;

=head1 NAME


=cut
BEGIN {
    use_ok 'Catalyst::Test', 'App::CamelPKI';
    use_ok 'Test::Group';
    use_ok 'Catalyst::Utils';
    use_ok 'JSON';
    use_ok 'Crypt::OpenSSL::CA';
    use_ok 'App::CamelPKI::Test';
    use_ok 'App::CamelPKI::Test', 'camel_pki_chain';
    use_ok 'App::CamelPKI::Certificate';
}

test "Unique demand" => sub {
 	my $role = "test";
 	my $dns = "monsite.com";
 	my $res = 
 	jsoncall_local("http://localhost:3000/ca/template/ssl/certifyJSON",
 		{"requests" , [ {"template" => "SSLServer", "dns" => $dns} ] });

	is(scalar(@{$res->{keys}}), 1, "1 answer");

	my $cert = App::CamelPKI::Certificate->parse($res->{keys}->[0]->[0]);
	my $dn = $cert->get_subject_DN->to_string;

	like($dn, qr/$dns/, "DNS dans le dn");


	my $PrivateKey = App::CamelPKI::PrivateKey->parse($res->{keys}->[0]->[1]);
	is ($cert->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together");
};
 
 
 
test "three certificates (SSLServer et SSLClient)" => sub {
 	my $role = "test2";
 	my $dns = "monsite2.com";
 	my $res = 
 	jsoncall_local("http://localhost:3000/ca/template/ssl/certifyJSON",
 		{"requests" , [ {"template" => "SSLServer", "dns" => $dns},
 						{"template" => "SSLClient", "role" => $role} ] });
	
	is(scalar(@{$res->{keys}}), 2, "2 answers");

	my $certSSLClient = App::CamelPKI::Certificate->parse($res->{keys}->[1]->[0]);
	my $dn = $certSSLClient->get_subject_DN->to_string;
	like($dn, qr/$role/, "Role in dn"); 

	my $PrivateKey = App::CamelPKI::PrivateKey->parse($res->{keys}->[1]->[1]);
	is ($certSSLClient->get_public_key->get_modulus, $PrivateKey->get_modulus, "Certificate and key fitted together");
	
	
	
	foreach my $keyandcert (@{$res->{keys}}) {
        my $cert = $keyandcert->[0];
    	certificate_chain_ok($cert, [ camel_pki_chain ]);
    }
}