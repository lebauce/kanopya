#!/bin/bash -e

#@Author: Maxime <maxime.demoulin@hederatech.com>
#@Date: 11/02/11
#@Args: package's version number

#this script aims to build all the kanopya's package at the same time, and has to be launch in the same dir than the other packages building scripts.


./package_builder.pl libkanopya-perl $1
./package_builder.pl kanopya-bootmanager $1
./package_builder.pl kanopya-core $1
./package_builder.pl kanopya-storage $1
./package_builder.pl kanopya-webui $1
./package_builder.pl kanopya-monitor $1
./package_builder.pl kanopya-orchestrator $1
./package_builder.pl kanopya-dev $1
./package_builder.pl kanopya $1
