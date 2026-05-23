"""A script to convert media files to base64 encoded text files.

This script processes media files (images, audio, video) and converts them to base64 encoded
text format. It can handle individual files or recursively process entire directories.
The encoded data is saved to new files with the original extension plus '.b64'.

Supported file types:
    - Images: .png, .jpg, .jpeg
    - Audio: .mp3
    - Video: .mp4

Functions:
    convert_to_base64(input_file): Converts a media file to base64 encoded text
    main(): Handles user input and initiates file processing

Usage:
    Run the script and enter a file or directory path when prompted.
    For directories, all supported media files will be processed recursively.
    
    Examples:
        - Single file: "path/to/video.mp4"
        - Current directory (recursive): "."
        - Specific directory: "path/to/media/folder"

Output:
    Creates new files with '.b64' extension: 'your_file.mp4.b64'
"""

import base64
import os
from pathlib import Path

def convert_to_base64(input_file):
    # Read file in binary mode
    with open(input_file, 'rb') as file:
        # Convert to base64
        encoded = base64.b64encode(file.read())
        
    # Create output filename by appending .b64 while keeping original extension
    output_file = input_file.with_suffix(input_file.suffix + '.b64')
    
    # Write base64 string to text file
    with open(output_file, 'w') as file:
        file.write(encoded.decode('utf-8'))
        
    print(f"Converted {input_file} to base64 -> {output_file}")

def main():
    # Get directory path from user
    while True:
        dir_path = input("Enter the directory path containing media files: ").strip()
        path = Path(dir_path)
        
        if path.exists():
            break
        print("Invalid directory path. Please try again.")
    
    # Supported extensions
    supported_extensions = {'.jpg', '.jpeg', '.mp3', '.mp4', '.md', '.png'}
    
    # Recursively process all files in specified directory and subdirectories
    for file in path.rglob('*'):
        if file.is_file() and file.suffix.lower() in supported_extensions:
            convert_to_base64(file)

if __name__ == '__main__':
    main()