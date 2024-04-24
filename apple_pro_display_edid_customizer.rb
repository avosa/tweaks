#!/usr/bin/env ruby

# Apple Pro Display XDR Custom EDID Script
# Author: Webster Avosa

# Requirements:
# - Ensure you have the 'edid-decode' utility installed (usually available via package manager).
# - Connect your Apple Pro Display XDR to your NVIDIA 4090 via the Huawei DP+2xUSB-A to USB-C cable.

# Usage:
# 1. Run this script with root privileges (sudo).
# 2. It will read the existing EDID, modify it, and apply the custom EDID.
# 3. Restart Xorg or reboot your system for changes to take effect.

# Constants
DEFAULT_EDID_PATH = '/sys/class/drm/card0-DP-1/edid' # Default path to the existing EDID

def find_edid_file
  # Attempt to find the EDID file in common locations
  possible_paths = [
    DEFAULT_EDID_PATH,
    '/sys/class/drm/card1-DP-1/edid', # Additional common path
    # Add more paths here if needed
  ]

  existing_path = possible_paths.find { |path| File.exist?(path) }
  return existing_path if existing_path

  puts "EDID file not found in default locations."
  puts "Please provide the full path to the existing EDID file:"
  input_path = gets.chomp.strip
  input_path
end

def read_existing_edid(edid_file)
  # Read the existing EDID from the display
  existing_edid = `cat #{edid_file}`.strip
  puts "Existing EDID:\n#{existing_edid}"
  existing_edid
end

def modify_edid(existing_edid)
  # Modify the EDID (you can customize this part)
  # For simplicity, let's assume we're changing the resolution to 6K (5120x2880)
  modified_edid = existing_edid.gsub('3840x2160', '5120x2880')
  puts "Modified EDID:\n#{modified_edid}"
  modified_edid
end

def write_custom_edid(modified_edid)
  # Write the modified EDID to a binary file
  custom_edid_file = File.join(File.dirname(DEFAULT_EDID_PATH), 'custom_edid.bin')
  File.open(custom_edid_file, 'wb') { |f| f.write([modified_edid].pack('H*')) }
  puts "Custom EDID written to #{custom_edid_file}"
end

def apply_custom_edid
  # Apply the custom EDID
  `xrandr --newmode "CustomEDID" #{File.join(File.dirname(DEFAULT_EDID_PATH), 'custom_edid.bin')}`
  `xrandr --addmode DP-1 CustomEDID`
  `xrandr --output DP-1 --mode CustomEDID`
  puts 'Custom EDID applied!'
end

# Main
if Process.uid.zero?
  edid_file = find_edid_file
  existing_edid = read_existing_edid(edid_file)
  modified_edid = modify_edid(existing_edid)
  write_custom_edid(modified_edid)
  apply_custom_edid
else
  puts 'Please run this script with root privileges (sudo).'
end
