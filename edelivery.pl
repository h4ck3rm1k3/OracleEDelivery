use strict;
use warnings;
use Data::Dumper;
use YAML;
use HTTP::Cookies;
use LWP::UserAgent;
use HTTP::Status;
use HTTP::Response;
use URI::URL;
use HTML::Parse;
use IO::Socket::SSL qw(debug3);
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

use Net::SSL (); # From Crypt-SSLeay
BEGIN {
    $Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
}

$ENV{HTTPS_VERSION} = 3;
 $ENV{HTTPS_DEBUG} = 1;
my $cookie_jar = HTTP::Cookies->new( 
    file     => "cookies.lwp",
    );
my $cfg= YAML::LoadFile("config.yml");
my $pwd= $cfg->{pwd};
my $user= $cfg->{user};
my $base= 'https://edelivery.oracle.com';

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
$ua->cookie_jar( $cookie_jar );


sub getWelcome 
{
    my $res = $ua->get($base);
    my $data = $res->content();
    my $parsed_html=HTML::Parse::parse_html($data);
    for (@{ $parsed_html->extract_links() }) {
	my ($link) = @$_;
	# process the URL here
	if ($link =~/caller=WelcomePage/ )
	{
	    return $base. $link;
	}
    }
}

#my $welcome = getWelcome;
#warn $welcome;
#my $welcome= "https://login.oracle.com";
my $welcome = "https://login.oracle.com/mysso/signon.jsp";

sub login
{
    warn "going to get $welcome";
    my $res = $ua->get($welcome);
    my $data = $res->content();
    warn Dumper($data);
    my $parsed_html=HTML::Parse::parse_html($data);

    for (@{ $parsed_html->extract_links() }) {
	my ($link) = @$_;
	# process the URL here
	warn $link;
    }    
}

login;

#warn Dumper($res);
#https://edelivery.oracle.com/EPD/GetUserInfo/get_form?caller=WelcomePage

# list of packages
# https://edelivery.oracle.com/EPD/Search/handle_go

# one package
#https://edelivery.oracle.com/EPD/Download/get_form?egroup_aru_number=14566752
