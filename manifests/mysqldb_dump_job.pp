# MySQL database dump job
# Can also dump a related storage directory
define yabt::mysqldb_dump_job(
    $user,
    $password,
    $dbname,
    $port = 3306,
    $hostname = 'localhost',
    $storage_dir = undef,

    $retention_period = 14,
    $full_period = 7,
    $phase = 5,
    $recurrence = 'daily',
    $at = undef,
    $dump_location = undef,
    $enabled = true,
    $pre_cmd = undef,
    $post_cmd = undef,
    $ensure = 'present',
) {
    $changes = $storage_dir ? {
        undef => [ 'rm mysqldb/storage_dir' ],
        default => [ "set mysqldb/storage_dir ${storage_dir}" ],
    }

    yabt::dump_job { $name: # mysqldb_${name}
        ensure           => $ensure,
        enabled          => $enabled,
        pre_cmd          => $pre_cmd,
        post_cmd         => $post_cmd,
        type             => 'yabt\\MysqlDbDumpJob',
        phase            => $phase,
        recurrence       => $recurrence,
        at               => $at,
        section          => 'mysqldb',
        retention_period => $retention_period,
        full_period      => $full_period,
        dump_location    => $dump_location,
        changes          => concat([
            "set mysqldb/user ${user}",
            "set mysqldb/password ${password}",
            "set mysqldb/hostname ${hostname}",
            "set mysqldb/dbname ${dbname}",
            "set mysqldb/port ${port}",
        ], $changes),
    }
}
