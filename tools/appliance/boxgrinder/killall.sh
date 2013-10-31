#!/bin/bash

ps aux | grep mysqld | awk '{ print $2 }' | xargs -i sh -c 'test -e /proc/{} && kill -9 {} || true'
