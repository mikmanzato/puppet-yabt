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
    $pre_cmd = undef,
    $post_cmd = undef,
    $ensure = 'present',
) {
    $changes = $destination ? {
        undef => [ 'rm rdiff-backup/destination' ],
        default => [ "set rdiff-backup/destination ${destination}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        pre_cmd    => $pre_cmd,
        post_cmd   => $post_cmd,
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
