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
class vmax_plugin::xml_config {

  # Capture values from Fuel UI for VMAX config
  $xml_settings = hiera('fuel-vmax-v8')

  # Set required values from UI
  $vmax_hardware_version        = $xml_settings['vmax_hardware_version']
  $vmax_v3_type                 = $xml_settings['vmax_v3_type']
  $vmax_ecom_host_address       = $xml_settings['vmax_ecom_host_address']
  $vmax_ecom_ip_address         = $xml_settings['vmax_ecom_ip_address']
  $vmax_ecom_port               = $xml_settings['vmax_ecom_port']
  $vmax_ecom_username           = $xml_settings['vmax_ecom_username']
  $vmax_ecom_password           = $xml_settings['vmax_ecom_password']
  $vmax_array_id                = $xml_settings['vmax_array_id']
  $vmax_port_group              = $xml_settings['vmax_port_group']
  $vmax_v2_pool                 = $xml_settings['vmax_v2_pool']
  $vmax_v3_srp                  = $xml_settings['vmax_v3_srp']
  $vmax_v2_fast_policy          = $xml_settings['vmax_v2_fast_policy']
  $vmax_v3_slo                  = $xml_settings['vmax_v3_slo']

  # Set SE version specific variables
  if $vmax_hardware_version == 'vmax_v2' {
    $server_addr = $xml_settings['vmax_ecom_ip_address']
  }
  elsif $vmax_hardware_version == 'vmax_v3_hybrid' {
    $server_addr = $xml_settings['vmax_ecom_host_address']
    $vmax_v3_workload = $xml_settings['vmax_v3_workload']
  }
  elsif $vmax_hardware_version == 'vmax_v3_afa' {
    $server_addr = $xml_settings['vmax_ecom_host_address']
    $vmax_v3_workload = 'diamond'
  }

  # Split user input using comma delimiter, add values to array
  $port_array = split($vmax_port_group, ",")
  # Remove any whitespace from array values
  $stripped_array = strip($port_array)
  # Prefix value with tab characters and opening PortGroup XML tag
  $xml_array_prefix = prefix($stripped_array, "\t\t<PortGroup>")
  # Suffix value with newline character and closing PortGroup XML tag
  $xml_array_suffix = suffix($xml_array_prefix, "</PortGroup>\n")
  # Join all array values to make one continuous string
  $final_port_list = join($xml_array_suffix)
  # Remove the very last newline character from the string
  $xml_ready_port_list = chop($final_port_list)

  # If the environment is using VMAX2 construct the following XML...
  if $vmax_hardware_version == 'vmax_v2' {
    $cinder_vmax_config_xml =
      "<?xml version='1.0' encoding='UTF-8'?>
      <EMC>
      \t<EcomServerIp>${server_addr}</EcomServerIp>
      \t<EcomServerPort>${vmax_ecom_port}</EcomServerPort>
      \t<EcomUserName>${vmax_ecom_username}</EcomUserName>
      \t<EcomPassword>${vmax_ecom_password}</EcomPassword>
      \t<PortGroups>
      ${final_port_list}
      \t<Array>${vmax_array_id}</Array>
      \t<Pool>${vmax_v2_pool}</Pool>
      \t<FastPolicy>${vmax_v2_fast_policy}</FastPolicy>
      </EMC>\n"
  }

    # If the environment is using VMAX3 construct the following XML...
  elsif $vmax_hardware_version != 'vmax_v2' {
    $cinder_vmax_config_xml =
      "<?xml version='1.0' encoding='UTF-8'?>
      <EMC>
      \t<EcomServerIp>${server_addr}</EcomServerIp>
      \t<EcomServerPort>${vmax_ecom_port}</EcomServerPort>
      \t<EcomUserName>${vmax_ecom_username}</EcomUserName>
      \t<EcomPassword>${vmax_ecom_password}</EcomPassword>
      \t<PortGroups>
      ${final_port_list}
      \t</PortGroups>
      \t<Array>${vmax_array_id}</Array>
      \t<Pool>${vmax_v3_srp}</Pool>
      \t<SLO>${vmax_v3_slo}</SLO>
      \t<Workload>${vmax_v3_workload}</Workload>
      </EMC>\n"
  }
}