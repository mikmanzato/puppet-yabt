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
    $pre_cmd = undef,
    $post_cmd = undef,
    $ensure = 'present',
) {
    $changes = $target_url ? {
        undef => [ 'rm duplicity/target_url' ],
        default => [ "set duplicity/target_url ${target_url}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        pre_cmd    => $pre_cmd,
        post_cmd   => $post_cmd,
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
