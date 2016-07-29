# == Class: confluence::post_install
#
# Do the post-install configuration of Confluence.
#
class confluence::post_install(
) {

  file {"${confluence::homedir}/confluence.cfg.xml":
    owner   => $confluence::user,
    group   => $confluence::group,
    ensure  => present,
    content => template('confluence/confluence.cfg.xml.erb'),
    mode    => '0755',
    require => Class['confluence::install'],
    notify  => Class['confluence::service'],
  }

}
