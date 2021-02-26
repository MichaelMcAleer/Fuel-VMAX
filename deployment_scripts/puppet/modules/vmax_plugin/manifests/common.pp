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
class vmax_plugin::common {

  include vmax_plugin::params

  # Ensure iSCSI package is installed
  package { $::vmax_plugin::params::iscsi_package_name:
    ensure => 'installed'
  }

  # Ensure PyWbem package is installed
  package { $::vmax_plugin::params::pywbem_package_name:
    ensure => 'installed'
  }

  # NOTE: Possibly switch this out and perform task with sed command to remove dos artifacts
  #
  # Ensure dos2unix package is installed
  # package { $::vmax_plugin::params::dos2unix_package_name:
  #   ensure => 'installed'
  # }

  # If the environment is Debian, check iSCSI service is running after restarting
  case $::osfamily {
    'Debian': {
      service { $::vmax_plugin::params::iscsi_service_name:
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
        require    => Package[$::vmax_plugin::params::iscsi_package_name],
      }
    }
  }
}
