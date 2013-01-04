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

#    warn Dumper($form->inputs);

    my $form = HTML::Form->parse($data, 'https://edelivery.oracle.com');
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

    open OUT, ">packagesout.html";
    print OUT $data;
    close OUT;

# platform
#                                'value' => '226',
#                                'name' => 'Linux x86-64'
    
# $Var1 = bless( {
#                  'onchange' => ';popup_populate(\'A\', \'B\');EPDSearchProductPlatformChanged();',
#                  'current' => 0,
#                  'menu' => [
#                              {
#                                'seen' => 1,
#                                'value' => '',
#                                'name' => '- Select a product pack -'
#                              },
#                              {
#                                'value' => '19928',
#                                'name' => 'ATG Web Commerce'
#                              },
#                              {
#                                'value' => '20781',
#                                'name' => 'ATG Web Commerce Self-Study'
#                              },
#                              {
#                                'value' => '126',
#                                'name' => 'E-Business Suite'
#                              },
#                              {
#                                'value' => '15631',
#                                'name' => 'E-Business Suite Self-Study'
#                              },
#                              {
#                                'value' => '9350',
#                                'name' => 'Financial Services Applications'
#                              },
#                              {
#                                'value' => '12063',
#                                'name' => 'Health Sciences'
#                              },
#                              {
#                                'value' => '13904',
#                                'name' => 'Hyperion Performance Management and BI'
#                              },
#                              {
#                                'value' => '15629',
#                                'name' => 'Hyperion Performance Management and BI Self-Study'
#                              },
#                              {
#                                'value' => '11484',
#                                'name' => 'iLearning Applications'
#                              },
#                              {
#                                'value' => '12685',
#                                'name' => 'JD Edwards EnterpriseOne'
#                              },
#                              {
#                                'value' => '15628',
#                                'name' => 'JD Edwards EnterpriseOne Self-Study'
#                              },
#                              {
#                                'value' => '12686',
#                                'name' => 'JD Edwards World'
#                              },
#                              {
#                                'value' => '19251',
#                                'name' => 'M-Series Products'
#                              },
#                              {
#                                'value' => '18251',
#                                'name' => 'MySQL Database'
#                              },
#                              {
#                                'value' => '12285',
#                                'name' => 'On Demand'
#                              },
#                              {
#                                'value' => '14225',
#                                'name' => 'Oracle Agile Applications'
#                              },
#                              {
#                                'value' => '13664',
#                                'name' => 'Oracle Application Integration Architecture'
#                              },
#                              {
#                                'value' => '14224',
#                                'name' => 'Oracle AutoVue'
#                              },
#                              {
#                                'value' => '15384',
#                                'name' => 'Oracle BEA'
#                              },
#                              {
#                                'value' => '14125',
#                                'name' => 'Oracle Beehive'
#                              },
#                              {
#                                'value' => '13045',
#                                'name' => 'Oracle Business Intelligence'
#                              },
#                              {
#                                'value' => '13364',
#                                'name' => 'Oracle Communications Applications'
#                              },
#                              {
#                                'value' => '15585',
#                                'name' => 'Oracle Crystal Ball'
#                              },
#                              {
#                                'value' => '9480',
#                                'name' => 'Oracle Database'
#                              },
#                              {
#                                'value' => '15626',
#                                'name' => 'Oracle Database Self-Study'
#                              },
#                              {
#                                'value' => '13264',
#                                'name' => 'Oracle Demantra'
#                              },
#                              {
#                                'value' => '18249',
#                                'name' => 'Oracle Desktop Virtualization Products'
#                              },
#                              {
#                                'value' => '18189',
#                                'name' => 'Oracle EIS-DVD Content'
#                              },
#                              {
#                                'value' => '20733',
#                                'name' => 'Oracle Endeca'
#                              },
#                              {
#                                'value' => '20782',
#                                'name' => 'Oracle Endeca Self-Study'
#                              },
#                              {
#                                'value' => '12965',
#                                'name' => 'Oracle Enterprise Manager'
#                              },
#                              {
#                                'value' => '15505',
#                                'name' => 'Oracle Enterprise Performance Management System'
#                              },
#                              {
#                                'value' => '16025',
#                                'name' => 'Oracle Financial Services Products'
#                              },
#                              {
#                                'value' => '15632',
#                                'name' => 'Oracle Fusion Applications'
#                              },
#                              {
#                                'value' => '10120',
#                                'name' => 'Oracle Fusion Middleware'
#                              },
#                              {
#                                'value' => '15746',
#                                'name' => 'Oracle Fusion Middleware Self-Study'
#                              },
#                              {
#                                'value' => '13984',
#                                'name' => 'Oracle Governance Risk and Compliance'
#                              },
#                              {
#                                'value' => '15565',
#                                'name' => 'Oracle Insurance Applications'
#                              },
#                              {
#                                'value' => '20250',
#                                'name' => 'Oracle Knowledge'
#                              },
#                              {
#                                'value' => '13943',
#                                'name' => 'Oracle Outside In Technology'
#                              },
#                              {
#                                'value' => '16045',
#                                'name' => 'Oracle Policy Automation'
#                              },
#                              {
#                                'value' => '9701',
#                                'name' => 'Oracle RDB'
#                              },
#                              {
#                                'value' => '19548',
#                                'name' => 'Oracle Repair Infrastructure Products'
#                              },
#                              {
#                                'value' => '12788',
#                                'name' => 'Oracle Retail Applications'
#                              },
#                              {
#                                'value' => '13084',
#                                'name' => 'Oracle Secure Enterprise Search'
#                              },
#                              {
#                                'value' => '18248',
#                                'name' => 'Oracle Solaris'
#                              },
#                              {
#                                'value' => '18250',
#                                'name' => 'Oracle Solaris Virtualization Products'
#                              },
#                              {
#                                'value' => '18108',
#                                'name' => 'Oracle StorageTek Products'
#                              },
#                              {
#                                'value' => '14644',
#                                'name' => 'Oracle Tax Applications'
#                              },
#                              {
#                                'value' => '13606',
#                                'name' => 'Oracle Utilities Applications'
#                              },
#                              {
#                                'value' => '22395',
#                                'name' => 'Oracle Virtual Networking'
#                              },
#                              {
#                                'value' => '12684',
#                                'name' => 'PeopleSoft Enterprise'
#                              },
#                              {
#                                'value' => '15627',
#                                'name' => 'Peoplesoft Enterprise Self-Study'
#                              },
#                              {
#                                'value' => '22235',
#                                'name' => 'Pillar Axiom Products'
#                              },
#                              {
#                                'value' => '15925',
#                                'name' => 'Primavera Applications'
#                              },
#                              {
#                                'value' => '15745',
#                                'name' => 'Related Technologies Self-Study'
#                              },
#                              {
#                                'value' => '13046',
#                                'name' => 'Siebel CRM'
#                              },
#                              {
#                                'value' => '15630',
#                                'name' => 'Siebel CRM Self-Study'
#                              },
#                              {
#                                'value' => '17225',
#                                'name' => 'Sun Products'
#                              },
#                              {
#                                'value' => '17245',
#                                'name' => 'Sun Self-Study'
#                              },
#                              {
#                                'value' => '21375',
#                                'name' => 'Taleo Products'
#                              },
#                              {
#                                'value' => '12964',
#                                'name' => 'User Productivity Kit'
#                              }
#                            ],
#                  'name' => 'product',
#                  'idx' => 1,
#                  'type' => 'option',
#                  'size' => '1'
#                }, 'HTML::Form::ListInput' );

