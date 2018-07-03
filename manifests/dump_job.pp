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
    $pre_cmd = undef,
    $post_cmd = undef,
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
        pre_cmd    => $pre_cmd,
        post_cmd   => $post_cmd,
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
