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
