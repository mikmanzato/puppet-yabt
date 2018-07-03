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
    $pre_cmd = undef,
    $post_cmd = undef,
    $ensure = 'present',
) {
    yabt::svn_dump_job { $name:
        ensure           => $ensure,
        enabled          => $enabled,
        pre_cmd          => $pre_cmd,
        post_cmd         => $post_cmd,
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
