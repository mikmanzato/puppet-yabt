# Private class

# Manages installation
class yabt::install (
    $version = 'latest',
    $ensure  = 'present',
) {
    class { 'yabt::install::github':
        ensure  => $ensure,
        version => $version,
    }
}
