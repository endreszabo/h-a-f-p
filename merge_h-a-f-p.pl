#!/usr/bin/env perl 
#================================================================================
#         FILE: merge_h-a-f-p.pl
#        DESCR: Q&D 'h-a-f-p tsv prefs.js merger. Preferences can be found at
#               the end of this file after the __DATA__ section using TSV format.
#
#        USAGE: ./merge_h-a-f-p.pl [home]
#
#       AUTHOR: Endre Szabo
#================================================================================

use strict;
use warnings;
use utf8;

my %prefs;
my $rc=0;
my $ic=0;
my $sc=0;

sub getProfiles($) {
	my $home=shift;
	open(my $FP, '<'.$home.'/.mozilla/firefox/profiles.ini') || return undef;
	my %profiles;
	my $profileId;
	my $ct=0;
	while(<$FP>) {
		next if $_ eq '';
		if (m/^\[([a-zA-Z0-9]+)\]$/) {
			next if $1 eq 'General';
			$profileId=\%{$profiles{++$ct}};
		} elsif (m/(\S+)=(.*)/) {
			if ($1 eq 'Name') {
				$profileId->{'name'}=$2;
			} elsif ($1 eq 'Path') {
				$profileId->{'path'}=$2;
			}
		}
	}
	close $FP;
	if (scalar keys %profiles == 1) {
		my $path=$home.'/.mozilla/firefox/'.$profiles{1}{'path'};
		printf "Found only Firefox profile at path '%s'\n", $path;
		return $path;
	} else {
		printf "Found more than 1 Firefox profile. Select one from below:\n\n%s\nSelection: ",
		join(
			"\n",map {
				"\t".$_.': '.$profiles{$_}{'name'}
			}sort {
				$a <=> $b
			} keys %profiles
		);
		my $n=<STDIN>;
		my $path=$home.'/.mozilla/firefox/'.$profiles{int($n)}{'path'};
		printf "Selected profile path is at '%s'\n", $path;
		return $path;
	}
	return undef;
}

my $path=getProfiles($ARGV[0] || $ENV{'HOME'});
if (!$path) {
	printf "No Firefox profiles found.\n";
	exit 1;
}

while(<DATA>) {
	chomp;
	next if $_ =~ /^#/;
	next if $_ !~ /\t/;
	my @a=split("\t",$_);
	$prefs{$a[0]}=$a[1];
}
open(my $FP, "<".$path."/prefs.js");
open(my $OFP, ">".$path."/prefs-new.js");
while(<$FP>) {
	if (/^user_pref/) {
		$sc++;
		my @a=split(/[",]/,$_,4);
		$a[3]=~s/^ //;
		$a[3]=~s/\);$//;
		if ($prefs{$a[1]}) {
			printf $OFP "user_pref(\"%s\", %s);\n",$a[1],$prefs{$a[1]};
			delete $prefs{$a[1]};
			$rc++;
		} else {
			print $OFP $_;
		}
	} else {
		print $OFP $_;
	}
}
close $FP;
if (scalar keys %prefs) {
	print $OFP "//Inserting preferences not found in your original prefs.js\n";
	foreach (keys %prefs) {
		printf $OFP "user_pref(\"%s\", %s);\n",$_,$prefs{$_};
		$ic++;
	}
}
close $OFP;

printf "Processed %d user_pref() records, %d of them were replaced and inserted %d new records at the end of the file.\n\n",
	$sc, $rc, $ic;
printf "See the changes using diff(1) output:\n\$ diff -u '%s' '%s'\n\n", $path."/prefs.js", $path."/prefs-new.js";
printf "Apply it with Firefox shut down first using:\n\$ mv '%s' '%s'\n", $path."/prefs-new.js", $path."/prefs.js";
__DATA__
middlemouse.contentLoadURL	false
browser.tabs.loadDivertedInBackground	True
browser.cache.disk.enable	false
browser.fullscreen.animateUp	0
browser.newtab.url	about:blank
browser.search.openintab	true
browser.tabs.animate	false
browser.tabs.closeWindowWithLastTab	false
browser.urlbar.trimURLs	false
general.smoothScroll	false
general.useragent.override	Mozilla/5.0
geo.enabled	false
network.http.sendRefererHeader	0
network.prefetch-next	false
network.websocket.enabled	false
security.ssl3.*_rc4_*	false
media.peerconnection.enabled	false

