# == Class: confluence::post_install
#
# Do the post-install configuration of Confluence.
#
class confluence::post_install(
  $enabled = $confluence::enable_post_install
) {

  file {"${confluence::homedir}/confluence.cfg.xml":
    owner   => $confluence::user,
    group   => $confluence::group,
    mode    => '0644',
    ensure  => present,
    content => template('confluence/confluence.cfg.xml.erb'),
    replace => $enabled,
    require => Class['confluence::install'],
    notify  => Class['confluence::service'],
  }

}
