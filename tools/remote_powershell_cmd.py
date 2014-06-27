#!/usr/bin/python

# Execute a powershell command on a remote host using kerberos authentication
#
# A valid non-expired Ticket must exist (see klist, kinit)
#
# Troubleshooting :
#
# "winrm.exceptions.WinRMTransportError: Kerberos-based authentication was failed. Code 500"
# => Winrm/Config/Service/AllowUnencrypted must be true on target machine
#
# "kerberos.GSSError: (('Unspecified GSS failure.  Minor code may provide more information', 851968), ("Credentials cache file '/tmp/krb5cc_0' not found", -176$
# => Client must renew the kerberos Ticket (kinit <user>)

import sys, getopt

from winrm.protocol import Protocol
import kerberos

def main(argv):
    usage =  __file__ + ' -t <targetHost> -c <powershellCommand>'

    target = ''
    command = ''
    try:
        opts, args = getopt.getopt(argv,"t:c:")
    except getopt.GetoptError:
        print usage
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-t':
            target = arg
        elif opt == '-c':
            command = arg

    if not target or not command:
        print usage
        sys.exit(2)

    run_command(command, target)


def run_command(command, target):

    p = Protocol(
        endpoint='https://' + target + ':5986/wsman',
        transport='kerberos',
    )

    # We do not want prined info about kerberos ticket
    stdout_orig = sys.stdout
    f = open('/dev/null', 'w')
    sys.stdout = f

    try:
        shell_id = p.open_shell()
        command_id = p.run_command(shell_id, 'powershell', [command])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)

        sys.stdout = stdout_orig

        print std_out

        if std_err:
            sys.exit(std_err)

    except kerberos.GSSError as e:
        print >> sys.stderr, "kerberos GSSError:", e
        sys.exit(2)
    except:
        print >> sys.stderr, "Unexpected error during remote ps command execution :", sys.exc_info()[0], sys.exc_info()[1]
        sys.exit(2)


if __name__ == "__main__":
    main(sys.argv[1:])
