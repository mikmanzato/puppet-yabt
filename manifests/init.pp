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
