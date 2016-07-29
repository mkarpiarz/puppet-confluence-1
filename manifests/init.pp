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

  # Enable/disable colleting of custom facts within module.
  $enable_custom_facts = true,

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
  $enable_post_install = false,
  $dbtype = 'postgresql',
  $setupstep = 'complete',
  $serverid = undef,
  $buildnumber = 5781,
  $licensemessage = undef,
  $dbhost = 'localhost',
  $dbport = 5432,
  $dbname = 'confluence',
  $dbuser = 'confluence',
  $dbpassword = undef,
) {

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

  if ($enable_custom_facts) {
    # if custom facts are enabled, use appriopriate manifest
    class { '::confluence::facts': before => Class['::confluence::install'] }
  }
  else {
    # only get parameters (which confluence::facts is inheriting)
    class { '::confluence::params': before => Class['::confluence::install'] }
  }

  class { '::confluence::install': before => Class['::confluence::config'] }
  class { '::confluence::config': notify => Class['::confluence::service'] }
  class { '::confluence::service': }

  if ($enable_sso) {
    class { '::confluence::sso':
    }
  }

  if ($enable_post_install) {
    if $setupstep != 'complete' and $setupstep != 'setupdata-start' {
      fail('setupstep must be either "complete" or "setupdata-start"')
    }

    if $serverid == undef {
      fail('You need to specify a value for serverid')
    }

    if $licensemessage == undef {
      fail('You need to specify a value for licensemessage')
    }

    if $dbpassword == undef {
      fail('You need to specify a value for dbpassword')
    }

    if $dbtype == 'postgresql' {
      $dbdriver = 'org.postgresql.Driver'
      $dbprotocol = 'postgresql'
      $dbdialect = 'net.sf.hibernate.dialect.PostgreSQLDialect'

      class { '::confluence::post_install': }
    }
    else {
      fail('Unsupported type of database.')
    }
  }
}
