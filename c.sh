#!/usr/bin/env fish

# Define the output file name
set OUTPUT "combined.txt"

# Overwrite the output file if it exists
echo "" >$OUTPUT

# Use 'fd' to find all .swift files recursively
# Exclude hidden directories and certain paths if needed
# Example: Exclude 'Tests' and 'ThirdParty' directories
set swift_files (fd --extension swift --exclude Tests --exclude ThirdParty)

# Check if any .swift files were found
if test (count $swift_files) -eq 0
    echo "No .swift files found in the current directory and its subdirectories."
    exit 0
end

# Iterate over each .swift file
for file in $swift_files
    # Append the file path as a Swift comment
    echo "// $file" >>$OUTPUT

    # Append the contents of the .swift file using 'bat'
    bat "$file" >>$OUTPUT

    # Add a newline for separation
    echo "" >>$OUTPUT
end

echo "All .swift files have been concatenated into $OUTPUT"
