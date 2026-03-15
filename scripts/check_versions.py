# AI-GENERATED
"""Verifies installed versions of hardware simulation tools.

This module checks the system path for Icarus Verilog and GTKWave. It
specifically accounts for Homebrew tap conflicts on macOS by using
fully-qualified formula names.
"""

import platform
import subprocess


def check_command_output(command):
    """Executes a command and captures its output.

    Args:
        command: A list containing the command and its arguments.

    Returns:
        The standard output of the command if successful, or an error 
        description if the command is missing or fails.
    """
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return f'Not found or error executing: {command[0]}'


def main():
    """Checks environment health and tool versions.

    Queries iverilog and gtkwave versions. On macOS, it uses brew to 
    verify the specific yanjiew1 tap installation to avoid naming 
    conflicts with other taps.
    """
    system_platform = platform.system().lower()
    print(f'Checking environment on {system_platform.capitalize()}...')

    # Icarus Verilog check.
    print('--- Icarus Verilog Version ---')
    print(check_command_output(['iverilog', '-V']))

    # GTKWave check.
    print('\n--- GTKWave Version ---')
    print(check_command_output(['gtkwave', '--version']))

    # Homebrew specific check for macOS.
    if system_platform == 'darwin':
        print('\n--- Homebrew Tap Check ---')
        # Use fully-qualified name to avoid the 'multiple taps' error.
        brew_check = subprocess.run(
            ['brew', 'info', 'yanjiew1/gtkwave/gtkwave'],
            capture_output=True, text=True
        )
        if brew_check.returncode == 0:
            print('GTKWave (yanjiew1) is correctly recognized by brew.')
        else:
            print('Warning: brew could not find yanjiew1/gtkwave/gtkwave.')


if __name__ == '__main__':
    main()