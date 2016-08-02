# == Class: confluence::params
#
# Defines default values for confluence module
#
class confluence::params (
  # Enable post-install configuration of Confluence.
  $enable_post_install = false,
  $dbtype = 'postgresql',
  $setupstep = 'complete',
  $serverid,
  $buildnumber = 5781,
  $licensemessage,
  $dbhost = 'localhost',
  $dbport = 5432,
  $dbname,
  $dbuser,
  $dbpassword,
) {

  case $::osfamily {
    /RedHat/: {
      if $::operatingsystemmajrelease == '7' {
        $service_file_location = '/usr/lib/systemd/system/confluence.service'
        $service_file_template = 'confluence/confluence.service.erb'
        $service_lockfile      = '/var/lock/subsys/confluence'
      } elsif $::operatingsystemmajrelease == '6' {
        $service_file_location = '/etc/init.d/confluence'
        $service_file_template = 'confluence/confluence.initscript.erb'
        $service_lockfile      = '/var/lock/subsys/confluence'
      } else {
        fail("Only osfamily ${::osfamily} 6 and 7 and supported")
      }
    }
    /Debian/: {
      $service_file_location   = '/etc/init.d/confluence'
      $service_file_template   = 'confluence/confluence.initscript.erb'
      $service_lockfile        = '/var/lock/confluence'
    }
    default: { fail('Only osfamily Debian and Redhat are supported') }
  }
}