# $VAR2 = bless( {
#                  'onchange' => 'EPDSearchProductPlatformChanged();',
#                  'current' => 0,
#                  'menu' => [
#                              {
#                                'seen' => 1,
#                                'value' => '999',
#                                'name' => 'HP-UX PA-RISC (32-bit)'
#                              },
#                              {
#                                'value' => '',
#                                'name' => '- Select a platform -'
#                              },
#                              {
#                                'value' => '227',
#                                'name' => 'IBM: Linux on POWER Systems'
#                              },
#                              {
#                                'value' => '304',
#                                'name' => 'HP NonStop Itanium (Guardian)'
#                              },
#                              {
#                                'value' => '312',
#                                'name' => 'Fujitsu BS2000/OSD (SQ series)'
#                              },
#                              {
#                                'value' => '173',
#                                'name' => 'Oracle Solaris on x86 (32-bit)'
#                              },
#                              {
#                                'value' => '421',
#                                'name' => 'Apple Mac OS X (PowerPC)'
#                              },
#                              {
#                                'value' => '212',
#                                'name' => 'IBM AIX on POWER Systems (64-bit)'
#                              },
#                              {
#                                'value' => '211',
#                                'name' => 'IBM S/390 Based Linux (31-bit)'
#                              },
#                              {
#                                'value' => '912',
#                                'name' => 'Microsoft Windows (32-bit)'
#                              },
#                              {
#                                'value' => '308',
#                                'name' => 'HP NonStop Itanium (OSS)'
#                              },
#                              {
#                                'value' => '522',
#                                'name' => 'Apple Mac OS X (Intel) (64-bit)'
#                              },
#                              {
#                                'value' => '209',
#                                'name' => 'IBM: Linux on System z'
#                              },
#                              {
#                                'value' => '30',
#                                'name' => 'IBM z/OS on System z'
#                              },
#                              {
#                                'value' => '23',
#                                'name' => 'Oracle Solaris on SPARC (64-bit)'
#                              },
#                              {
#                                'value' => '453',
#                                'name' => 'Oracle Solaris on SPARC (32-bit)'
#                              },
#                              {
#                                'value' => '214',
#                                'name' => 'Linux Itanium'
#                              },
#                              {
#                                'value' => '228',
#                                'name' => 'FreeBSD - x86'
#                              },
#                              {
#                                'value' => '87',
#                                'name' => 'HP Tru64 UNIX'
#                              },
#                              {
#                                'value' => '267',
#                                'name' => 'Oracle Solaris on x86-64 (64-bit)'
#                              },
#                              {
#                                'value' => '1',
#                                'name' => 'HP OpenVMS VAX'
#                              },
#                              {
#                                'value' => '233',
#                                'name' => 'Microsoft Windows x64 (64-bit)'
#                              },
#                              {
#                                'value' => '197',
#                                'name' => 'HP-UX Itanium'
#                              },
#                              {
#                                'value' => '293',
#                                'name' => 'Apple Mac OS X (Intel) (32-bit)'
#                              },
#                              {
#                                'value' => '303',
#                                'name' => 'HP NonStop S-series (Guardian)'
#                              },
#                              {
#                                'value' => '316',
#                                'name' => 'Unisys OS 2200'
#                              },
#                              {
#                                'value' => '59',
#                                'name' => 'HP-UX PA-RISC (64-bit)'
#                              },
#                              {
#                                'value' => '243',
#                                'name' => 'HP OpenVMS Itanium'
#                              },
#                              {
#                                'value' => '89',
#                                'name' => 'HP OpenVMS Alpha'
#                              },
#                              {
#                                'value' => '226',
#                                'name' => 'Linux x86-64'
#                              },
#                              {
#                                'value' => '361',
#                                'name' => 'Fujitsu BS2000/OSD (S series)'
#                              },
#                              {
#                                'value' => '319',
#                                'name' => 'IBM AIX on POWER Systems (32-bit)'
#                              },
#                              {
#                                'value' => '46',
#                                'name' => 'Linux x86'
#                              },
#                              {
#                                'value' => '314',
#                                'name' => 'IBM z/VM on System z'
#                              },
#                              {
#                                'value' => '43',
#                                'name' => 'IBM i on POWER Systems'
#                              },
#                              {
#                                'value' => '285',
#                                'name' => 'Fujitsu BS2000/OSD (SX series)'
#                              },
#                              {
#                                'value' => '208',
#                                'name' => 'Microsoft Windows Itanium (64-bit)'
#                              },
#                              {
#                                'value' => '2000',
#                                'name' => 'Generic Platform'
#                              }
#                            ],
#                  'name' => 'platform',
#                  'idx' => 1,
#                  'type' => 'option',
#                  'size' => '1'
#                }, 'HTML::Form::ListInput' );

