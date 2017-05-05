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
