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
class vmax_plugin::controller {

  # Include common settings for iSCSI & PyWbem services/packages
  include vmax_plugin::common
  # Include settings for cinder XML file configuration
  include vmax_plugin::xml_config

  # Capture values from Fuel UI for VMAX config
  $plugin_settings = hiera('fuel-vmax-v9')

  # Define services
  $services = ['cinder-volume', 'cinder-api', 'cinder-scheduler']

  # Set required values from UI
  $vmax_hardware_version        = $plugin_settings['vmax_hardware_version']
  $vmax_backened_type_iscsi     = $plugin_settings['vmax_backened_type_iscsi']
  $vmax_backened_type_fc        = $plugin_settings['vmax_backened_type_fc']
  $vmax_iscsi_target            = $plugin_settings['vmax_iscsi_ip_address']
  $vmax_iscsi_volume_type       = $plugin_settings['vmax_iscsi_volume_type']
  $vmax_iscsi_backend_name      = $plugin_settings['vmax_issi_backend_name']
  $vmax_fc_volume_type          = $plugin_settings['vmax_fc_volume_type']
  $vmax_fc_backend_name         = $plugin_settings['vmax_fc_backend_name']


  # Set enabled backend values for cinder.conf
  if $vmax_backened_type_iscsi == 'true' and $vmax_backened_type_fc == 'true' {
    $enabled_backends = 'CONF_GROUP_ISCSI, CONF_GROUP_FC'
  }
  elsif $vmax_backened_type_iscsi == 'true' and $vmax_backened_type_fc == 'false' {
    $enabled_backends = 'CONF_GROUP_ISCSI'
  }
  elsif $vmax_backened_type_iscsi == 'false' and $vmax_backened_type_fc == 'true' {
    $enabled_backends = 'CONF_GROUP_FC'
  }

  file { 'driver_transfer':
    path    => '/usr/lib/python2.7/dist-packages/cinder/volume/drivers/emc',
    source  => 'puppet:///modules/vmax_plugin',
    mode    => '644',
    owner   => 'root',
    group   => 'root',
    replace => true,
    recurse => true,
    ensure  => present,
  }

  # /etc/cinder/cinder.conf add
  # LINE: enabled_backends = ${volume_type}
  ini_setting { "cinder_conf_enabled_backends":
    ensure  => present,
    path    => '/etc/cinder/cinder.conf',
    section => 'DEFAULT',
    setting => 'enabled_backends',
    value   => $enabled_backends,
  }

  # If the backend type is iSCSI add following to cinder.conf...
  if $vmax_backened_type_iscsi == 'true' {
    # LINE: volume_driver = cinder.volume.drivers.emc.emc_vmax_iscsi.${volume_driver}
    ini_setting { "iscsi_target_ip":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'iscsi_ip_address',
      value   => $vmax_iscsi_target,
    }
    # LINE: volume_driver = cinder.volume.drivers.emc.emc_vmax_iscsi.${volume_driver}
    ini_setting { "cinder_conf_volume_driver":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'volume_driver',
      value   => "cinder.volume.drivers.emc.emc_vmax_iscsi.EMCVMAXISCSIDriver",
    }
    # LINE: cinder_emc_config_file = /etc/cinder/cinder_emc_config_${vmax_backend}.xml
    ini_setting { "cinder_conf_config_xml":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'cinder_emc_config_file',
      value   => "/etc/cinder/cinder_emc_config_CONF_GROUP_ISCSI.xml",
    }
    # LINE: volume_backend_name=$vmax_iscsi_backend_name
    ini_setting { "cinder_conf_volume_backend_name":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_ISCSI',
      setting => 'volume_backend_name',
      value   => $vmax_iscsi_backend_name,
    }
    # Create config xml file
    file { "cinder_emc_config_CONF_GROUP_ISCSI.xml":
      ensure  => present,
      path    => "/etc/cinder/cinder_emc_config_CONF_GROUP_ISCSI.xml",
      content => $::vmax_plugin::xml_config::cinder_vmax_config_xml,
      mode    => '0644',
      owner   => root,
      group   => root,
      replace => true,
    }
    # Create cinder volume type, COMMAND: cinder type-create ${vmax_iscsi_volume_type}
    exec { "Create Cinder volume type \'${vmax_iscsi_volume_type}\'":
      command => "bash -c 'source /root/openrc; cinder type-create ${vmax_iscsi_volume_type}'",
      path    => ['/usr/bin', '/bin'],
      unless  => "bash -c 'source /root/openrc; cinder type-list |grep -q \" ${vmax_iscsi_volume_type} \"'",
    }
    # Associate cinder type-key and set volume backend name
    # COMMAND: cinder type-key ${vmax_iscsi_volume_type}
    # COMMAND: set volume_backend_name=${vmax_iscsi_backend_name}
    exec { "Create Cinder volume type extra specs for \'${vmax_iscsi_volume_type}\'":
      command => "bash -c 'source /root/openrc; cinder type-key ${vmax_iscsi_volume_type} set volume_backend_name=${vmax_iscsi_backend_name}'",
      path    => ['/usr/bin', '/bin'],
      onlyif  => "bash -c 'source /root/openrc; cinder type-list |grep -q \" ${vmax_iscsi_volume_type} \"'",
    }
  }

