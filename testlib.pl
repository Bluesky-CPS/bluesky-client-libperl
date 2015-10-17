require bluesky_cli;

$blueskyGateway = "127.0.0.1:8189"; 
$conn = new bluesky_cli( $blueskyGateway, "guest", "guest" );

#$conn->test();

# print all sensor data [on the available devices.]
@embeddedDeviceList = $conn->list_ed();
foreach $ed (@embeddedDeviceList) {
	@sensorDat = ();
	@sensorDat = $conn->getSensorDatByAdc($ed->{'EDIP'}, "mcp3208");
	#$len = scalar(@{sensorDat});
	#print $len . " \r\n";
	print $ed->{'EDIP'} . ":\r\n";
	print "[ ";
	foreach $ch (@sensorDat) {
		print $ch . ", ";
	}
	print " ]\r\n";
}
