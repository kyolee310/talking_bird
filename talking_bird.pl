#!/usr/bin/perl

#    Licensed to the Apache Software Foundation (ASF) under one
#    or more contributor license agreements.  See the NOTICE file
#    distributed with this work for additional information
#    regarding copyright ownership.  The ASF licenses this file
#    to you under the Apache License, Version 2.0 (the
#    "License"); you may not use this file except in compliance
#    with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing,
#    software distributed under the License is distributed on an
#    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied.  See the License for the
#    specific language governing permissions and limitations
#    under the License.
#
#    Contributor: Kyo Lee kyo.lee@eucalyptus.com

use Net::Twitter::Lite;
use strict;

local $| = 1;

my $bird;

############################## main() ####################################

my $consumer_key = "";
my $consumer_secret = "";
my $token = "";
my $token_secret = "";

# READ TALKINF BIRD CONFIGURATION FILE
my $config_file = "./var/talking_bird.ini";
my $line;

open(CONFIG, "< $config_file") or die $!;
while($line = <CONFIG>){
	chomp($line);
	if( $line =~ /^CONSUMER_KEY:\s(\S+)/ ){
		$consumer_key = $1;
	}elsif( $line =~ /^CONSUMER_SECRET:\s(\S+)/ ){
		$consumer_secret = $1;
	}elsif( $line =~ /^TOKEN:\s(\S+)/ ){
		$token = $1;
	}elsif( $line =~ /^TOKEN_SECRET:\s(\S+)/ ){
		$token_secret = $1;
	};
};
close(CONFIG);


############################## main() ####################################

print "\n";

if( @ARGV < 1 ){
	print "[ERROR] No Tweet Input File !!\n";
	exit(1);
}; 

my $inputfile = shift @ARGV;

if( !(-e "$inputfile") ){
	print "[ERROR] No Tweet Input File !!\n";
	exit(1);
};

my $post = `head -n 1 ./$inputfile`;
chomp($post);

connect_bird();

if( check_the_bird() ){
	if( check_the_bird_limit() ){
		update_bird($post);
	};
}else{
	print "[ERROR] Bird is No good !!\n";
};

disconnect_bird();
print "\n";

exit(0);

1;


###################################################### SUBROUTINES ############################################################

sub print_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};

sub connect_bird{

	print print_time() . "\tConnecting to the Bird Cage\n";
	print "\n";

	$bird = Net::Twitter::Lite->new(
		consumer_key        => $consumer_key,
		consumer_secret     => $consumer_secret,
		access_token        => $token,
		access_token_secret => $token_secret,
	);

	sleep(1);

	print print_time() . "\tConnected to the Bird Cage\n";
	print "\n";

	return 0;
};

sub disconnect_bird{

	print print_time() . "\tDisconnecting the Bird Cage\n";
	print "\n";

	$bird->end_session();

	return 0;

};

sub check_the_bird{
	if( $bird->authorized ){
		return 1;
	};

	return 0;
};

sub update_bird{
	my $tweet = shift @_;
	my $is_error = 0;

	print print_time() . "\tUpdating to the Bird Cage\n";
	print "\n";
	print "TWEET:\t\"" . $tweet . "\"\n";
	print "\n";

	my $result = eval { $bird->update($tweet) };

	if( $@ ){
#		warn "$@\n" if $@;
		print "WARNING:\t$@\n";
		print "\n";

		$is_error = 1;
	};

	print print_time() . "\tUpdated to the Bird Cage\n";
	print "\n";

	return $is_error;
};


sub check_the_bird_limit{
	my $rate =  $bird->rate_limit_status();

	print "Bird Rate Limit Status\n";
	print "Reset Time in Seconds:\t" . $rate->{'reset_time_in_seconds'} . "\n";
	print "Hourly Limit:\t" . $rate->{'hourly_limit'} . "\n";
	print "Remaining Hits:\t" . $rate->{'remaining_hits'} . "\n";
	print "Reset Time:\t" . $rate->{'reset_time'} . "\n";
	print "\n";

	if( $rate->{'remaining_hits'} < 10 ){
		print "WARNING:\tFell Below 10 Hits !!\n";
		return 0;
	};

	return 1;
};

1;
