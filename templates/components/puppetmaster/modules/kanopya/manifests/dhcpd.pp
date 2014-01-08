class kanopya::dhcpd(
  $interfaces  = [],
  $ntpservers  = [],
  $dnsdomain   = "hederatech.com",
  $nameservers = [],
  $hosts       = [],
  $pools       = [])
{
  tag("kanopya::operation::startnode")

  class { 'dhcp':
    interfaces  => $interfaces,
    ntpservers  => $ntpservers,
    dnsdomain   => $dnsdomain,
    nameservers => $nameservers,
  }

  create_resources('dhcp::pool', $pools)
  create_resources('dhcp::host', $hosts)
}
