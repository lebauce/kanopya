class kanopya::snmpd(
  $collector = "127.0.0.1"
) {
  class { 'snmp':
    agentaddress => [ 'udp:0.0.0.0:161' ],
    snmpd_config => [ "rocommunity kanopya ${collector}" ]
  }
}
