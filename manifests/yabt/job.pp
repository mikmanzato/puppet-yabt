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
