#!/bin/bash -e

#@Author: Maxime <maxime.demoulin@hederatech.com>
#@Date: 11/02/11
#@Args: package's version number

#this script aims to build all the kanopya's package at the same time, and has to be launch in the same dir than the other packages building scripts.


./package_builder.pl libkanopya-perl
./package_builder.pl kanopya-bootmanager
./package_builder.pl kanopya-core
./package_builder.pl kanopya-storage
./package_builder.pl kanopya-webui
./package_builder.pl kanopya-monitor
./package_builder.pl kanopya-orchestrator
./package_builder.pl kanopya-dev
./package_builder.pl kanopya
