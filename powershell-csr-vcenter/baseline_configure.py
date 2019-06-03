#! /usr/bin/env python
"""Send baseline configuraiton to a network device

Copyright (c) 2018 Cisco and/or its affiliates.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

# Import libraries
from netmiko import ConnectHandler

# Configuration commands to send to device
baseline_config = [
    "netconf-yang",
    "restconf",
]

def send_baseline(device):
    # Open CLI connection to device
    with ConnectHandler(ip = device["address"],
                        port = device["ssh_port"],
                        username = device["username"],
                        password = device["password"],
                        device_type = device["device_type"]) as ch:

        # Send configuration to device
        output = ch.send_config_set(baseline_config)

        # Print the raw command output to the screen
        print("The following configuration was sent: ")
        print(output)

        # Saving Configuration
        save = ch.send_command("write mem")
        print(save)


if __name__ == "__main__":
    # Use Arg Parse to retrieve device details
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--address", help="Device Address", required=True
    )
    parser.add_argument(
        "--username", help="Device User - default = 'developer'", default="developer"
    )
    parser.add_argument(
        "--password", help="Device Password - default = 'C1sco12345'", default="C1sco12345"
    )
    parser.add_argument(
        "--ssh_port", help="Device SSH Port - default = 22", default=22
    )
    parser.add_argument(
        "--device_type", help="NetMiko Device Type - defaulte = 'cisco_ios'", default="cisco_ios"
    )

    args = parser.parse_args()


    device = {
        "address": args.address,
        "ssh_port": args.ssh_port,
        "username": args.username,
        "password": args.password,
        "device_type": args.device_type
    }

    print("Sending baseline configuraiton to device at address {}".format(args.address))
    send_baseline(device)
