# yabt

#### Table of Contents

2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What yabt affects](#what-yabt-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with yabt](#beginning-with-yabt)
4. [Usage](#usage)
5. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Module Description

[Yabt](https://github.com/mikmanzato/yabt) is the Yet-another backup tool, a 
simple but effective backup tool for GNU/Linux systems. This [Puppet module](https://docs.puppetlabs.com/puppet/latest/reference/modules_fundamentals.html)
simplifies the task of installing Yabt and creating configurations to manage 
backup jobs.

## Setup

### What yabt affects

This module affects just the yabt configuration files and directories.

### Beginning with yabt

To have Puppet install Yabt with the default parameters, declare the yabt class:

``` puppet
class { '::yabt': }
```

You can also configure some global defaults related to notifications and 
dump or backup destinations:

``` puppet
class { '::yabt':
    dump_location               => 'ftps://user:pass@ftp.example.com/',
    rdiffbackup_destination     => 'user@example.com::',
    notifications_enabled       => true,
    notifications_from          => 'yabt@example.com',
    notifications_recipients    => 'me@example.com,you@example.com',
    notifications_smtp_hostname => 'localhost',
    sn_recurrence               => 'daily',
}
```

Then you configure specific dump or backup jobs. This is a rdiff-backup job of a 
local directory */home/user*:

``` puppet
::yabt::rdiffbackup_job { 'yabt_home_user':
    source => '/home/user',
}
```

which will use the global `rdiffbackup_destination` configured above. 

A MySQL dump job looks like this:

``` puppet
::yabt::mysqldb_dump_job { 'yabt_mysqldump_myapp':
    user         => 'mysql_user',
    password     => 'mysql_pass',
    hostname     => 'mysql_host',
    dbname       => 'mysql_dbname',
    storage_dir  => "/var/lib/myapp/storage",
}
```

which will use the global `dump_location` configured above.


## Usage

### Initialization

Class `::yabt` defines common settings.

``` puppet
class { '::yabt':
    dump_location               => 'ftps://username:password@host/dir',
    duplicity_target_url        => 'ftp://username:password@host/dir',
    rdiffbackup_destination     => 'username@hostname::',
    notifications_enabled       => true,
    notifications_from          => 'yabt@example.com',
    notifications_recipients    => 'yourname@example.com',
    sn_recurrence               => 'daily',
}
```


### Directory dump job

The `::yabt::dir_dump_job` resource backs up a local directory.

``` puppet
::yabt::dir_dump_job { 'job_name':
    path  => "path_to_directory",
}
```


### Etc directory dump job

The `::yabt::etc_dir_dump_job` resource backs up the */etc* directory.

``` puppet
include ::yabt::etc_dir_dump_job
```


### MySQL database dump job
    
The `::yabt::mysqldb_dump_job` resource dumps a MySQL database. The dump is
performed using `mysqldump` which must be installed on the local system.
    
``` puppet
::yabt::mysqldb_dump_job { 'job_name':
    user         => 'mysql_username',
    password     => 'mysql_password',
    hostname     => 'mysql_server_host',
    dbname       => 'name_of_db',
}
```

If the database references data files which are stored on the filesystem one
can backup the filesystem storage together with the database. Actually, the
filesystem is backed up just after the database is dumped (using tar) and a
tarfile is produced which contains both the database dump and the filesystem 
dump.

``` puppet
::yabt::mysqldb_dump_job { 'job_name':
    user         => 'mysql_username',
    password     => 'mysql_password',
    hostname     => 'mysql_server_host',
    dbname       => 'name_of_db',
    storage_dir  => "path_to_storage_directory",
}
```


### Rdiffbackup backup job

The `::yabt::rdiffbackup_job` resource backs up a local directory to a target 
location. The directory is backed up using `rdiffbackup` which must be installed
locally (note that puppet-yabt does not take care of installing rdiffbackup).

``` puppet
::yabt::rdiffbackup_job { 'job_name':
    source => 'path_of_local_directory_to_backup',
}
```


### Status notification job

The `::yabt::status_notification_job` sends email notifications to 
configured recipients to communicate the backup status or specific backup errors.

``` puppet
::yabt::status_notification_job
```


## Reference

TODO


## Limitations

This module has been developed and tested under Ubuntu Linux version 16.04 and
Puppet 3.8. It should reasonably work under any Debian-based distribution as
well as Puppet 3.8+ and 4+.

Input is welcome to add support for other platforms.


## Development

TODO
