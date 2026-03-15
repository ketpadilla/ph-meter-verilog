# AI-GENERATED
"""Installs hardware simulation tools across different operating systems.

This module detects the host operating system and utilizes the appropriate
package manager (Homebrew, APT, or Chocolatey) to install Icarus Verilog
and GTKWave for Verilog development.
"""

import platform
import subprocess


def install_system_dependencies():
    """Installs Icarus Verilog and GTKWave.

    Detects the platform and executes system-level commands to ensure hardware
    simulation dependencies are met.

    Raises:
        subprocess.CalledProcessError: An error occurred while executing the
          package manager commands.
    """
    system_platform = platform.system().lower()

    if system_platform == 'darwin':
        print('Running on macOS. Installing Icarus Verilog and GTKWave...')
        try:
            # Install or upgrade Icarus Verilog.
            subprocess.check_call(['brew', 'install', 'icarus-verilog'])

            # Install GTKWave formula specifically from the yanjiew1 tap.
            # Using the full name prevents conflicts with other taps or casks.
            print('Installing GTKWave via yanjiew1 tap...')
            subprocess.check_call(['brew', 'install', '--formula', 
                                   'yanjiew1/gtkwave/gtkwave'])

            print('Icarus Verilog and GTKWave are ready on macOS.')
        except subprocess.CalledProcessError as e:
            print(f'Error: Command failed with return code {e.returncode}')
            print('If Homebrew reported a linking conflict, '
                  'run: brew link --overwrite python@3.14')

    elif system_platform == 'linux':
        print('Running on Linux. Installing Icarus Verilog and GTKWave...')
        try:
            subprocess.check_call(['sudo', 'apt-get', 'update'])
            subprocess.check_call(['sudo', 'apt-get', 'install', '-y', 
                                   'iverilog', 'gtkwave'])
            print('Success: Icarus Verilog and GTKWave installed.')
        except subprocess.CalledProcessError:
            print('Error: Failed to install dependencies on Linux.')

    elif system_platform == 'windows':
        print('Running on Windows. Installing Icarus Verilog and GTKWave...')
        try:
            subprocess.check_call(['choco', 'install', 'iverilog', 
                                   'gtkwave', '-y'])
            print('Success: Icarus Verilog and GTKWave installed.')
        except subprocess.CalledProcessError:
            print('Error: Failed to install dependencies on Windows. '
                  'Ensure Chocolatey is installed.')
    else:
        print('Unsupported OS. Please install tools manually.')


def main():
    """Main execution entry point."""
    install_system_dependencies()


if __name__ == '__main__':
    main()