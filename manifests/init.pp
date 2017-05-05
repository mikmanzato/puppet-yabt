#

# General YABT setup
class yabt(
    $notifications_enabled = false,
    $notifications_from = undef,
    $notifications_recipients = undef,
    $notifications_smtp_hostname = 'localhost',
    $dump_location = undef,
    $duplicity_target_url = undef,
    $rdiffbackup_destination = undef,
    $rsync_destination = undef,
    $sn_recurrence = 'weekly',
    $sn_at = undef,
    $sn_complete_recurrence = 'monthly',
    $sn_complete_at = undef,
    $ensure = 'present',
    $version = 'latest',
) {
    include yabt::config
#    include mm::php::cli

    class { 'yabt::install':
        ensure  => $ensure,
        version => $version,
    }

    if ($ensure == 'present') {
        $main_conf = "${yabt::config::etc_dir}/main.conf"

        $notifications_changes = $notifications_enabled ? {
            true => [
                'set notifications/enabled 1',
                "set notifications/smtp_hostname ${notifications_smtp_hostname}",
                "set notifications/from ${notifications_from}",
                "set notifications/recipients ${notifications_recipients}",
            ],
            false => [
                'rm notifications/enabled',
                'rm notifications/smtp_hostname',
                'rm notifications/from',
                'rm notifications/recipients',
            ],
        }

        $dump_changes = $dump_location ? {
            undef => [ 'rm dump/location' ],
            default => [ "set dump/location ${dump_location}" ],
        }

        $duplicity_changes = $duplicity_target_url ? {
            undef => [ 'rm duplicity/target_url' ],
            default => [ "set duplicity/target_url ${duplicity_target_url}" ],
        }

        $rdiffbackup_changes = $rdiffbackup_destination ? {
            undef => [ 'rm rdiff-backup/destination' ],
            default => [ "set rdiff-backup/destination ${rdiffbackup_destination}" ],
        }

        $rsync_changes = $rsync_destination ? {
            undef => [ 'rm rsync/destination' ],
            default => [ "set rsync/destination ${rsync_destination}" ],
        }

        file { $yabt::config::etc_dir:
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            require => Class['yabt::install'],
        }

        file { $yabt::config::jobs_dir:
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            require => File[$yabt::config::etc_dir],
        }

        augeas { $name:
            lens    => 'Puppet.lns',
            incl    => $main_conf,
            changes => concat(
                $notifications_changes,
                $dump_changes,
                $duplicity_changes,
                $rdiffbackup_changes,
                $rsync_changes
            ),
            require => File[$yabt::config::etc_dir],
        }

        # Job to notify overall status (only failures)
        if ($sn_recurrence != false) {
            yabt::status_notification_job { 'sn':
                ensure     => $ensure,
                complete   => 0,
                at         => $sn_at,
                recurrence => $sn_recurrence,
                require    => File[$yabt::config::etc_dir],
            }
        }

        # Job to notify complete status
        if ($sn_complete_recurrence != false) {
            yabt::status_notification_job { 'snc':
                ensure     => $ensure,
                complete   => 1,
                at         => $sn_complete_at,
                recurrence => $sn_complete_recurrence,
                require    => File[$yabt::config::etc_dir],
            }
        }
    }
}


# Private class
# Generic Yabt job
define yabt::job (
    $type,
    $changes,
    $phase = undef,
    $recurrence = undef,
    $at = undef,
    $enabled = true,
    $ensure = 'present',
) {
    include yabt::config

    $full_conf = "${yabt::config::jobs_dir}/${name}.conf"

    if ($ensure == 'present') {
        include yabt

        $enabled_changes = $enabled ? {
            true   => [ 'set job/enabled 1' ],
            default => [ 'set job/enabled 0' ],
        }

        $phase_changes = $phase ? {
            undef   => [ 'rm job/phase' ],
            default => [ "set job/phase ${phase}" ],
        }

        $recurrence_changes = $recurrence ? {
            undef   => [ 'rm job/recurrence' ],
            default => [ "set job/recurrence ${recurrence}" ],
        }

        $at_changes = $at ? {
            undef   => [ 'rm job/at' ],
            default => [ "set job/at ${at}" ],
        }

        # Create empty conf file, otherwise augeas doesn't work properly
        exec { "yabt_create_job_${full_conf}":
            command => "/bin/echo -n > ${full_conf}",
            creates => $full_conf,
            require => File[$yabt::config::jobs_dir],
        }

        # Apply configuration
        augeas { $name:
            lens    => 'Puppet.lns',
            incl    => $full_conf,
            changes => concat([
                "set job/name ${name}",
                "set job/type ${type}",
            ], $enabled_changes, $phase_changes, $recurrence_changes, $at_changes, $changes),
            require => Exec["yabt_create_job_${full_conf}"],
        }
    }
    else {
        file { $full_conf:
            ensure => 'absent',
        }
    }
}


# Status notification job
define yabt::status_notification_job (
    $complete = 0,
    $phase = 9,
    $recurrence = 'weekly',
    $at = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $complete_changes = $complete ? {
        undef   => [ 'rm status-notification/complete' ],
        default => [ "set status-notification/complete ${complete}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        type       => 'yabt\\StatusNotificationJob',
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => $complete_changes,
    }
}


# Private class
# Generic dump job
define yabt::dump_job (
    $type,
    $section,
    $changes,
    $retention_period = 14,
    $full_period = 7,
    $incremental = undef,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $incremental_val = $incremental ? {
        false => 0,
        true  => 1,
        undef => undef,
    }
    
    $incremental_val_not_undef = $incremental_val != undef
    
    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        type       => $type,
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => concat([
            "set ${section}/retention_period ${retention_period}",
            "set ${section}/full_period ${full_period}",
        ],
        $dump_location ? {
            undef   => [ "rm ${section}/location" ],
            default => [ "set ${section}/location ${dump_location}" ],
        },
        $incremental_val_not_undef ? {
            true    => [ "set ${section}/incremental ${incremental_val}" ],
            default => [ "rm ${section}/incremental" ],
        },
        $changes),
    }
}


