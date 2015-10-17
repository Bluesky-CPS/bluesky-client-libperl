#!/usr/bin/perl
#-*- coding: utf-8 -*-
=for comment
= Bluesky connector for perl programmer.
= Author: Praween AMONTAMAVUT (Hayakawa Laboratory)
= Requirements: perl v5.14.2 with "libwww-perl" and "libjson-perl"
=cut

package bluesky_cli;

use Data::Dumper;
use Try::Tiny;
use HTTP::Request::Common qw(POST);  
use JSON::XS qw(encode_json);
use JSON::XS qw(decode_json);
use LWP::UserAgent; 


# Constructor.
sub new
{
	my $class = shift;
	my $self = {
		_blueskyGateway => shift,
		_username       => shift,
		_password       => shift,
	};
	$self->{_blueskyGateway} =~ s/http:\/\///g;
	$self->{_blueskyGateway} =~ s/\/$//g;
	$self->{_blueskyGateway} = "http://" . $self->{_blueskyGateway};
	bless $self, $class;
	return $self;
}

# test the library.
sub test {
	my( $self ) = @_;
	print "\r\n[test...]:\r\n";

	print "\r\n[test createBlueskyParam]:\r\n";
	@opts = ('noneFix', 'edconnected');
	print "test opts: " . $opts[0] . "\r\n";
	$params = $self->createBlueskyParam('ls', @opts);
	print "params: " . $params;

	print "\r\n";

	print "\r\n[test login]:\r\n" . $self->login() . "\r\n";
	print "\r\n[test logout]:\r\n" . $self->logout() . "\r\n";
	
	print "\r\n";

	$getResult = $self->blueskyGet($params);
	print "\r\n[test blueskyGet]:\r\n" . $getResult . "\r\n" if(defined($getResult));
	
	print "\r\n";
	
	print "\r\n[test list_ed]:\r\n";
	@embeddedDeviceList = $self->list_ed();
	#print "in test: " . $embeddedDeviceList[0]->{'EDIP'} . "\r\n";
	foreach $ed (@embeddedDeviceList) {
		print $ed->{'EDIP'} . "\r\n";
	}

	print "\r\n";

	print "[test sensornetwork]:\r\n";
	@snOpts = ("172.16.4.105", "gpio", "set", "21", "0");
	$sn = $self->sensornetwork(@snOpts);
	print $sn . "\r\n";

	print "\r\n";

	print "[test getSensorDatByAdc]:\r\n";
	@adc = $self->getSensorDatByAdc("172.16.4.105", "mcp3208");
	print "\r\nsensor data: " . $adc[0] . "\r\n";
	#print $adc[0] . "\r\n" if(defined($adc));
	return;
}

# Using sensornetwork with bluesky API.
sub sensornetwork {
	my( $self, @opts ) = @_;
	$params = $self->createBlueskyParam("sensornetwork", @opts);
	$doTheAPI = $self->blueskyGet($params);
	return $doTheAPI;
}

# Get sensor data from the sensor that is connecting ADC modules.
sub getSensorDatByAdc {
	my( $self, $deviceIP, $adcmodule ) = @_;
	$mosi = "10";
	$miso = "9";
	$clk = "11";
	$ce = "8";
	$sensorDat = "";
	@spiDat = ();
	@opts = ($deviceIP, "spi", $adcmodule, $mosi, $miso, $clk, $ce);
	$sensorDat = $self->sensornetwork(@opts);
	# simple check the json pattern.
	if($self->isJsonPattern($sensorDat)){
		$jsonDecoded = decode_json($sensorDat) or die "ERR.";
	}else{
		$jsonDecoded = {};
	}
	if (defined($jsonDecoded)){
		@spiDat = @{$jsonDecoded->{'ETLog'}->{'logging'}->{'spi'}};
	}
	return @spiDat;
}

sub isJsonPattern {
	my( $self, $dat ) = @_;
	if($dat =~ m/^{/){
		# true
		return 1;
	}else{
		# false
		return 0;
	}
}

# Return the list of connecting embedded devices information. 
sub list_ed {
	my( $self ) = @_;
	@ret = ();
	@listOpts = ('noneFix', 'edconnected');
	$listInst = "ls";
	$params = $self->createBlueskyParam($listInst, @listOpts);
	$embeddedDeviceList = $self->blueskyGet($params);
	$jsonList = decode_json $embeddedDeviceList;

	if(defined($jsonList)) {
		@ret = @{$jsonList->{'ETLog'}->{'EDConnStatement'}};
	}
	return @ret;
}

# Convert to parameter of HTTP.
sub createBlueskyParam {
	my( $self, $instruction, @opts ) = @_;
	$ret = "/etLog?instruction=" . $instruction;
	$i = 0;
	foreach $opt (@opts) {
		$i++;
		$ret .= "&opt" . $i . "=" . $opt;
	}
	return $ret;
}

# Do something with Bluesky API.
sub blueskyGet {
	my( $self, $blueskyParam ) = @_;
	$isLogin = $self->login();
	$ret;
	$getCli = LWP::UserAgent->new;
	$getCli->timeout(10);
	$getCli->env_proxy;

	$res = $getCli->get($self->{_blueskyGateway} . $blueskyParam);

	if ($res->is_success) {
		#print $res->decoded_content;
		$ret = $res->decoded_content;
	}else {
		#die $res->status_line;
	}

	$isLogout = $self->logout();
	return $ret;
}

# login to the system as the public account.
sub login {
	my( $self ) = @_;
	$cli = LWP::UserAgent->new();  
	for( $i = 0; $i < 2; $i++ ) {
		$req = POST $self->{_blueskyGateway} . '/doLogin.ins', [ 
			username=> $self->{_username},
			password=> $self->{_password},
			mode    => 'signin',
		];
		$req->content_type('application/json');
		$loginResult = $cli->request($req)->content;
		$resultDecoded = decode_json $loginResult;
		$isLogin = $resultDecoded->{'ETLog'}->{'login'}->{'result'};
		if($isLogin eq "true") {
			break;
		}
	}
	return $isLogin;
}

# logout from the system from the account.
sub logout {
	my( $self ) = @_;
	$cli = LWP::UserAgent->new();  
	for( $i = 0; $i < 2; $i++ ) {
		$req = POST $self->{_blueskyGateway} . '/doLogout.ins', [ 
			username=> $self->{_username},
			mode    => 'signout',
		];
		$req->content_type('application/json');
		$logoutResult = $cli->request($req)->content;
		$resultDecoded = decode_json $logoutResult;
		$isLogout = $resultDecoded->{'ETLog'}->{'logout'}->{'result'};
		if($isLogout eq "true") {
			break;
		}
	}
	return $isLogout;
}
1;
