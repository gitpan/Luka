# $Id: 10errordie.t,v 1.6 2006/07/07 19:14:40 toni Exp $
use Test::More tests => 19;
#use Test::More qw(no_plan);
use Test::Exception;
use lib qw(lib);
use What;
use Error qw(:try);

#==================================================================
# Below commented out tests could be used if we could detect
# whether exim is the MTA running.
#=================================================================

BEGIN {
    use_ok( 'Luka' );
    use_ok( 'Net::FTP' );
    $SIG{__DIE__} = sub
    {
	my @loc = caller(1);
 	ref $@
	    # if it's already an object, we caught previously thrown exception
 	    ? $@->rethrow 
	    # otherwise we throw new exception
 	    : throw Luka::Exception::External( error => join("",@_), id => "generic",
					       context => "External warning generated " .
					       "at line $loc[2] in $loc[1]", severity => 3);
    };
    $SIG{__WARN__} = sub
    {
	my @loc = caller(1);
	throw Luka::Exception::External( error => join("",@_), id => "generic",
					 context => "External warning generated " .
					 "at line $loc[2] in $loc[1]", severity => 3);
    };

}

our $FTP_HOST_ERR = "ftp.false";
our $FTP_HOST = "ftp.kernel.org";
our $FTP_DIR  = "pub";
our $FTP_USER = "anonymous";
our $FTP_PASS = "some\@bla.org";
our $FTP_FILE = "bla.txt";
our $testuser = "10errordie.t";

our $MTA = What->new->mta;
our $ERRORDIE_SYSTEM_USER = getpwnam $testuser; 
#diag( "err user:$ERRORDIE_SYSTEM_USER.");
#diag( "MTA:$MTA.");

diag( "Testing catching Luka::Exception::External via __DIE__ handler" );

lives_and ( sub { is ftp_classic_eval_caught(), 15 }, 
	    'caught Luka::Exception::External' );

throws_ok ( sub { ftp_classic() }, "Luka::Exception::External", 
	    'got back Luka::Exception::External' );
 
diag( "Testing Luka's report entry in syslog" );

if (defined($ERRORDIE_SYSTEM_USER)) {

    diag(" *** test user $testuser exists! *** ");

    lives_and ( sub {is ftp_classic_eval_report(), 14 }, 
	    'caught Luka::Exception::External and reported it' );

    if ($MTA eq "Exim" or $MTA eq "MasqMail") {

	like  (&get_latest_syslog(),
	       qr/Error report sent to 10errordie.t/,
	       "Luka's error report in syslog");

	like  (1, qr/1/, "empty/placeholder test");

    } else {

    	like  (1, qr/1/, "empty/placeholder test");
    	like  (1, qr/1/, "empty/placeholder test");

    }

} else {

    diag(" *** test user $testuser not found.   ***");

    lives_and ( sub { is ftp_classic_eval_report(), 14 }, 
		'ftp_classic_eval_report, caught Luka::Exception::External' );

    if ($MTA eq "Exim" or $MTA eq "MasqMail") {

	like  (&get_latest_syslog(),
	       qr/Bad hostname \'ftp.false\'/,
	       #qr/Couldn\'t report by email: to: 10errordie.t\@localhost/,
	       "ftp_classic_eval_report, error report in syslog");

	like  (&get_latest_syslog(),
	       qr/Bad hostname \'ftp.false\'/,
	       #qr/Mail system reported: RCPT error \(550 unknown user\)\!/,
	       "ftp_classic_eval_report, error report in syslog 2");
    } else {

    	like  (1, qr/1/, "empty/placeholder test");
    	like  (1, qr/1/, "empty/placeholder test");

    }
}

diag( "Testing catching Luka::Exception::External directly, via try/catch of Error.pm" );

throws_ok ( sub { wrong_luka_constructor() }, "Exception::Class::Base", 
	    'unknown field file passed to constructor for class Luka::Exception::External' );


diag( "Testing ->report exceptions thrown from Luka::Conf (except for Courier&XMail MTAs)" );
if (not $MTA eq "Courier" and not $MTA eq "XMail") {

    throws_ok ( sub { config_file_error() }, "Luka::Exception::Program", 
		'config file error' );

    like  (&get_latest_syslog(),
	   qr/Luka system disabled. Couldn\'t read its config file \'bla.txt\'/,
	   "Luka's error report in syslog");
} else {

    like  (1, qr/1/, "empty/placeholder test");
    like  (1, qr/1/, "empty/placeholder test");

}

if (defined($ERRORDIE_SYSTEM_USER)) {
    
    lives_and ( sub {is ftp_luka_catch(), 16 }, 
		'caught Luka::Exception::External and reported it' );

    if ($MTA eq "Exim" or $MTA eq "MasqMail") {

	like  (&get_latest_syslog(),
	       qr/Error report sent to 10errordie.t/,
	       "Luka's error report in syslog");

	like  (1, qr/1/, "empty test");

    }  else {

    	like  (1, qr/1/, "empty/placeholder test");
    	like  (1, qr/1/, "empty/placeholder test");

    }

} else {

    lives_and ( sub { is ftp_luka_catch(), 16 }, 
		'ftp_luka_catch, caught Luka::Exception::External' );

    if ($MTA eq "Exim" or $MTA eq "MasqMail") {

	like  (&get_latest_syslog(),
	       qr/Bad hostname \'ftp.false\'/,
	       #qr/Couldn\'t report by email: to: 10errordie.t\@localhost/,
	       "ftp_luka_catch, error report in syslog");

	like  (&get_latest_syslog(),
	       qr/Bad hostname \'ftp.false\'/,
	       #qr/Mail system reported: RCPT error \(550 unknown user\)\!/,
	       "ftp_luka_catch, error report in syslog 2");
    } else {

    	like  (1, qr/1/, "empty/placeholder test");
    	like  (1, qr/1/, "empty/placeholder test");

    }

}

