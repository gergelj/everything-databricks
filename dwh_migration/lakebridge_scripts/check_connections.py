#!/usr/bin/env python3
"""Check network connectivity to a fixed list of hosts.

For each host it does a DNS resolve followed by a TCP connect (default
port 443). Prints a table and exits with the number of failed hosts
(0 = everything reachable).

Usage:
     python check_connections.py
"""

import socket
import sys

# Hosts to check (from address.txt).
HOSTS = [
    "api.github.com",
    "github.com",
    "raw.githubusercontent.com",
    "pypi.org",
    "files.pythonhosted.org",
    "repo1.maven.org",
]

PORT = 443
TIMEOUT = 5.0


def resolve(host):
    """Return the resolved IP address, or None if DNS resolution fails."""
    try:
        return socket.gethostbyname(host)
    except socket.gaierror:
        return None


def tcp_connect(host, port):
    """Return True if a TCP connection to host:port succeeds."""
    try:
        with socket.create_connection((host, port), timeout=TIMEOUT):
            return True
    except (OSError, socket.timeout):
        return False


def main():
    failures = 0

    header = f"{'HOST':<32} {'PORT':<6} {'DNS':<16} {'TCP':<6}"
    print(header)
    print("-" * len(header))

    for host in HOSTS:
        port = PORT

        ip = resolve(host)
        if ip is None:
            dns_status = "FAIL"
            tcp_status = "-"
            failures += 1
        else:
            dns_status = ip
            if tcp_connect(host, port):
                tcp_status = "ok"
            else:
                tcp_status = "FAIL"
                failures += 1

        print(f"{host:<32} {port:<6} {dns_status:<16} {tcp_status:<6}")

    print()
    print(f"checked {len(HOSTS)} host(s), {failures} failure(s)")
    return failures


if __name__ == "__main__":
    sys.exit(main())