  # If the backend type is FC add following to cinder.conf...
  if $vmax_backened_type_fc == 'true' {
    # LINE: volume_driver = cinder.volume.drivers.emc.emc_vmax_iscsi.${volume_driver}
    ini_setting { "cinder_conf_volume_driver":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_FC',
      setting => 'volume_driver',
      value   => "cinder.volume.drivers.emc.emc_vmax_fc.EMCVMAXFCDriver",
    }
    # LINE: cinder_emc_config_file = /etc/cinder/cinder_emc_config_${vmax_backend}.xml
    ini_setting { "cinder_conf_config_xml":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_FC',
      setting => 'cinder_emc_config_file',
      value   => "/etc/cinder/cinder_emc_config_CONF_GROUP_FC.xml",
    }
    # Line: volume_backend_name = $vmax_fc_backend_name
    ini_setting { "cinder_conf_volume_backend_name":
      ensure  => present,
      path    => '/etc/cinder/cinder.conf',
      section => 'CONF_GROUP_FC',
      setting => 'volume_backend_name',
      value   => $vmax_fc_backend_name,
    }
    # Create config xml file
    file { "cinder_emc_config_CONF_GROUP_FC.xml":
      ensure  => present,
      path    => "/etc/cinder/cinder_emc_config_CONF_GROUP_FC.xml",
      content => $::vmax_plugin::xml_config::cinder_vmax_config_xml,
      mode    => '0644',
      owner   => root,
      group   => root,
      replace => true,
    }
    # Create cinder volume type, COMMAND: cinder type-create ${vmax_iscsi_volume_type}
    exec { "Create Cinder volume type \'${vmax_fc_volume_type}\'":
      command => "bash -c 'source /root/openrc; cinder type-create ${vmax_fc_volume_type}'",
      path    => ['/usr/bin', '/bin'],
      unless  => "bash -c 'source /root/openrc; cinder type-list |grep -q \" ${vmax_fc_volume_type} \"'",
    }
    # Associate cinder type-key and set volume backend name
    # COMMAND: cinder type-key ${vmax_fc_volume_type}
    # COMMAND: set volume_backend_name=${vmax_fc_backend_name}
    exec { "Create Cinder volume type extra specs for \'${vmax_fc_volume_type}\'":
      command => "bash -c 'source /root/openrc; cinder type-key ${vmax_fc_volume_type} set volume_backend_name=${vmax_fc_backend_name}'",
      path    => ['/usr/bin', '/bin'],
      onlyif  => "bash -c 'source /root/openrc; cinder type-list |grep -q \" ${vmax_fc_volume_type} \"'",
    }
  }

  # If the environment is using VMAX 3, update config for SSL support
  if $vmax_hardware_version != 'vmax_v2' {
    include vmax_plugin::ssl83
  }

  # Ensure all services are runnning
  service { $services:
    restart => true,
    ensure  => running,
  }
}