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

sub exportAgree
{
    my $ua=shift;
    my $data=shift;
    ## now get the export agreement
    # open OUT, ">packages-1.html";
    # print OUT $data;
    # close OUT;

    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');
    

    my $agree=$form->find_input('epd_agree');
    my $product=$form->find_input('product');
    if (!$agree && $product)
    {
	return $data; # we have the product due to cookies, skip this step.
    }
    $agree->check;
    $agree=$form->find_input('export_agree');
    $agree->check;
    my $res = $ua->request($form->click);
    $data = $res->content();

    # open OUT, ">packages-2.html";
    # print OUT $data;
    # close OUT;

    my $parsed_html=HTML::Parse::parse_html($data);
    my $final;
    for (@{ $parsed_html->extract_links() }) {
	my ($link) = @$_;
	$final= $link;
    }    
    $res = $ua->get('https://edelivery.oracle.com' . $final);
    $data = $res->content();
    return $data; # this is the main search page

}

sub login
{
    my $ua=shift;
    my $welcome=shift;
    my $base= "https://login.oracle.com";
    ## get the login form
    my $res = $ua->get($welcome);
    my $data = $res->content();
    my $form = HTML::Form->parse($data, $base);
    die "No form defined for $data" unless $form;
    $form->value(ssousername => $username);
    $form->value(password => $password);
    $res = $ua->request($form->click);
    $data = $res->content();
    
    # second try , need to login 2x
    $form = HTML::Form->parse($data, $base);
    $form->value(ssousername => $username);
    $form->value(password => $password);
    $res = $ua->request($form->click);
    $data = $res->content();
    ## follow the redirect 
    my $parsed_html=HTML::Parse::parse_html($data);
    my $final;
    for (@{ $parsed_html->extract_links() }) {
	my ($link) = @$_;
	$final= $link;
    }    
    $res = $ua->get($final);
    $data = $res->content();
    return $data;
}

sub packages
{
    my $ua=shift;
    my $data=shift;
    open OUT, ">packages.html";
    print OUT $data;
    close OUT;


    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');
    open OUT, ">packages.pm";
    print OUT Dumper($form->inputs);;
    close OUT;

    my $product=$form->find_input('product');
    die unless $product;
#product
#                                'value' => '10120',
#                                'name' => 'Oracle Fusion Middleware'
    $product->value('10120');

    my $platform=$form->find_input('platform');
    die unless $platform;

    $platform->value('226');

    my $res = $ua->request($form->click);
    $data = $res->content();

    return $data;
# platform
#                                'value' => '226',
#                                'name' => 'Linux x86-64'
# Options :    
#                  'name' => 'product',
#                  'name' => 'platform',
#                  'name' => 'platform_none',

}

sub Download {
    # run the download for a url
    my $ua=shift;
    my $url=shift;
    if ($url =~ /patch_file=([^&]+)/) {
	my $ofile=$1;
	warn "$url  -> $ofile";
	my $res= $ua->mirror( $url, "output/".$ofile );
#	my $res= $ua->get( $url ); #, "output/".$ofile );
#	warn Dumper($res);
    }
    elsif ($url =~ /epack_part_number=(.+)/) {
	my $ofile="EPACK_". $1;
	warn "$url  -> $ofile";
	my $res= $ua->mirror( $url, "output/".$ofile );
#	my $res= $ua->get( $url );#, "output/".$ofile );
#	warn Dumper($res);
    }
    else
    {
		warn "$url  -> ?";
    }
}

sub download_aru {
    my $ua=shift;
    my $data=shift;

    
    while ($data =~ m/(EPD\/Down[^\"\']+)[\"\']/gm){
	Download $ua, 'https://edelivery.oracle.com/' . $1;
    }
    
    while ($data =~ m/(EPD\/ViewDigest[^\"\']+)[\"\']/gm){
	Download $ua, 'https://edelivery.oracle.com/' . $1;
    }
    
}

sub packages_aru
{
    my $ua=shift;
    my $data=shift;

    open OUT, ">packages_aru.html";
    print OUT $data;
    close OUT;

    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');

    open OUT, ">packagesaru.pm";
    print OUT Dumper($form->inputs);;
    close OUT;

    my $product=$form->find_input('product');
    die unless $product;
#product
#                                'name' => 'Oracle Fusion Middleware',                             'value' => '10120',
#    $product->value('10120');
#   'name' => 'Oracle Retail Applications' , 'value' => '12788'
    $product->value('12788');


    my $platform=$form->find_input('platform');
    die unless $platform;
    $platform->value('226');

    # set the aru number
    my $aru=$form->find_input('egroup_aru_number');
    $aru->value('13098738');


    my $res = $ua->request($form->click);
    $data = $res->content();


    open OUT, ">packagesaruout.html";
    print OUT $data;
    close OUT;

    download_aru $ua, $data; # now run the downloads

}


$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
$ENV{HTTPS_VERSION} = 3;
# $ENV{HTTPS_DEBUG} = 1;

my $cookie_jar = HTTP::Cookies->new( 
    file     => "cookies.lwp",
    autosave => 1,
    );

mkdir "output" unless -d "output";

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
$ua->cookie_jar( $cookie_jar );
$ua->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322; FDM)');

# run debug 
#$ua->add_handler("request_send",  sub { shift->dump; return });
#$ua->add_handler("response_done", sub { shift->dump; return });

my $welcome = getWelcome $ua, 'https://edelivery.oracle.com';
my $export   = login $ua, $welcome;
my $packages = exportAgree $ua,$export;
my $paru = packages $ua, $packages;
packages_aru $ua, $paru;


# a list of packages, now we need to select one to get the downloads
# https://edelivery.oracle.com/EPD/Search/handle_go
# one package
#https://edelivery.oracle.com/EPD/Download/get_form?egroup_aru_number=14566752