diag( "Running ftp session with multiple commands" );

if (defined($ERRORDIE_SYSTEM_USER)) {

    lives_and ( sub {is ftp_luka_ok(), 17 }, 
		'reported success' );

    if ($MTA eq "Exim" or $MTA eq "MasqMail") {

	like  (&get_latest_syslog(),
	       qr/Success report sent to 10errordie.t/,
	       "Luka's success report in syslog");
	
	like  (1, qr/1/, "empty test");

    } else  {

    	like  (1, qr/1/, "empty/placeholder test");
    	like  (1, qr/1/, "empty/placeholder test");
    }

} else {

    lives_and ( sub { ftp_luka_ok(),17 },  
		'ftp_luka_ok, caught Luka::Exception::External' );

    if ($MTA eq "Exim" or $MTA eq "MasqMail") {

	like  (&get_latest_syslog(),
	       qr/Luka initiating/,
	       #qr/Couldn\'t report by email: to: 10errordie.t\@localhost/,
	       "ftp_luka_ok, error report in syslog");
     
	like  (&get_latest_syslog(),
	       qr/Luka initiating/,
	       #qr/Mail system reported: RCPT error \(550 unknown user\)\!/,
	       "ftp_luka_ok, error report in syslog 2");

    } else {

    	like  (1, qr/1/, "empty/placeholder test");
    	like  (1, qr/1/, "empty/placeholder test");

    }

}


#==============================#
#  - - -  functions  - - -     #
#==============================#

sub get_latest_syslog {
    sleep 1; # small delay required to allow syslog to process data
    # Reporting that goes into syslog
    # roughly distinguishing RedHat
    my $log = -e "/etc/redhat-release" ? "messages" : "syslog";
    return `tail -n 2 /var/log/$log`;
}

sub config_file_error {
    try {
	throw Luka::Exception::External(error => "bla", severity => 3,
					context => "test",
					args => "bla.txt", conf => "bla.txt" );
    } catch Luka::Exception with {
 	my $e = shift;
	$e->report;
    }
}


sub wrong_luka_constructor {
    my $ftp = Net::FTP->new($FTP_HOST_ERR, (Debug => 0,Passive  => 1)) ||
	throw Luka::Exception::External(error => $@, id => "object_creation", severity => 3,
					context => "FTP error: couldn't create object",
					args => $FTP_HOST_ERR, file => "bla.txt" );
}


sub ftp_luka_catch {

    try {
	my $ftp = Net::FTP->new($FTP_HOST_ERR, (Debug => 0,Passive  => 1)) ||
	    throw Luka::Exception::External(error => $@, id => "object_creation", severity => 3,
					    context => "FTP error: couldn't create object",
					    args => $FTP_HOST_ERR );
     }
     catch Luka::Exception with {
 	my $e = shift;
 	$e->report unless $MTA eq "Courier" || $MTA eq "XMail";
 	return 16;
     }
}

sub ftp_luka_ok {

    try {
	my $ftp = Net::FTP->new($FTP_HOST, (Debug => 0,Passive  => 1)) ||
	    throw Luka::Exception::External(error => $@, id => "object_creation", severity => 3,
					    context => "FTP error: couldn't create object",
					    args => $FTP_HOST );
	ok(1, "FTP: got Net::FTP object for host $FTP_HOST");

	$ftp->login($FTP_USER ,$FTP_PASS) ||
	    throw Luka::Exception::External(error => $ftp->message . $@, id => "login",
					    context => "FTP error: couldn't login", severity => 3,
					    args => "user=$FTP_USER,pass=$FTP_PASS" );
	ok(1, "FTP: logged in with user=$FTP_USER, pass=$FTP_PASS");

	$ftp->binary() ||
	    throw Luka::Exception::External(error => $ftp->message . $@, id => "binary",
					    context => "FTP error: couldn't switch to binary mode",
					    args => $FTP_FILE, severity => 3 );
	ok(1, "FTP: switched to binary mode");

	$ftp->cwd($FTP_DIR) ||
	    throw Luka::Exception::External(error => $ftp->message . $@, id => "cwd",
					    context => "FTP error: couldn't switch directory",
					    args => $FTP_DIR, severity => 3 );
	ok(1, "FTP: switched to $FTP_DIR dir ");	

	$ftp->quit;
	my $obj = Luka->new({ });
	$obj->report_success unless $MTA eq "Courier" || $MTA eq "XMail";
	return 17;
	
    } catch Luka::Exception with {

 	my $e = shift;
 	$e->report unless $MTA eq "Courier" || $MTA eq "XMail";
 	return 17;

     } catch Error with {

 	my $e = shift;
 	$e->report
	    unless $MTA eq "Courier" || $MTA eq "XMail";
 	return 18;	

     };
}


sub ftp_classic_eval_report {
    eval { ftp_classic(); };
    if ( my $e = Exception::Class->caught('Luka::Exception::External')) 
    {
	$e->report unless $MTA eq "Courier" || $MTA eq "XMail";
	return 14;
    } 
}

sub ftp_classic_eval_caught {
    eval { ftp_classic(); };
    if ( my $e = Exception::Class->caught('Luka::Exception::External')) 
    {
	return 15;
    } 
}

sub ftp_classic {
    my $ftp = Net::FTP->new("ftp.false", (Debug => 0,Passive  => 1)) || die($@);
}
