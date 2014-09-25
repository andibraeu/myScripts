#! /usr/bin/perl

use Net::NNTP;
use LWP::Simple;
use iCal::Parser;
use DateTime;
use POSIX qw(strftime);
use Encode qw(decode encode);
#use Data::Dumper;

#######
## change this to point to your NNTP server host.
$nntpserver = 'localhost';
########
# url to wiki
my $url="http://ics.freifunk.net/tags/weimar";
my $url_ics="http://ics.freifunk.net/tags/weimar.ics";
my $weburl="http://weimarnetz.de";
my $wikiurl="http://wireless.subsignal.org";
my $place="undef";
my $date="undef";
my $subject="";
my $body="";
my $newsgroup="freifunk.de.weimar.discuss";
my $today = DateTime->today();
my $start_of_week = $today->truncate( to => 'week' )->ymd('');
my $end_of_week = $today->truncate( to => 'week' )->add( days => 6)->ymd('');
$today = DateTime->today();

# Print warning and exit.  Some mailers will discard warning string.
# # Postfix is nice enough to display it in the mailq & log output when
# # we exit with non-success exitcode.
sub croak {
   my ($msg,$exitcode) = @_;

   warn "$msg\n";
   exit($exitcode);
}


my $ical = get $url_ics;
die "Couldn't get $url_ics" unless defined $ical;

#build subject
$subject = "Termine für die " . $today->week_number() . ". Kalenderwoche " . $today->week_year();

# Then go do things with $ical, like this:
my $parser = iCal::Parser->new( start => $start_of_week, end => $end_of_week);
my $ical = $parser->parse_strings($ical);
my $calendar = $parser->calendar;
my $events = $ical->{events};

#print Dumper(%{ $events });
# print keys %{ $events };

#build body
$body = "Liebe Liste,\n\ndiese Termine stehen in der " . $today->week_number() . ". Woche an:\n\n";
foreach $year (sort { $a <=> $b  } keys %{ $events }) {
    foreach $month (sort { $a <=> $b  } keys %{ $events->{$year} }) {
			foreach $day (sort { $a <=> $b  } keys % { $events->{$year}->{$month} }) {
				foreach $event (sort { $a <=> $b  } keys % { $events->{$year}->{$month}->{$day} }) {
					$body .= "\tThema: \t" . $events->{$year}->{$month}->{$day}->{$event}->{'SUMMARY'} . "\n";
					my $date = $events->{$year}->{$month}->{$day}->{$event}->{'DTSTART'}->strftime("%A, %e. %B %k:%M");
					$body .= "\tZeit: \t" . $date . " Uhr\n";
					$body .= "\tOrt: \t" . $events->{$year}->{$month}->{$day}->{$event}->{'LOCATION'} . "\n";
					$body .= "\tLink: \t" . $events->{$year}->{$month}->{$day}->{$event}->{'URL'} . "\n\n";
				}
			}
    }
}

$body .= "Weitere Informationen und Termine findest Du unter " . $url . ", auf unserer Website unter $weburl oder im Wiki unter " . $wikiurl . "\n\nMit drahtlosen Grüßen\n\nDas Weimarnetz\n";

#print $body;

push @headers,"From: Weimarnetz Wiki <do_not_reply\@weimarnetz.de>\n";
push @headers,"Newsgroups: ". $newsgroup ."\n";
push @headers,"Subject: ". $subject ."\n";
push @headers,"\n";


my $nntp = Net::NNTP->new($nntpserver) or croak('Net::NNTP failure.', "1");

$nntp->post() or croak('post() failure',&EX_TEMPFAIL);
$nntp->datasend(\@headers) or croak('datasend() header failure',"1");

#while (<>) {
  $nntp->datasend(encode("iso-8859-1",$body))or croak('datasend() body failure',"1");
#}

#$nntp->debug(1);		# if error exit code, log to maillog (STDERR)
$nntp->dataend() or croak('Post dataend() failure.', "2");
$nntp->quit();

exit(0);

  
