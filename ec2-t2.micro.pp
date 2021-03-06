##
# Puppet script for configuring
# a base Amazon EC2 AmazonLinux t2.micro instance
# in preparation for installing eXist
#
# @author Adam Retter <adam.retter@googlemail.com>
#
##

$swap_size = 1048576
$exist_data_fs_dev = "/dev/sdb"
$exist_data = "/exist-data"

exec { "yum update":
	command => "/usr/bin/yum update -y"
}

##
# Create Swap file and Switch on the Swap
##
exec { "create swapfile":
	command => "/bin/dd if=/dev/zero of=/swapfile1 bs=1024 count=${swap_size}",
	creates => "/swapfile1"
}

exec { "mkswap":
	command => "/sbin/mkswap /swapfile1",
	refreshonly => true,
	subscribe => Exec["create swapfile"]
}

exec { "swapon":
	command => "/sbin/swapon /swapfile1",
	refreshonly => true,
	subscribe => Exec["mkswap"],
	before => Mount["swap"]
}

mount { "swap":
	device => "/swapfile1",
	fstype => "swap",
	ensure => present,
	options => defaults,
	dump => 0,
	pass => 0,
	require => Exec["create swapfile"]
}

##
# Create a storage filesytem for eXist's database
##
exec { "make database fs":
	command => "/sbin/mkfs -t ext4 ${exist_data_fs_dev}",
	unless => "/bin/mount | /bin/grep ${exist_data_fs_dev} | /bin/grep ext4",
	before => Mount[$exist_data]
}

file { $exist_data:
        ensure => directory,
        mode => 700,
}

mount { $exist_data:
	device => $exist_data_fs_dev,
	fstype => "ext4",
	ensure => mounted,
	options => defaults,
	dump => 0,
	pass => 2,
	require => File[$exist_data]
}

##
# Add eXist banner to the MOTD
##
file { "exist motd banner":
	path => "/etc/update-motd.d/10-exist-banner",
	ensure => present,
	mode => 0755,
	content =>
'#!/bin/sh

cat << "EOF"
        ____  ___.__           __ 
  ____  \   \/  /|__|  _______/  |_
_/ __ \  \     / |  | /  ___/\   __\
\  ___/  /     \ |  | \___ \  |  |
 \___  >/___/\  \|__|/____  > |__|
     \/       \_/         \/

NoSQL Native XML Database
and Application Platform

http://www.exist-db.org

Courtesy of Adam Retter http://www.adamretter.org.uk.

EOF'
}

exec { "update motd":
	command => "/usr/sbin/update-motd",
	require => File["exist motd banner"]
}

