use strict;
use warnings;
use Net::SSL (); # From Crypt-SSLeay
BEGIN {
    $Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
}

use Data::Dumper;
use YAML;
use HTTP::Cookies;
use LWP::UserAgent;
use HTTP::Status;
use HTTP::Response;
use URI::URL;
use HTML::Parse;
use IO::Socket::SSL; # qw(debug3);
use HTML::Form;

my $cfg= YAML::LoadFile("config.yml");
my $password= $cfg->{pwd};
my $username= $cfg->{user};

sub getWelcome 
{
    my $ua =shift;
    my $base=shift;
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

sub login
{
    my $ua=shift;
    my $welcome=shift;
    my $base= "https://login.oracle.com";
 #   my $login = $base . "/mysso/signon.jsp";

    my $res = $ua->get($welcome);


    my $data = $res->content();
#    warn Dumper($data);
    # my $parsed_html=HTML::Parse::parse_html($data);

    # for (@{ $parsed_html->extract_links() }) {
    # 	my ($link) = @$_;
    # 	# process the URL here
    # 	warn $link;
    # }    

    open OUT, ">in.html";
    print OUT $data;
    close OUT;

    my $form = HTML::Form->parse($data, $base);
#    $form->value(Mssousername => $username);
#    $form->value(Mssopassword => $password);
    $form->value(ssousername => $username);
#    $form->value(ssopassword => $password);
    $form->value(password => $password);

#    warn Dumper($form->inputs());

    $res = $ua->request($form->click);
    #warn Dumper($res);    
    my $data = $res->content();
    open OUT, ">out.html";
    print OUT $data;
    close OUT;

}

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
$ENV{HTTPS_VERSION} = 3;
# $ENV{HTTPS_DEBUG} = 1;

my $cookie_jar = HTTP::Cookies->new( 
    file     => "cookies.lwp",
    autosave => 1,
    );
my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
$ua->cookie_jar( $cookie_jar );


$ua->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322; FDM)');

my $welcome = getWelcome $ua, 'https://edelivery.oracle.com';
warn "found welcome url $welcome";
login $ua, $welcome;


#warn Dumper($res);
#https://edelivery.oracle.com/EPD/GetUserInfo/get_form?caller=WelcomePage
# list of packages
# https://edelivery.oracle.com/EPD/Search/handle_go
# one package
#https://edelivery.oracle.com/EPD/Download/get_form?egroup_aru_number=14566752
