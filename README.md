# yabt

#### Table of Contents

1. [Module Description](#module-description)
2. [Setup](#setup)
    * [What yabt affects](#what-yabt-affects)
    * [Beginning with yabt](#beginning-with-yabt)
3. [Usage](#usage)
4. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)
7. [Copyright](#copyright)

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

All global configuration will end up in the main yabt configuration file, 
*/usr/local/etc/yabt/main.conf*.

Then you configure specific dump or backup jobs. Configuration for jobs will 
end up in the job configuration directory, */usr/local/etc/yabt/jobs.d/*.
Each job configuration file will be named after the job.

This is a rdiff-backup job of a local directory */home/user*:

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

This section highlights the main classes and the basic configuration. Additional
configuration options are documented in the [reference section](#reference).


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

The `::yabt::dir_dump_job` resource dumps a local directory in "tar" format. 

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

It is a special case of the directory dump job.


### Subversion repositories dump job

The `::yabt::svn_dump_job` resource backs up local subversion repositories. 

``` puppet
::yabt::svnrepositories_dump_job { 'svnrepositories':
    parent_path => '/var/svnroot',
}
```

All repositories in directory `parent_path` will be backed up.


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


### Duplicity backup job

The `::yabt::duplicity_job` resource backs up a local directory to a target 
location. The directory is backed up using `duplicity` which must be installed
locally (note that *puppet-yabt* does not take care of installing rdiffbackup).

``` puppet
::yabt::duplicity_job { 'job_name':
    source_dir => 'path_of_local_directory_to_backup',
}
```


### Rdiffbackup backup job

The `::yabt::rdiffbackup_job` resource backs up a local directory to a target 
location. The directory is backed up using `rsync` which must be installed
locally (note that *puppet-yabt* does not take care of installing rsync, 
nonetheless rsync is typically installed by default).

``` puppet
::yabt::rdiffbackup_job { 'job_name':
    source => 'path_of_local_directory_to_backup',
}
```


### Rsync backup job

The `::yabt::rsync_job` resource backs up a local directory to a target 
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

### Public classes

#### Class: `yabt`

Guides the basic setup and installation of Yabt on your system.

When this class is declared with the default options, Puppet:

  * Does not send any notification
  * Does not configure any default destination 
  * Install or updates Yabt at the latest version released

You can simply declare the default Yabt class:

class { '::yabt': }

This class will download and install yabt from the distribution location. Note 
that dependencies are NOT installed, such as PHP or the client tools required to
support the various kinds of dump or backup jobs.

**Parameters within `yabt`:**

##### `notifications_enabled`

Enable email notifications. Default: false, which means that no email 
notifications are sent at all.

##### `notifications_from`

Email address of the sender of the notification email.

Default: undef, which means that no email notifications are sent at all.

##### `notifications_recipients`

Email address(es) of the recipients of the notification email.

Default: undef, which means that no default notification recipients are 
configured, and hence, no email notifications are sent at all.

##### `notifications_smtp_hostname`

The SMTP host to use to send email.

Default: 'localhost', which uses a locally installed SMTP server.

##### `dump_location`

The default location for dump jobs, which applies if no other `dump_location`s 
are set in the dump jobs.

Default: undef, which means that no default dump location is set. A `dump_location` 
must be provided for every dump job.

##### `duplicity_target_url`

The default target URL for duplicity backup jobs.

Default: undef, which means that no default target url is set. A `target_url` 
must be provided for every Duplicity job.

##### `rdiffbackup_destination`

Default: undef, which means that no default destination is set. A `destination` 
must be provided for every Rdiff-backup job.

##### `rsync_destination`

Default: undef, which means that no default destination is set. A `destination` 
must be provided for every Rdiff job.

##### `sn_recurrence`

Recurrence for the default status notification job. Use `false` to disable the
default status notification job.

Default: 'weekly', which means that a weekly email is sent.

##### `sn_at`

When the default status notification job runs. 

Default: undef, which means that the email will be sent at the default time 
(which depends on the recurrence, but is generally at 03:30).

##### `sn_complete_recurrence`

Recurrence for the backup complete status notification job. Use `false` to 
disable the default complete status notification job.

Default: 'monthly', which means that a monthly email with the complete status 
is sent.

##### `sn_complete_at`

When the default complete status notification job runs. 

Default: undef, which means that the email will be sent at 03:30 of the 5th day 
of the month (if the default monthly recurrence is used).

##### `ensure`

Either `present` or `absent`. When `present` then Yabt is ensured installed, 
whereas `absent` disinstalls Yabt.

Default: 'present'.

##### `version`

The version of Yabt to install.

Default: 'latest', which means that the latest Yabt version is installed.


#### Common job parameters

##### `phase`

Running phase, numeric value from 0 to 10. Jobs in a lower phase run earlier 
than jobs in a higher phase. Used to run notification jobs at later phases than 
dump and backup jobs.

Default: depends on the type of job. Dump and backup jobs generally default to 
phase 5, while notification jobs default to phase 9.

##### `recurrence`

Tells how often the job is run. Possible choices are: `hourly`, `daily`, 
`weekly` or `monthly`. The `at` parameter tells *when* the job will run given 
its recurrence.

Default: `weekly`

##### `at`

Tells when the job should be run. Format differs depending on the
`recurrence` value:

  * for `hourly` recurrence it is in the format `:MM` where MM are the
    minutes in the hour
  * for `daily` recurrence it is in the format `HH:MM` where HH:MM is the
    hour and minutes in the day
  * for `weekly` recurrence it is in the format `dayname, HH:MM` where day
    is the name of the day either abbreviated or full (sun, mon, tue... or
    sunday, monday, tuesday, ...) and HH:MM is the hour and minutes in the
    day
  * for `monthly` recurrence it is in the format `D, HH:MM` where day is
    the day number in the month (1, 2, ...31) and HH:MM is the hour and
    minutes in the day

Examples (which are also the defaults applied when the `at` parameter is
omitted):

    05, 03:30    ; monthly recurrence: runs on day 5 at 03:30
    Sun, 03:30   ; weekly recurrence: runs on Sundays at 03:30
    03:30        ; daily recurrence: runs every day at 03:30
    :30          ; hourly recurrence: runs every hour at minute 30

Note that the job is not guaranteed to run *at the exact time* indicated in the 
`at` parameter. If there is another job running at the same time the job 
execution will be deferred.

##### `enabled`

Default: true, which means that the job is configured to run. Use false to 
disable job execution, still preserving the configuration file.

##### `ensure`

Default: 'present', which means that the job is configured. Use 'absent' to 
remove the job.


#### Common dump job parameters

Dump jobs produce "dump file"s out of the source content. For dump jobs, Yabt 
controls and takes care directly of the backup files produced, as well as 
retention and incrementality. 

See (here)[https://github.com/mikmanzato/yabt#dump-jobs] for additional 
information on dump jobs.

Dump jobs share the following parameters.

##### `retention_period`

Number of previous dumps to retain. Works together with the `recurrence` 
parameter in the `[job]` section: for daily recurrence the retention period is 
a number of days while for weekly recurrence the retention is a number of weeks

Default: 14

##### `full_period`

Number of runs after which a full dump is always executed.

Default: 7

##### `incremental`

`true` activates incremental dumps. Yabt will store only differences from the 
previous dump, saving time and space. Not all dump jobs support incrementality.

Default: `true` (where supported).

##### `dump_location`

Where dump files are stored. It is expressed in a URI-like
format. It is a "root directory", each dump is stored in subdirectories of
this directory. A number of possibilities are currently supported:

  * a local directory:

        file:///var/backups

  * a space on a FTP server:

        ftp://username:password@hostname/path

  * a space on a FTPS server (where possible this is to be preferred over FTP):

        ftps://username:password@hostname/path

  * a space on a SFTP (ssh2) server:

        ssh2://username:password@hostname/path

By default, the `dump_location` configured with `yabt` class is used.


#### Define: `yabt::status_notification_job`

Configures a status notification job. An e-mail is sent with a report of the 
status of the jobs.

See (here)[https://github.com/mikmanzato/yabt#status-notification-job] 
for additional usage information.

**Parameters within `yabt::status_notification_job`:**

See also the [common job parameters](#common-job-parameters).

##### `complete`

When `true`, a complete report is produced, including also successful jobs. 
When `false`, only failed backups are notified and if no job failed no report 
is sent at all.

Default: `false`


#### Define: `yabt::dir_dump_job`

Stores all files from a local directory into a *.tar.bz2* file.

See (here)[https://github.com/mikmanzato/yabt#directory-dump-job] for additional
usage information.

**Parameters within `yabt::dir_dump_job`:**

See also the [common job parameters](#common-job-parameters) and the 
[common dump job parameters](#common-dump-job-parameters).

##### `path`

Required. The path to the directory to dump.


#### Class: `yabt::etc_dir_dump_job`

Specialized directory dump job which dumps the contents of the */etc* directory.

**Parameters within `yabt::dir_dump_job`:**

Class has no custom parameter. See the [common job parameters](#common-job-parameters) 
and the [common dump job parameters](#common-dump-job-parameters).



#### Define: `yabt::mysqldb_dump_job`

Dumps a [MySQL](https://www.mysql.com/) database. Optionally dumps also
content stored on the filesystem but referenced by the database.

See also the [common job parameters](#common-job-parameters) and the 
[common dump job parameters](#common-dump-job-parameters).

See (here)[https://github.com/mikmanzato/yabt#mysql-dump-job] 
for additional usage information.

**Parameters within `yabt::mysqldb_dump_job`:**

##### `dbname`

Required. Name of the database.

##### `user` and `password`

Required. The access credentials to the database.

##### `hostname`

Location of the MySQL server. Defaults to 'localhost'

##### `port`

TCP/IP port where MySQL listens. Defaults to port 3306

##### `storage_dir`

Path to the filesystem directory where files are stored. Optional, when not 
provided no associated filesystem is backed up.


#### Define: `yabt::svnrepositories_dump_job`

Dumps all svn repositories contained into a directory (the "parent directory"). 
This job must be configured on a server which mounts the parent directory as a 
local directory.

See also the [common job parameters](#common-job-parameters) and the 
[common dump job parameters](#common-dump-job-parameters).

See (here)[https://github.com/mikmanzato/yabt#subversion-repositories-dump-job] 
for additional usage information.

**Parameters within `yabt::svnrepositories_dump_job`:**

##### `parent_path`

Required. The directory which contains the SVN repositories to dump. It must be 
a local directory.


#### Define: `yabt::rsync_job`

Back up a local directory using [rsync](https://rsync.samba.org/).

See also the [common job parameters](#common-job-parameters).

See (here)[https://github.com/mikmanzato/yabt#rsync-job] 
for additional usage information.

**Parameters within `yabt::rsync_job`:**

##### `source`

Path to local directory to back up.

##### `destination`

Where to back-up files to. Examples are:

  * `user:pass@rsynchost:/path`: back up to a remote rsync server (recommended)
  * `/var/backups/`: back up to a local directory

Default: the value configured in `rsync_destination` in the `yabt` class.


#### Define: `yabt::duplicity_job`

Back up a local directory using [duplicity](http://duplicity.nongnu.org/).

See also the [common job parameters](#common-job-parameters).

See (here)[https://github.com/mikmanzato/yabt#duplicity-job] 
for additional usage information.

**Parameters within `yabt::duplicity_job`:**

##### `source_dir`

Required. Path to the local directory to back up.

##### `passphrase`

Required. A non-obvious alphanumeric string which is used by duplicity to 
encrypt the backup files before they are stored.
    
##### `target_url`

Optional. URL of the target location to backup to.

Default: the value configured in `duplicity_target_url` in the `yabt` class.

##### `retention_period`

Optional. Number of days to retain in the backup. Default: 180

##### `full_period`

Optional. Number of days after which to run a full backup. Default: 60


#### Define: `yabt::rdiffbackup_job`

Back up a local directory using [rdiff-backup](http://www.nongnu.org/rdiff-backup/).

See (here)[https://github.com/mikmanzato/yabt#rdiff-backup-job] 
for additional usage information.

**Parameters within `yabt::rdiffbackup_job`:**

See also the [common job parameters](#common-job-parameters).

##### `source`

Path to local directory to back up.

##### `destination`

The location where to store the backup copy. It can be a 
local destination:
        
    /path/to/local/directory

or a destination on a remote machine:
  
    user@hostname::/path/to/remote/directory

In this case you should pre-initialize access to the remote machine by 
copying the public SSH key [for example as it is explained here](https://www.howtoforge.com/linux_rdiff_backup).

Default: the value configured in `rdiffbackup_destination` in the `yabt` class.

##### `retention_period`

Remove the incremental backup  information  in  the destination directory that 
has been around longer than the given time. time_spec can be either an absolute 
time, like "2002-01-04",  or a  time interval. The time interval is an integer 
followed by the character s, m, h, D, W, M, or Y, indicating  seconds,  
minutes,  hours,  days,  weeks, months, or years respectively, or a number of 
these concatenated.  For example, 32m  means  32  minutes,  and 3W2D10h7s means 
3 weeks, 2 days, 10 hours, and 7 seconds. See also rdiff-backup's 
`--remove-older-than` option.
    
Default: '1Y' which corresponds to one year.


## Limitations

This module has been developed and tested under Ubuntu Linux version 16.04 and 
Puppet 3.8. It was tested working under Debian Jessie. It should 
reasonably work under any Debian-based distribution as well as Puppet 3.8+ and 
4+.


## Development

Input is welcome to add support for other platforms.


## Copyright

Copyright (c) Michele Manzato.

The Puppet module for Yabt is open source software licensed under the MIT 
License. Basically, you are free to use Yabt in any commercial or 
non-commercial project, you can modify the code as you wish as long as you 
don't change licensing and retain the original copyright statement.

See Yabt documentation for additional copyright information.

## Disclaimer

This Puppet module for Yabt is released as-is. I cannot guarantee fitness of 
Yabt for any particular use and I cannot assume any direct or indirect 
liability should your system or your data be damaged or lost due to proper or 
improper use of Yabt, or due to bugs in the Puppet module itself or third-party 
programs run by this module.
