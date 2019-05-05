#!/usr/bin/env bash

# Always failing assertion with a message.
#
# Example:
#     fail "It should have been but it wasn't to be"
function fail() {
    echo "$1"
    exit 1
}

# Asserts the non-existence of a file system path.
#
# Example:
#     assertPathNotExists foo/bar.txt
#
function assertPathNotExists() {
    if [[ -e "$TESTED/$1" ]]; then
        fail "Expected $1 to be missing but it exists."
    fi
}

# Asserts the existence of a file.
#
# Example:
#     assertFileExists foo/bar.txt
#
function assertFileExists() {
    if [[ ! -f "$TESTED/$1" ]]; then
        fail "Expected $1 to exist but it was not found."
    fi
}

function assertFileIsExecutable() {
    if [[ ! -x "$TESTED/$1" ]]; then
        fail "Expected $1 to be executable but it was not."
    fi
}

function assertFileIsNotExecutable() {
    if [[ -x "$TESTED/$1" ]]; then
        fail "Expected $1 to not be executable but it was."
    fi
}

# Asserts that the content of a file matches a given regular
# expression.
#
# Example:
#     assertFileRegex foo/bar.txt "^this line exists$"
#
function assertFileRegex() {
    if ! grep -q "$2" "$TESTED/$1"; then
        fail "Expected $1 to match $2 but it did not."
    fi
}

# Asserts that the content of a file does not match a given regular
# expression.
#
# Example:
#     assertFileNotRegex foo/bar.txt "^this line is missing$"
#
function assertFileNotRegex() {
    if grep -q "$2" "$TESTED/$1"; then
        fail "Expected $1 to not match $2 but it did."
    fi
}

# Asserts that the content of a file matches another file.
#
# Example:
#     assertFileCompare foo/bar.txt bar-expected.txt
function assertFileContent() {
    if ! cmp -s "$TESTED/$1" "$2"; then
        fail "Expected $1 to be same as $2 but were different:
$(diff -du --label actual --label expected "$TESTED/$1" "$2")"
    fi
}

# Asserts the existence of a directory.
#
# Example:
#     assertDirectoryExists foo/bar
#
function assertDirectoryExists() {
    if [[ ! -d "$TESTED/$1" ]]; then
        fail "Expected directory $1 to exist but it was not found."
    fi
}

# Asserts that a directory exists but is empty.
#
# Example:
#     assertDirectoryEmpty foo/bar
#
function assertDirectoryEmpty() {
    assertDirectoryExists "$1"

    local content
    content="$(find "$TESTED/$1" -mindepth 1 -maxdepth 1 -printf '%P\n')"

    if [[ $content ]]; then
        fail "Expected directory $1 to be empty but it contains
$content"
    fi
}

# Asserts that a directory exists and is not empty.
#
# Example:
#     assertDirectoryNotEmpty foo/bar
#
function assertDirectoryNotEmpty() {
    assertDirectoryExists "$1"

    if [[ ! $(find "$TESTED/$1" -mindepth 1 -maxdepth 1) ]]; then
        fail "Expected directory $1 to be not empty but it was."
    fi
}
