#!/usr/bin/env bash
# fix python34/python34u and python36/python36u conflicts

# https://gist.github.com/centminmod/e050cf02794fb5bcdf3090c28efab202
# https://community.centminmod.com/threads/python-conflict-on-update.17144/

if [[ "$(rpm -qa python34u)" ]]; then
    # remove ius community python34u
    yum -y remove python34u python34u-devel python34u-pip python34u-setuptools python34u-tools python34u-libs python34u-tkinter
    # install epel python34
    yum -y install python34 python34-devel python34-pip python34-setuptools python34-tools python34-libs python34-tkinter
fi

# only apply to centos 7 as centos 6 epel doesn't have python36
if [[ -f /bin/systemctl && "$(rpm -qa python36u)" ]]; then
    # remove ius community python36u
    yum -y remove python36u python36u-devel python36u-pip python36u-setuptools python36u-tools python36u-libs python36u-tkinter
    # install epel python36
    yum -y install python36 python36-devel python36-pip python36-setuptools python36-tools python36-libs python36-tkinter
fi

if [[ ! "$(rpm -qa cmake3)" ]]; then
    # reinstall removed dependencies from above removed ius community packages
    yum -y install cmake3 cmake3-data
fi