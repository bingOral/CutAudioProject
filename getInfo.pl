#!/usr/bin/perl

use strict;
use JSON;

open(IN,$ARGV[0])||die("The file can't find!\n");
my $jsonparser = new JSON;

while(my $row = <IN>)
{
	chomp($row);
	my $json = $jsonparser->decode($row);
	my $info = $json->{info};
	my $res = preProcessInfo($info);
	if($res)
	{
		print $res."\n";
	}
}

sub preProcessInfo
{
	my $info = shift;
	my $res = $info;

	$res =~ s/’/'/g;
	$res =~ s/\'s/@/g;
	$res =~ s/\'m/%/g;
	$res =~ s/\'t/#/g;
	$res =~ s/\'ll/&&/g;
	$res =~ s/\./&&&/g;
	$res =~ s/([0-9]+)\,([0-9]+)/$&##$2/g;
	$res =~ s/([a-z]+)\-([a-z]+)/$1&$2/g;
	$res =~ s/([0-9]+)\.([0-9]+)/$&~$2/g;

	$res =~ s/[^a-z0-9A-Z@%&#~]/ /g;
	$res =~ s/[,"!'?-]/ /g;
	$res =~ s/\(|\)\[\]\_/ /g;
	$res =~ s/\(.*\)/ /g;
	$res =~ s/[\r\n]/ /g;
	$res =~ s/\s+/ /g;

	$res =~ s/&&&/./g;
	$res =~ s/&&/\'ll/g;
	$res =~ s/##/,/g;
	$res =~ s/@/\'s/g;
	$res =~ s/%/\'m/g;
	$res =~ s/#/\'t/g;
	$res =~ s/&/-/g;
	$res =~ s/~/./g;

	$res = lc($res);
	return $res;
}

1;

