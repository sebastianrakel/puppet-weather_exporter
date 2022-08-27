# @summary Manage weather_exporter service
class weather_exporter (
  String[1] $user = 'weather_exporter',
  String[1] $group = 'weather_exporter',
  Boolean $manage_user = true,
  Boolean $manage_group = true,
  Boolean $manage_service = true,
  String[1] $service_name = 'weather-exporter',
  String[1] $version = '0.3.1',
  String[1] $base_url = 'https://github.com/niklasdoerfler/weather-exporter/releases/download/',
  String[1] $archive_bin_path = "/opt/${service_name}-${version}/${service_name}",
  Hash $config = {},
  Boolean $manage_config = true,
){
  $download_url = "${base_url}/v${version}/weather-exporter-v${version}-linux-amd64.tar.gz"

  file { "/opt/${service_name}-${version}":
    ensure => directory,
    owner  => 'root',
  }

  archive { "/tmp/${name}-${version}.tar.gz":
    ensure          => present,
    extract         => true,
    extract_path    => "/opt/${service_name}-${version}",
    source          => $download_url,
    checksum_verify => false,
    creates         => $archive_bin_path,
    cleanup         => true,
    before          => File[$archive_bin_path],
  }

  file { $archive_bin_path:
    owner => 'root',
    group => 0, # 0 instead of root because OS X uses "wheel".
    mode  => '0555',
  }

  if $manage_user {
    user { $user:
      ensure => present,
      system => true,
    }

    if $manage_group {
      group { $group:
        ensure => present,
        system => true,
      }
    }
  }

  if $manage_config {
    file { '/etc/weather_exporter':
      ensure => directory,
      owner  => $user,
      group  => $group,
    }

    file { '/etc/weather_exporter/config.yaml':
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0600',
      content => $config.to_yaml,
    }
  }

  if $manage_service {
    systemd::unit_file { "${service_name}.service":
      content    => epp('weather_exporter/weather_exporter.service.epp', {
        user     => $user,
        group    => $group,
        bin_path => $archive_bin_path,
      }),
    }

    service { $service_name:
      ensure => running,
      enable => true,
    }
  }
}
