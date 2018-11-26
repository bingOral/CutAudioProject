#!/usr/bin/perl

use strict;
use JSON;

open(IN,$ARGV[0])||die("The file can't find!\n");
my $jsonparser = new JSON;

while(my $row = <IN>)
{
	chomp($row);
	my $json = $jsonparser->decode($row);
	my $wavs = $json->{subwav};
	foreach my $wav (@$wavs)
	{
		print $wav."\n";
	}
}
