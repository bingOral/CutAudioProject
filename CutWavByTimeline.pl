#!/usr/bin/perl

use strict;
use JSON;
use Encode;
use File::Copy;
use Try::Tiny;

if(scalar(@ARGV) != 2)
{
	print "Usage : perl $0 infile outfile\n";
	exit;
}

open(IN,$ARGV[0])||die("The file can't find!\n");
open(OUT,">$ARGV[1]")||die("The file can't find!\n");

my @task = <IN>;
dowork(\@task);

sub dowork
{
	my $task = shift;
	foreach my $movie (@$task)
	{
		chomp($movie);

		print "Before :".$movie."\n";
		$movie = pro($movie);
		print "After  :".$movie."\n";

		my $wav = formate($movie);
		my $srt = getSrt($movie);
		my $dir = getDir($movie);
		if($srt)
		{
			my $json = srt2json($srt);
			print "wav : ".$wav."\nsrt : ".$srt."\ndir : ".$dir."\n";
			cut($wav,$dir,$json);
		}
		#die;
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

	if( -e $ass)
	{	
		qx(asstosrt -f $ass -o $dir);
		qx(iconv -f UTF-16LE -t UTF-8 $srt -o $srt);
		return $srt;	
	}
	else
	{
		$srt = search($movie,$dir);

		if($srt)
		{
			return $srt;	
		}
		else
		{
			return;
		}
	}
}

sub cut
{
	my $wav = shift;
	my $dir = shift;
	my $res = shift;

	my $prefix;
	if($wav =~ /.*\/(.*).wav/)
	{
		$prefix = $1;
	}

	try
	{	
		for(my $i = 0; $i < scalar(@$res); $i++)
		{
			my $start_time = $res->[$i]->{start_time};
			my $end_time = $res->[$i]->{end_time};
			my $texts = $res->[$i]->{text};
			
			my $filename = $dir.'/'.$prefix.'-'.($i+1).'.wav';	
        		my $str = "ffmpeg -v quiet -y -i ".$wav." -ss ".$start_time." -to ".$end_time." -acodec copy ".$filename;
			print $str."\n";
			system($str) unless -e $filename;
			print OUT $filename."|".formater($texts)."\n";
		}
	}
	catch
	{
		print "Error : ".$wav." !\n";
	}
}

sub formater
{
        my $info = shift;
        unless(Encode::is_utf8($info))
        {   
                $info = Encode::decode('iso-8859-1',$info);
        }   
        return $info;
}

sub search
{
	my $movie = shift;
	my $dir = shift;

	my $str;
	if($movie =~ /.*\/(.*).mkv/)
	{
		$str = $1;
	}

	opendir(DIR,$dir)||die("Can't open this dir!\n");
	my @files = readdir DIR;
	my @files_pro;

	foreach my $file (@files)
	{
		if($file =~ /.*.srt$/)
		{
			$file = pro($dir.$file);
			push @files_pro, $file;	
		}		
	}

	foreach my $file (@files_pro)
	{
		if($file =~ /$str.*.srt$/)
		{
			return $file;
		}
	}	
	return;
}

sub pro 
{
	my $filename = shift;
	my $newname = $filename;
	$newname =~ s/[^a-zA-Z0-9_\-.\/]//g;

	copy($filename,$newname) unless -e $newname;
	return $newname;		
}

sub srt2json
{
	my $file = shift;

	open(IN,$file)||die("The file can't find!\n");

	my $buffer;
	my $res;
	my $rtn;

	while(my $row = <IN>)
	{
		$row =~ s/[\r\n]//g;
		$buffer .= $row.'|';
	
		if($row =~ /^\s*$/)
		{
			push @$res,$buffer;
			$buffer = "";
		}
	}
	
	foreach my $row (@$res)
	{
		chomp($row);
		my @arr = split(/\|/,$row);
		my @times = split(/ --> /,$arr[1],2);
	
		my $start_time = $times[0];
		$start_time =~ s/,/./;
		my $end_time = $times[1];
		$end_time =~ s/,/./;
		
		my $text = $row;
		$text =~ s/$arr[1]|^\d+\|+|\|+$//g;
	
		my $var;
		$var->{start_time} = $start_time;
		$var->{end_time} = $end_time;
		$var->{text} = $text;
		push @$rtn,$var;
	}
	return $rtn;
}

1;

