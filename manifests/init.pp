# == Class: confluence
#
# Install confluence, See README.md for more.
#
class confluence (

  # JVM Settings
  $javahome     = undef,
  $jvm_xms      = '256m',
  $jvm_xmx      = '1024m',
  $jvm_permgen  = '256m',
  $java_opts    = '',

  # Confluence Settings
  $version      = '5.7.1',
  $product      = 'confluence',
  $format       = 'tar.gz',
  $installdir   = '/opt/confluence',
  $homedir      = '/home/confluence',
  $user         = 'confluence',
  $group        = 'confluence',
  $uid          = undef,
  $gid          = undef,
  $manage_user  = true,
  $shell        = '/bin/true',

  # Misc Settings
  $download_url = 'http://www.atlassian.com/software/confluence/downloads/binary',
  $checksum     = undef,

  # Choose whether to use puppet-staging, or puppet-archive
  $deploy_module = 'archive',

  # Manage confluence server
  $manage_service = true,

  # Tomcat Tunables
  # Should we use augeas to manage server.xml or a template file
  $manage_server_xml   = 'augeas',
  $tomcat_port         = 8090,
  $tomcat_max_threads  = 150,
  $tomcat_accept_count = 100,
  # Reverse https proxy setting for tomcat
  $tomcat_proxy = {},
  # Any additional tomcat params for server.xml
  $tomcat_extras = {},
  $context_path  = '',

  # Command to stop confluence in preparation to updgrade. This is configurable
  # incase the confluence service is managed outside of puppet. eg: using the
  # puppetlabs-corosync module: 'crm resource stop confluence && sleep 15'
  $stop_confluence = 'service confluence stop && sleep 15',

  # Enable confluence version fact for running instance
  # This required for upgrades
  $facts_ensure = 'present',

  # Enable SingleSignOn via Crowd

  $enable_sso = false,
  $application_name = 'crowd',
  $application_password = '1234',
  $application_login_url = 'https://crowd.example.com/console/',
  $crowd_server_url = 'https://crowd.example.com/services/',
  $crowd_base_url = 'https://crowd.example.com/',
  $session_isauthenticated = 'session.isauthenticated',
  $session_tokenkey = 'session.tokenkey',
  $session_validationinterval = 5,
  $session_lastvalidation = 'session.lastvalidation',

  # Enable post-install configuration of Confluence.
  $enable_post_install  = $confluence::params::enable_post_install,
  $dbtype               = $confluence::params::dbtype,
  $setupstep            = $confluence::params::setupstep,
  $serverid             = $confluence::params::serverid,
  $buildnumber          = $confluence::params::buildnumber,
  $licensemessage       = $confluence::params::licensemessage,
  $dbhost               = $confluence::params::dbhost,
  $dbport               = $confluence::params::dbport,
  $dbname               = $confluence::params::dbname,
  $dbuser               = $confluence::params::dbuser,
  $dbpassword           = $confluence::params::dbpassword,
) inherits confluence::params {

  validate_re($version, '^(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)(|[a-z])$')
  validate_absolute_path($installdir)
  validate_absolute_path($homedir)
  validate_bool($manage_user)

  validate_re($manage_server_xml, ['^augeas$', '^template$' ],
    'manage_server_xml must be "augeas" or "template"')
  validate_hash($tomcat_proxy)
  validate_hash($tomcat_extras)

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  $webappdir    = "${installdir}/atlassian-${product}-${version}"

  if $::confluence_version and $::confluence_version != 'unknown' {
    # If the running version of CONFLUENCE is less than the expected version of CONFLUENCE
    # Shut it down in preparation for upgrade.
    if versioncmp($version, $::confluence_version) > 0 {
      notify { 'Attempting to upgrade CONFLUENCE': }
      exec { $stop_confluence: before => Class['::confluence::install'] }
    }
  }

  if $javahome == undef {
    fail('You need to specify a value for javahome')
  }

  class { '::confluence::install': before => Class['::confluence::config'] }
  class { '::confluence::config': notify => Class['::confluence::service'] }
  class { '::confluence::service': }

  if ($enable_sso) {
    class { '::confluence::sso':
    }
  }

  validate_bool($enable_post_install)
  if ($enable_post_install) {
    validate_re($setupstep, ['^complete$', '^setupdata-start$' ],
      'setupstep must be either "complete" or "setupdata-start"')
    # server ID should be in the form XXXX-XXXX-XXXX-XXXX
    validate_re($serverid, '^([0-9A-Z]{4}\-){3}[0-9A-Z]{4}$')
    validate_re($licensemessage, '^[a-zA-Z0-9\/+=-]{501}$')
    if $dbuser == undef {
      fail('You need to specify a value for dbuser')
    }
    if $dbpassword == undef {
      fail('You need to specify a value for dbpassword')
    }
    if $dbname == undef {
      fail('You need to specify a value for dbname')
    }
    validate_integer($buildnumber)
    validate_integer($dbport)

    if $dbtype == 'postgresql' {
      $dbdriver = 'org.postgresql.Driver'
      $dbprotocol = 'postgresql'
      $dbdialect = 'net.sf.hibernate.dialect.PostgreSQLDialect'
    }
    else {
      fail('Unsupported type of database.')
    }
  }
  class { '::confluence::post_install': }
}