# $VAR3 = bless( {
#                  'readonly' => 1,
#                  '/' => '/',
#                  'value_name' => 'Platform',
#                  'value' => ' - Select a product pack first - ',
#                  'name' => 'platform_none',
#                  'type' => 'hidden'
#                }, 'HTML::Form::TextInput' );

# $VAR4 = bless( {
#                  'readonly' => 1,
#                  '/' => '/',
#                  'value_name' => '',
#                  'value' => '',
#                  'name' => 'sort_product',
#                  'type' => 'hidden'
#                }, 'HTML::Form::TextInput' );

# $VAR5 = bless( {
#                  'readonly' => 1,
#                  '/' => '/',
#                  'value_name' => '',
#                  'value' => '',
#                  'name' => 'sort_platform',
#                  'type' => 'hidden'
#                }, 'HTML::Form::TextInput' );

# $VAR6 = bless( {
#                  'readonly' => 1,
#                  '/' => '/',
#                  'value_name' => '',
#                  'value' => '',
#                  'name' => 'direction',
#                  'type' => 'hidden'
#                }, 'HTML::Form::TextInput' );

# $VAR7 = bless( {
#                  'readonly' => 1,
#                  '/' => '/',
#                  'value_name' => '',
#                  'value' => '',
#                  'name' => 'orderby',
#                  'type' => 'hidden'
#                }, 'HTML::Form::TextInput' );

# $VAR8 = bless( {
#                  'readonly' => 1,
#                  'value_name' => '',
#                  'name' => 'sortcolpressed',
#                  'type' => 'hidden'
#                }, 'HTML::Form::TextInput' );
    
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
$ua->add_handler("request_send",  sub { shift->dump; return });
$ua->add_handler("response_done", sub { shift->dump; return });

my $welcome = getWelcome $ua, 'https://edelivery.oracle.com';
my $export   = login $ua, $welcome;
my $packages = exportAgree $ua,$export;
packages $ua, $packages;


# a list of packages, now we need to select one to get the downloads
# https://edelivery.oracle.com/EPD/Search/handle_go
# one package
#https://edelivery.oracle.com/EPD/Download/get_form?egroup_aru_number=14566752
