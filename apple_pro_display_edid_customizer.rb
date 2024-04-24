#!/usr/bin/env ruby

# Apple Pro Display XDR Custom EDID and Modeline Configuration Script
# Author: Webster Avosa

# Requirements:
# - Ensure you have 'edid-decode', 'cvt', and 'xrandr' utilities installed.
# - Connect your Apple Pro Display XDR to your NVIDIA 4090 via the Huawei DP+2xUSB-A to USB-C cable.

# Usage:
# 1. Run this script with root privileges (sudo).
# 2. It will read the existing EDID, analyze it, modify it, create a custom modeline, and update Xorg configuration.
# 3. Restart Xorg or reboot your system for changes to take effect.

require 'fileutils'

# Constants
DEFAULT_EDID_PATH = '/sys/class/drm/card0-DP-1/edid' # Default path to the existing EDID
XORG_CONFIG_DIR = '/etc/X11/xorg.conf.d'
XORG_CONFIG_FILE = '/etc/X11/xorg.conf'

def find_edid_file
  possible_paths = [DEFAULT_EDID_PATH, '/sys/class/drm/card1-DP-1/edid'] # Add more paths here if needed
  existing_path = possible_paths.find { |path| File.exist?(path) }
  raise 'EDID file not found in default locations. Please provide the path manually.' unless existing_path
  existing_path
end

def analyze_edid(edid_file)
  decoded = `edid-decode #{edid_file}`
  puts "EDID Analysis:\n#{decoded}"
  decoded
end

def modify_edid(edid_file)
  # Example modification: Assumes existing EDID is hex-encoded
  existing_edid_hex = File.read(edid_file).unpack1('H*')
  modified_edid = existing_edid_hex.gsub(/(?<=01ffffff...)(.{32})/, '000102030405060708090a0b0c0d0e0f') # Placeholder modification
  modified_edid
end

def write_custom_edid(modified_edid)
  custom_edid_file = File.join(File.dirname(DEFAULT_EDID_PATH), 'custom_edid.bin')
  File.write(custom_edid_file, [modified_edid].pack('H*'), mode: 'wb')
  custom_edid_file
end

def create_modeline
  # Generate a modeline for 6K resolution using cvt
  modeline = `cvt 5120 2880 60`.split("\n").last.strip
  puts "Generated Modeline:\n#{modeline}"
  modeline
end

def xorg_config_path
  # Check if xorg.conf exists
  if File.exist?(XORG_CONFIG_FILE)
    XORG_CONFIG_FILE
  else
    # Ensure the configuration directory exists
    FileUtils.mkdir_p(XORG_CONFIG_DIR) unless Dir.exist?(XORG_CONFIG_DIR)
    File.join(XORG_CONFIG_DIR, '99-custom-edid.conf')
  end
end

def update_xorg_config(custom_edid_file, modeline)
  config_path = xorg_config_path
  FileUtils.cp(config_path, "#{config_path}.bak") if File.exist?(config_path) # Backup the original or current config

  File.open(config_path, 'a') do |file|
    file.puts "\nSection \"Monitor\""
    file.puts "    Identifier \"AppleProDisplayXDR\""
    file.puts "    Option \"CustomEDID\" \"#{custom_edid_file}\""
    file.puts "    Modeline #{modeline}"
    file.puts "    Option \"PreferredMode\" \"#{modeline.split(' ').first}\""
    file.puts "EndSection\n"
  end
  puts "Updated Xorg configuration at #{config_path}"
end

# Main
if Process.uid.zero?
  begin
    edid_file = find_edid_file
    analyze_edid(edid_file)
    modified_edid = modify_edid(edid_file)
    custom_edid_file = write_custom_edid(modified_edid)
    modeline = create_modeline
    update_xorg_config(custom_edid_file, modeline)
    puts 'Custom configuration applied! Please restart Xorg or reboot your system.'
  rescue => e
    puts "Error: #{e.message}"
  end
else
  puts 'Please run this script with root privileges (sudo).'
end
