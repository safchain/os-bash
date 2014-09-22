#!/usr/bin/env bash

_RH=${ROOT_HELPER:-"sudo"}

function _fatal() {
    echo $1
    exit -1
}

function vm_create() {
    if [ -z "$2" ]; then
        _fatal "Usage: $0 vm-create <vm name> <cidr>"
    fi

    if ip netns | grep $1; then
        _fatal "The vm specified already exists"
    fi

    $_RH ip netns add vm-$1
    $_RH ip netns exec vm-$1 ip l set lo up
    $_RH ip l add name vm-$1-eth0 type veth peer name eth0 netns vm-$1
    $_RH ip l set vm-$1-eth0 up
    $_RH ip netns exec vm-$1 ip l set eth0 up
    $_RH ip netns exec vm-$1 ip a add $2 dev eth0
}

function vm_delete() {
    if [ -z "$1" ]; then
        _fatal "Usage: $0 vm-delete <vm name>"
    fi

    $_RH ip l delete vm-$1-eth0
    $_RH ip netns del vm-$1
}

#set -x

function tun_create() {
    if [ -z "$2" ]; then
        _fatal "Usage: $0 tun-create <tun name> <remote_ip>"
    fi
    $_RH ovs-vsctl add-br br-$1
    $_RH ovs-vsctl add-port br-$1 gre-$1 -- set interface gre-$1 type=gre \
        options:remote_ip=$2
}

function tun_delete() {
    if [ -z "$1" ]; then
        _fatal "Usage: $0 tun-delete <tun name>"
    fi
     $_RH ovs-vsctl del-br $1
}

case $1 in
    vm-create)
        vm_create $2 $3;;
    vm-delete)
        vm_delete $2;;
    tun-create)
        tun_create $2 $3;;
    tun-delete)
        tun_delete $2;;
    *)
        _fatal "Not valid operation $1";;
esac
