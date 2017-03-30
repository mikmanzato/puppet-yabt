# Private class

# Class which manages download and installation of yabt
class yabt::install::github (
	$version = 'latest',
	$ensure  = 'present',
)
{
	include yabt::config

	$real_version = $version ? {
		default  => $version,
		'latest' => $yabt::config::latest_version,
	}
	
	$pkgname = "yabt-${real_version}"
	$package = "${pkgname}.tar.gz"
	$url = "${yabt::config::releases_url}${real_version}/${package}"

	$cmd_download = "/bin/rm -rf /tmp/$pkgname $package 2> /dev/null && /usr/bin/wget $url && /bin/tar zxf $package"
	$cmd_cleanup = "/bin/rm -rf /tmp/$pkgname $package 2> /dev/null"
	$cmd_install = "$cmd_download && /tmp/$pkgname/install.sh && $cmd_cleanup"
	$cmd_uninstall = "$cmd_download && /tmp/$pkgname/uninstall.sh && $cmd_cleanup"

	if $ensure == 'present' {
		exec { 'yabt_github_install':
			cwd     => "/tmp",
			command => $cmd_install,
			unless  => "/usr/bin/test -x /usr/local/bin/yabt && /usr/bin/test $(/usr/local/bin/yabt --version) = '$real_version'",
		}
	}
	else {
		exec { 'yabt_github_uninstall':
			cwd     => "/tmp",
			command => $cmd_uninstall,
			unless  => "/usr/bin/test ! -e /usr/local/bin/yabt",
		}
	}
}


class yabt::install (
	$version = 'latest',
	$ensure  = 'present',
) {
	class { 'yabt::install::github':
		version => $version,
		ensure  => $ensure,
	}
}
