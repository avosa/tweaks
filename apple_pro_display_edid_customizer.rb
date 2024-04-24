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

# Path constants for EDID and Xorg configuration files.
EDID_PATHS = ['/sys/class/drm/card0-DP-1/edid', '/sys/class/drm/card1-DP-1/edid'] # Add more paths here if needed
XORG_CONFIG_DIR = '/etc/X11/xorg.conf.d'
XORG_CONFIG_FILE = '/etc/X11/xorg.conf'

class DisplayConfiguration
  def initialize
    # Ensure the script is run with root privileges
    raise 'Please run this script with root privileges (sudo).' unless Process.uid.zero?
    @edid_file = find_edid_file
    @custom_edid_file = File.join(File.dirname(EDID_PATHS.first), 'custom_edid.bin')
  end

  def configure_display
    # High-level steps to configure the display
    apply_edid_modifications
    create_and_apply_modeline
    update_xorg_configuration
    puts 'Custom configuration applied! Please restart Xorg or reboot your system.'
  rescue StandardError => e
    puts "Error: #{e.message}"
  end

  private

  def find_edid_file
    # Locate the existing EDID file from possible paths
    EDID_PATHS.find { |path| File.exist?(path) } || raise('EDID file not found. Please check the connection or specify the path.')
  end

  def apply_edid_modifications
    # Decode and modify the EDID to suit custom requirements
    decoded = `edid-decode #{@edid_file}`
    puts "EDID Analysis:\n#{decoded}"

    # Example modification for demonstration purposes
    modified_edid = File.read(@edid_file).unpack1('H*').gsub(/(?<=01ffffff...)(.{32})/, '000102030405060708090a0b0c0d0e0f')
    File.write(@custom_edid_file, [modified_edid].pack('H*'), mode: 'wb')
  end

  def create_and_apply_modeline
    # Generate a modeline for a 6K resolution using cvt
    modeline = `cvt 5120 2880 60`.split("\n").last.strip
    puts "Generated Modeline:\n#{modeline}"
    @modeline = modeline
  end

  def update_xorg_configuration
    # Update or create Xorg configuration file to use the modified EDID and new modeline
    config_path = determine_xorg_config_path
    FileUtils.cp(config_path, "#{config_path}.bak") if File.exist?(config_path)

    File.open(config_path, 'a') do |file|
      file.puts "\nSection \"Monitor\""
      file.puts "    Identifier \"AppleProDisplayXDR\""
      file.puts "    Option \"CustomEDID\" \"#{@custom_edid_file}\""
      file.puts "    Modeline #{@modeline}"
      file.puts "    Option \"PreferredMode\" \"#{@modeline.split(' ').first}\""
      file.puts "EndSection\n"
    end
    puts "Updated Xorg configuration at #{config_path}"
  end

  def determine_xorg_config_path
    # Determine the path for the Xorg configuration file
    return XORG_CONFIG_FILE if File.exist?(XORG_CONFIG_FILE)
    FileUtils.mkdir_p(XORG_CONFIG_DIR) unless Dir.exist?(XORG_CONFIG_DIR)
    File.join(XORG_CONFIG_DIR, '99-custom-edid.conf')
  end
end

DisplayConfiguration.new.configure_display

