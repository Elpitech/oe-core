#!/bin/bash
for i in ./meta-baikal-t/conf/machine/*.conf; do basename $i | /usr/bin/cut -d "." -f 1; done
