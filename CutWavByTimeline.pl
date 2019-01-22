#!/usr/bin/perl

use strict;
use JSON;
use Encode;

open(IN,$ARGV[0])||die("The file can't find!\n");

my @task = <IN>;
dowork(\@task);

sub dowork
{
	my $task = shift;
	foreach my $movie (@$task)
	{
		chomp($movie);
		print $movie."\n";
		my $wav = formate($movie);
		my $srt = getSrt($movie);
		my $json = getJson($srt);
		my $dir = getDir($movie);
		my $res = cut($wav,$dir,$json);
		die;
	}
}

sub getDir
{
	my $movie = shift;
	my $dir;
	
	if($movie =~ /(.*\/.*).mkv/)
	{
		$dir = $1;	
	}

	mkdir($dir) unless -e $dir;
	return $dir;
}

sub formate
{
	my $movie = shift;
	my $wav;

	if($movie =~ /(.*\/.*).mkv/)
	{
		$wav = $1.'.wav';
	}

	my $str = "ffmpeg -v quiet -y -i $movie -f wav -ar 16000 -ac 1 $wav";
	print $str."\n";
	system($str) unless -e $wav;
	return $wav;
}

sub getSrt
{
	my $movie = shift;
	my $ass;
	my $srt;
	my $dir;
	
	if($movie =~ /((.*\/).*).mkv/)
	{
		$ass = $1.'.ass';
		$srt = $1.'.srt';
		$dir = $2;
	}
	
	qx(asstosrt -f $ass -o $dir);
	qx(iconv -f UTF-16LE -t UTF-8 $srt -o $srt);
	return $srt;
}

sub getJson
{
	my $srt = shift;
	my $str = "perl script/srt2json.pl -f $srt -v";
	system($str);
	return $srt.'.json';
}

sub cut
{
	my $wav = shift;
	my $dir = shift;
	my $json = shift;

	my $res;
	my $jsonparser = new JSON;
	open(IN,$json)||die("The file can't find!\n");
	my $content = <IN>;

	my $prefix;
	if($wav =~ /.*\/(.*).wav/)
	{
		$prefix = $1;
	}

	my $res = $jsonparser->decode($content);
	for(my $i = 0; $i < scalar(@$res); $i++)
	{
		my $start_time = $res->[$i]->{start_time};
		my $end_time = $res->[$i]->{end_time};
		my $texts = $res->[$i]->{subtitle};
		
		$start_time =~ s/,/./;
		$end_time =~ s/,/./;
		$texts =~ s/\n/&/;
	
		my $filename = $dir.'/'.$prefix.'-'.($i+1).'.wav';	
        	my $str = "ffmpeg -v quiet -y -i ".$wav." -ss ".$start_time." -to ".$end_time." -acodec copy ".$filename;
		print $str."\n";
		system($str);
		print $filename."|".formater($texts)."\n";
	}	
}

sub formater
{
        my $info = shift;
        unless(Encode::is_utf8($info))
        {   
                $info = Encode::decode('utf8',$info);
        }   
        return $info;
}

1;

