#!/usr/bin/env python

# Copyright 2016 Bluebox, an IBM Company
# Copyright 2016 Ivo Vasev <ivasev at us.ibm.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import division

import argparse
import sys
import subprocess
from subprocess import check_output
import traceback

# Standard Nagios return codes
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

argparser = argparse.ArgumentParser()
argparser.add_argument('--criticality',
                       help='Set sensu alert level, default is critical',
                       default='critical')
options = argparser.parse_args()


def switch_on_criticality():
    if options.criticality == 'warning':
        sys.exit(WARNING)
    else:
        sys.exit(CRITICAL)


def main():
    # grep '^'"$(date +"%F %R")" nova-api.log > 1minute_tmp |
    # grep 'status:' 1minute_tmp | wc -l

    try:
        one_min_all_requests = int(check_output(
            ["/etc/sensu/plugins/minute_all.sh"]))
        one_min_err_requests = int(check_output(
            ["/etc/sensu/plugins/minute_err.sh"]))
    except subprocess.CalledProcessError as e:
        raise RuntimeError("command '{}' return with error (code {}): {}".format(
            e.cmd, e.returncode, e.output))

    if one_min_all_requests != 0:
        failures = 100.0 * one_min_err_requests / one_min_all_requests
        if failures < 5:
            state = OK
            print "Requests failure rate {failures} is less then 5.0%".format(
                failures=failures)
        elif failures > 5 and failures < 10:
            state = WARNING
            print "Requests failure rate {failures} is more then 5.0%".format(
                failures=failures)
        elif failures > 10:
            state = CRITICAL
            print "Requests failure rate {failures} is more then 10.0%".format(
                failures=failures)
    else:
        print "0 incoming requests received last minute"
        state = UNKNOWN
    print "Nova api requests received on the node for 1 min: {reqs}".format(
        reqs=one_min_all_requests)
    sys.exit(state)

if __name__ == '__main__':
    try:
        main()
    except Exception:
        traceback.print_exc(file=sys.stdout)
        sys.exit(CRITICAL)
