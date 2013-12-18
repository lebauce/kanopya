class kanopya::dhcpd(
  $interfaces  = [],
  $ntpservers  = [],
  $dnsdomain   = "hederatech.com",
  $nameservers = [],
  $hosts       = [],
  $pools       = [])
{
  class { 'dhcp':
    interfaces  => $interfaces,
    ntpservers  => $ntpservers,
    dnsdomain   => $dnsdomain,
    nameservers => $nameservers,
  }

  create_resources('dhcp::pool', $pools)
  create_resources('dhcp::host', $hosts)
}
