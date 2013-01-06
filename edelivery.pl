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
    my $productno=shift;
    my $platformno=shift;
    open OUT, ">packages.html";
    print OUT $data;
    close OUT;


    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');
    open OUT, ">packages.pm";
    print OUT Dumper($form->inputs);;
    close OUT;

    my $product=$form->find_input('product');
    die unless $product;
    $product->value($productno);

    my $platform=$form->find_input('platform');
    die unless $platform;

    $platform->value($platformno);

    my $res = $ua->request($form->click);
    $data = $res->content();

    return $data;

}

sub Download {
    # run the download for a url
    my $ua=shift;
    my $output=shift;
    my $url=shift;
    if ($url =~ /patch_file=([^&]+)/) {
	my $ofile=$1;
	warn "$url  -> $ofile";
	my $res= $ua->mirror( $url, "$output/".$ofile );
#	my $res= $ua->get( $url ); #, "output/".$ofile );
#	warn Dumper($res);
    }
    elsif ($url =~ /epack_part_number=(.+)/) {
	my $ofile="EPACK_". $1;
	warn "$url  -> $ofile";
	my $res= $ua->mirror( $url, "$output/".$ofile );
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
    my $dir=shift;
    my $data=shift;
    
}


sub output_aru_list 
{
    my $ua=shift;
    my $data=shift;
    my $productno =shift;
    my $platformno=shift;

    mkdir "output" unless -d "output";
    mkdir "output/$productno" unless -d "output/$productno";
    mkdir "output/$productno/$platformno" unless -d "output/$productno/$platformno";

    open OUT, ">output/$productno/$platformno/packages_aru.html";
    print OUT $data;
    close OUT;
    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');
    open OUT, ">output/$productno/$platformno/packagesaru.pm";
    print OUT Dumper($form->inputs);;
    close OUT;

}

sub packages_aru
{
    my $ua=shift;
    my $data=shift;
    my $productno =shift;
    my $platformno=shift;
    my $aruno=shift;

    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');
## now fill out the form

    my $product=$form->find_input('product');
    die unless $product;
    $product->value($productno);


    my $platform=$form->find_input('platform');
    die unless $platform;
    $platform->value($platformno);

    # set the aru number
    my $aru=$form->find_input('egroup_aru_number');
    $aru->value($aruno); 

    my $res = $ua->request($form->click);
    $data = $res->content();

    return $data;
}

sub download_aru 
{

    my $ua=shift;
    my $data=shift;
    my $productno =shift;
    my $platformno=shift;
    my $aruno=shift;
    
    open OUT, ">output/$productno/$platformno/$aruno/packagesaruout.html";
    print OUT $data;
    close OUT;

    mkdir "output" unless -d "output";
    mkdir "output/$productno" unless -d "output/$productno";
    mkdir "output/$productno/$platformno" unless -d "output/$productno/$platformno";
    mkdir "output/$productno/$platformno/$aruno" unless -d "output/$productno/$platformno/$aruno";


    my $dir="output/$productno/$platformno/$aruno";
    while ($data =~ m/(EPD\/Down[^\"\']+)[\"\']/gm){
	Download $ua, $dir, 'https://edelivery.oracle.com/' . $1;
    }
    
    while ($data =~ m/(EPD\/ViewDigest[^\"\']+)[\"\']/gm){
	Download $ua, $dir, 'https://edelivery.oracle.com/' . $1;
    }

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

my $product_no = 10120; #'name' => 'Oracle Fusion Middleware',                             'value' => '10120',
my $platform_no = 226; #'linux 64
my $welcome = getWelcome $ua, 'https://edelivery.oracle.com';
my $export   = login $ua, $welcome;
my $packages = exportAgree $ua,$export;
my $paru = packages $ua, $packages,$product_no, $platform_no;




#product
#'name' => 'Oracle Fusion Middleware',                             'value' => '10120',
# prod '10120'
# plat '226' # linux 64
# aru '15737734' # Oracle WebLogic Server 12c Media Pack
my $aru_no=15737734;

output_aru_list $ua, $paru, $product_no, $platform_no; # this saves the list of arus to the file, we will make a menu

#get the list of files you can download, for the aru
my $aru_list = packages_aru $ua, $paru, $product_no, $platform_no, $aru_no;

download_aru  $ua, $aru_list, $product_no, $platform_no, $aru_no;

# a list of packages, now we need to select one to get the downloads
# https://edelivery.oracle.com/EPD/Search/handle_go
# one package
#https://edelivery.oracle.com/EPD/Download/get_form?egroup_aru_number=14566752
