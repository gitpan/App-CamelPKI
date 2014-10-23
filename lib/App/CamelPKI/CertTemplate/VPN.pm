#!perl -w

use strict;
use warnings;

=head1 NAME

I<App::CamelPKI::CertTemplate::VPN> - Certificate templates for VPN nodes.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis"



=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

All these templates inherit from L<App::CamelPKI::CertTemplate::CertBase>
which contains common functions for open templates.

=cut

=head1 App::CamelPKI::CertTemplate::VPN1

Certificates made with this template are for OpenBSD IPSEC VPN key
exchange.

=cut

package App::CamelPKI::CertTemplate::VPN1;
use base "App::CamelPKI::CertTemplate::CertBase";

sub list_keys {qw (dns)};

sub prepare_certificate {
    my ($class, $cacert, $cert, %opts) = @_;
    $class->copy_from_ca_cert($cacert, $cert);
    my $dns = $opts{dns};

    my $keyUsage = "keyEncipherment";
    my $subjectAltName = "DNS:".$dns;

    $class->fillCommon($cacert, $cert);
    $class->fill_subject_DN($cert,
         OU => "CamelPKI",
         OU => "VPN",
         CN => $dns);

    $cert->set_extension("keyUsage", $keyUsage);
    $cert->set_extension("subjectAltName",$subjectAltName); 
    $cert->set_extension("extendedKeyUsage", "clientAuth");
}

require My::Tests::Below unless caller;
1;

__END__

=begin internals

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Test "%test_public_keys", "certificate_chain_ok", "%test_keys_plaintext";
use Crypt::OpenSSL::CA;
use App::CamelPKI::CertTemplate::CA;
use App::CamelPKI::PrivateKey;

my $keysize = 1024;


test "vpn1_generate"=> sub {	
	my $privKey = App::CamelPKI::PrivateKey->genrsa($keysize)
            ->as_crypt_openssl_ca_privatekey;
	my $certCA0 = Crypt::OpenSSL::CA::X509->new($privKey->get_public_key);
	App::CamelPKI::CertTemplate::CA0->prepare_self_signed_certificate($certCA0);
	my $pem = $certCA0->sign($privKey,"sha256");
	my $privKeyCA1 = App::CamelPKI::PrivateKey->genrsa($keysize)
            ->as_crypt_openssl_ca_privatekey;
	my $certCA1 = Crypt::OpenSSL::CA::X509->new($privKeyCA1->get_public_key);
	App::CamelPKI::CertTemplate::CA1->prepare_certificate($certCA0, $certCA1);
	my $pem1 = $certCA1->sign($privKey,"sha256");	

	my $certAuth = Crypt::OpenSSL::CA::X509->parse($pem1);
	my $certTest = Crypt::OpenSSL::CA::X509->new(Crypt::OpenSSL::CA::PublicKey->parse_RSA($test_public_keys{rsa1024}));
	App::CamelPKI::CertTemplate::VPN1->prepare_certificate($certAuth, $certTest, "dns", "monsite.com", "role", "test");
	certificate_chain_ok($certTest->sign($privKeyCA1, "sha256"), [$pem1, $pem]);
};

=end internals

=cut
