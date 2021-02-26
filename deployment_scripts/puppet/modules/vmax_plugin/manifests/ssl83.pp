#
#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class vmax_plugin::ssl83 {

  # Capture values from Fuel UI for VMAX config
  $ecom_info = hiera('fuel-vmax-v8')

  # Fields captured from Fuel UI VMAX settings
  $ecom_host                  = $ecom_info['vmax_ecom_host_address']
  $vmax_backened_type_iscsi   = $ecom_info['vmax_backened_type_iscsi']
  $vmax_backened_type_fc      = $ecom_info['vmax_backened_type_fc']

  case $::osfamily {
    # If the environment is using RedHat based OS...
    'RedHat': {
      $cert_directory = '/etc/pki/ca-trust/extracted/pem'
      $ca_command = 'yum update ca-certificates'
    }
    # If the environment is using Debian based OS...
    'Debian': {
      $cert_directory = '/usr/share/ca-certificates'
      $ca_command = 'update-ca-certificates'
    }
    # If the environment is using an OS other than Debian/RedHat
    default: {
      fail("${::osfamily} is currently unsuported, Debian and Redhat are the only supported platforms")
    }
  }

  # Get certs from ECOM server
  exec { "get_ecom_server_ca_certs":
    path    => ['/usr/bin', '/bin'],
    command => "openssl s_client -showcerts -connect ${ecom_host}:5989 </dev/null 2>/dev/null|openssl x509 -outform PEM >${ecom_host}.pem",
    returns => [0],
    user    => 'root',
    before  => Exec['copy_pem_to_system']
  }

  # Copy the pem file to the system certificate directory
  exec { "copy_pem_to_system":
    path    => ['/usr/bin', '/bin'],
    command => "cp ${ecom_host}.pem ${cert_directory}/${ecom_host}.crt",
    returns => [0],
    user    => 'root',
    before  => Exec['update_ca_certificates'],
    require => Exec['get_ecom_server_ca_certs']
  }

  # Update system CA certificates
  exec { "update_ca_certificates":
    path    => ['/usr/bin', '/bin'],
    command => $ca_command,
    returns => [0],
    user    => 'root',
    before  => ini_setting['conf_driver_ssl_cert_verify'],
    require => Exec['copy_pem_to_system'],
  }

  # If iSCSI is in use in environment, add SSL info to iSCSI backend block in cinder.conf
  if $vmax_backened_type_iscsi == 'true' {
    # Line: driver_ssl_cert_verify = False
    ini_setting { "iscsi_conf_driver_ssl_cert_verify":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'driver_ssl_cert_verify',
      value   => 'False',
      before  => ini_setting['iscsi_conf_driver_use_ssl'],
      require => Exec['update_ca_certificates'],
    }
    # LINE: driver_use_ssl = True
    ini_setting { "iscsi_conf_driver_use_ssl":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'driver_use_ssl',
      value   => 'True',
      before  => ini_setting['conf_driver_ssl_cert_path'],
      require => ini_setting['conf_driver_ssl_cert_verify'],
    }
    # LINE: driver_ssl_cert_path = /opt/stack/${ecom_host}.pem
    ini_setting { "iscsi_conf_driver_ssl_cert_path":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'driver_ssl_cert_path',
      value   => "${cert_directory}/${ecom_host}.pem",
      require => ini_setting['iscsi_conf_driver_use_ssl'],
    }
  }

  # If FC is in use in environment, add SSL info to FC backend block in cinder.conf
  if $vmax_backened_type_fc == 'true' {
    # LINE: driver_ssl_cert_verify = False
    ini_setting { "fc_conf_driver_ssl_cert_verify":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_FC',
      setting => 'driver_ssl_cert_verify',
      value   => 'False',
      before  => ini_setting['conf_driver_use_ssl'],
      require => Exec['update_ca_certificates'],
    }
    # LINE: driver_use_ssl = True
    ini_setting { "fc_conf_driver_use_ssl":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_FC',
      setting => 'driver_use_ssl',
      value   => 'True',
      before  => ini_setting['fc_conf_driver_ssl_cert_path'],
      require => ini_setting['fc_conf_driver_ssl_cert_verify'],
    }
    # LINE: driver_ssl_cert_path = /opt/stack/${ecom_host}.pem
    ini_setting { "fc_conf_driver_ssl_cert_path":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_FC',
      setting => 'driver_ssl_cert_path',
      value   => "${cert_directory}/${ecom_host}.pem",
      require => ini_setting['fc_conf_driver_use_ssl'],
    }
  }
}