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
