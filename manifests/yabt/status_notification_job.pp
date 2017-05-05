# Status notification job
define yabt::status_notification_job (
    $complete = 0,
    $phase = 9,
    $recurrence = 'weekly',
    $at = undef,
    $enabled = true,
    $ensure = 'present',
) {
    $complete_changes = $complete ? {
        undef   => [ 'rm status-notification/complete' ],
        default => [ "set status-notification/complete ${complete}" ],
    }

    yabt::job { $name:
        ensure     => $ensure,
        enabled    => $enabled,
        type       => 'yabt\\StatusNotificationJob',
        phase      => $phase,
        recurrence => $recurrence,
        at         => $at,
        changes    => $complete_changes,
    }
}
