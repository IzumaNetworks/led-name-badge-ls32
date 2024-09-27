#!/bin/bash
modprobe -r usbhid
sleep 1
modprobe usbhid