# Directory dump job
define yabt::dir_dump_job(
    $path,

    $retention_period = 14,
    $full_period = 7,
    $incremental = undef,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $ensure = 'present',
) {
    yabt::dump_job { $name:
        ensure           => $ensure,
        enabled          => $enabled,
        type             => 'yabt\\DirDumpJob',
        phase            => $phase,
        recurrence       => $recurrence,
        at               => $at,
        retention_period => $retention_period,
        full_period      => $full_period,
        incremental      => $incremental,
        section          => 'dir',
        dump_location    => $dump_location,
        changes          => [
            "set dir/path ${path}",
        ],
    }
}


# '/etc' directory dump job
class yabt::etc_dir_dump_job(
    $retention_period = 14,
    $full_period = 7,
    $incremental = undef,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $ensure = 'present',
) {
    yabt::dir_dump_job { 'dir_etc':
        ensure           => $ensure,
        enabled          => $enabled,
        phase            => $phase,
        recurrence       => $recurrence,
        at               => $at,
        retention_period => $retention_period,
        full_period      => $full_period,
        incremental      => $incremental,
        path             => '/etc',
        dump_location    => $dump_location,
    }
}


# MySQL database dump job
# Can also dump a related storage directory
define yabt::mysqldb_dump_job(
    $user,
    $password,
    $dbname,
    $port = 3306,
    $hostname = 'localhost',
    $storage_dir = undef,

    $retention_period = 14,
    $full_period = 7,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $changes = $storage_dir ? {
        undef => [ 'rm mysqldb/storage_dir' ],
        default => [ "set mysqldb/storage_dir ${storage_dir}" ],
    }

    yabt::dump_job { $name: # mysqldb_${name}
        ensure           => $ensure,
        enabled          => $enabled,
        type             => 'yabt\\MysqlDbDumpJob',
        phase            => $phase,
        recurrence       => $recurrence,
        at               => $at,
        section          => 'mysqldb',
        retention_period => $retention_period,
        full_period      => $full_period,
        dump_location    => $dump_location,
        changes          => concat([
            "set mysqldb/user ${user}",
            "set mysqldb/password ${password}",
            "set mysqldb/hostname ${hostname}",
            "set mysqldb/dbname ${dbname}",
            "set mysqldb/port ${port}",
        ], $changes),
    }
}

# SVN repository dump job (basic)
define yabt::svn_dump_job (
    $parent_path,

    $retention_period = 14,
    $full_period = 7,
    $incremental = undef,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $ensure = 'present',
) {
    yabt::dump_job { $name:
        ensure           => $ensure,
        enabled          => $enabled,
        type             => 'yabt\\SvnDumpJob',
        phase            => $phase,
        recurrence       => $recurrence,
        at               => $at,
        section          => 'svn',
        retention_period => $retention_period,
        full_period      => $full_period,
        incremental      => $incremental,
        dump_location    => $dump_location,
        changes          => concat([
            "set svn/parent_path ${parent_path}",
        ], $changes),
    }
}


# SVN repository dump job (all repositories/subdirectories in a directory)
define yabt::svnrepositories_dump_job (
    $parent_path,

    $retention_period = 14,
    $full_period = 7,
    $incremental = undef,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $ensure = 'present',
) {
    yabt::svn_dump_job { $name:
        ensure           => $ensure,
        enabled          => $enabled,
        phase            => $phase,
        recurrence       => $recurrence,
        at               => $at,
        retention_period => $retention_period,
        full_period      => $full_period,
        incremental      => $incremental,
        dump_location    => $dump_location,
        parent_path      => $parent_path,
    }
}


# Rsync-based backup job
define yabt::rsync_job (
    $source,
    $destination = undef,

    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $changes = $destination ? {
        undef => [ 'rm rsync/destination' ],
        default => [ "set rsync/destination ${destination}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        type       => 'yabt\\RsyncJob',
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => concat([
            "set rsync/source ${source}",
            'rm rdiff-backup',
            'rm duplicity',
        ], $changes),
    }
}


# Duplicity based backup job
define yabt::duplicity_job (
    $source_dir,
    $passphrase,
    $target_url = undef,
    $retention_period = 180,
    $full_period = 60,

    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $changes = $target_url ? {
        undef => [ 'rm duplicity/target_url' ],
        default => [ "set duplicity/target_url ${target_url}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        type       => 'yabt\\DuplicityJob',
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => concat([
            "set duplicity/source_dir ${source_dir}",
            "set duplicity/passphrase ${passphrase}",
            "set duplicity/retention_period ${retention_period}",
            "set duplicity/full_period ${full_period}",
            'rm rdiff-backup',
            'rm rsync',
        ], $changes),
    }
}


# Rdiff-backup-based backup job
# Note that rdiff-backup must be installed both on client and server
define yabt::rdiffbackup_job (
    $source,
    $destination = undef,
    $retention_period = '1Y',

    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $changes = $destination ? {
        undef => [ 'rm rdiff-backup/destination' ],
        default => [ "set rdiff-backup/destination ${destination}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        type       => 'yabt\\RdiffBackupJob',
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => concat([
            "set rdiff-backup/source ${source}",
            "set rdiff-backup/retention_period ${retention_period}",
            'rm duplicity',
            'rm rsync',
        ], $changes),
    }
}
