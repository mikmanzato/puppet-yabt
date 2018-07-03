# Status notification job
define yabt::status_notification_job (
    $complete = 0,
    $phase = 9,
    $recurrence = 'weekly',
    $at = undef,
    $enabled = true,
    $pre_cmd = undef,
    $post_cmd = undef,
    $ensure = 'present',
) {
    $complete_changes = $complete ? {
        undef   => [ 'rm status-notification/complete' ],
        default => [ "set status-notification/complete ${complete}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        pre_cmd    => $pre_cmd,
        post_cmd   => $post_cmd,
        type       => 'yabt\\StatusNotificationJob',
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => $complete_changes,
    }
}
