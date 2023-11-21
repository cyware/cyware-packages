# Certificate tool - Variables
# Copyright (C) 2015, KhulnaSoft Ltd.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

base_path="$(dirname "$(readlink -f "$0")")"
readonly base_path
readonly config_file="${base_path}/config.yml"
readonly logfile=""
cert_tmp_path="/tmp/cyware-certificates"
debug=">> /dev/null 2>&1"