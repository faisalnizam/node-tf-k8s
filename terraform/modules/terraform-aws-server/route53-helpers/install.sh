#!/usr/bin/env bash
#
# Script used by gruntwork-install to install the route53-helpers module.
#

set -e

# Locate the directory in which this script is located
readonly script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Move the bin files into /usr/local/bin
sudo cp "${script_path}"/bin/add-dns-a-record /usr/local/bin

# Change ownership and permissions
sudo chmod +x /usr/local/bin/add-dns-a-record
