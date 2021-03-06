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
    $pre_cmd = undef,
    $post_cmd = undef,
    $ensure = 'present',
) {
    yabt::dir_dump_job { 'dir_etc':
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
        path             => '/etc',
        dump_location    => $dump_location,
    }
}
