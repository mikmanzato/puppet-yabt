# Private class

# Manages installation
class yabt::install (
    $version = 'latest',
    $ensure  = 'present',
) {
    class { 'yabt::install::github':
        version => $version,
        ensure  => $ensure,
    }
}
