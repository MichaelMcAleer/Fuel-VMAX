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
class vmax_plugin::params {

  # Set environment specific variables for packages & services
  case $::osfamily {
    'Debian': {
      $pywbem_package_name = 'python-pywbem'
      $iscsi_package_name = 'open-iscsi'
      $iscsi_service_name = 'open-iscsi'
    }
    'RedHat': {
      $pywbem_package_name = 'pywbem'
      $iscsi_package_name = 'iscsi-initiator-utils' # or scsi-target-utils.x86_64
      $iscsi_service_name = false
    }
    default: {
      fail("${::osfamily} is currently unsuported, Debian and Redhat are the only supported platforms")
    }
  }
}
