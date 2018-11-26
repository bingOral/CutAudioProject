#!/usr/bin/perl

use strict;
use JSON;
use threads;
use Encode;

my $jsonparser = new JSON;
open(IN,$ARGV[0])||die("The file can't find!\n");

&Main();

sub Main
{
	my $threadnum = $ARGV[1];
	my @tasks = <IN>;
	my $group = div(\@tasks,$threadnum);

	my @threads;
	foreach my $key (keys %$group)
	{
		my $thread = threads->create(\&dowork,$group->{$key});
		push @threads,$thread;
	}

	foreach(@threads)
	{
		$_->join();
	}
}

sub div
{
	my $ref = shift;
	my $threadnum = shift;

	my $res;
    	for(my $i = 0; $i < scalar(@$ref); $i++)
   	{
   		my $flag = $i%$threadnum;
   		push @{$res->{$flag}},$ref->[$i];
    	}

    	return $res;
}

sub dowork
{
	my $param = shift;
	
	foreach my $row (@$param)
	{
		chomp($row);			
		unless(Encode::is_utf8($row))
		{
			$row = Encode::decode('utf8',$row);
		}

		my $json = $jsonparser->decode($row);
		my $filename = $json->{filename};
		if( -e $filename)
		{
			my $lab = qx(./divide/vadnn_divide -m ./divide/am.dat $filename);

			my $random = qx(uuidgen);
			$random =~ s/[\r\n]//g;
			my $logfile = "log/log-$random.txt";
			open(OUT,">$logfile")||die("The file can't create!\n");
			print OUT $lab;

			my $dir;
			if($filename =~ /(.*\/.*).wav/)
			{
				$dir = $1.'/';
			}

			$dir =~ s/wav/vadnn/;
			unless(-d $dir)
			{
				qx(mkdir -p $dir);	
			}
			
			system("python ./divide/seg_bigwav.py $logfile 0 0 $dir");

			my $str = "find $dir -name '*.wav'|";
			open(TEMP,$str)||die("The file can't find!\n");
			while(my $row = <TEMP>)
			{
				chomp($row);
				push @{$json->{subwav}},$row;
			}

			print $jsonparser->encode($json)."\n";
		}
	}
}

1;

