#!/bin/bash

# Test runner for EasySettings.
# Used to test both python 2 and python 3 in one run.
# -Christopher Welborn 01-20-2019
appname="EasySettings Test Runner"
appversion="0.0.1"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
# appdir="${apppath%/*}"

GREEN=${GREEN:-$'\e[1;32m'}
RED=${RED:=$'\e[1;31m'}
NOCOLOR=${NOCOLOR:-$'\e[0m'}

function echo_err {
    # Echo to stderr.
    printf "%b" "$RED"
    echo -e "$@" 1>&2
    printf "%b" "$NOCOLOR"
}

function echo_status {
    printf "%b" "$GREEN"
    echo -e "$@"
    printf "%b" "$NOCOLOR"
}

function fail {
    # Print a message to stderr and exit with an error status code.
    echo_err "$@"
    exit 1
}

function fail_usage {
    # Print a usage failure message, and exit with an error status code.
    print_usage "$@"
    exit 1
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Test runner for EasySettings.

    Usage:
        $appscript -h | -v
        $appscript (-2 | -3) [-n | -u]

    Options:
        -2,--python2   : Run for python 2 only.
        -3,--python3   : Run for python 3 only.
        -h,--help      : Show this message.
        -n,--nose      : Use nosetests.
        -u,--unittest  : Use unittest module.
        -v,--version   : Show $appname version and exit.
    "
}

declare -a nonflags
do_2=1
do_3=1
do_nose=0
do_unittest=0
do_runhelp=0

for arg; do
    case "$arg" in
        "-h" | "--help")
            print_usage ""
            exit 0
            ;;
        "-H" | "--runhelp")
            do_runhelp=1
            ;;
        "-n" | "--nose")
            do_nose=1
            ;;
        "-u" | "--unittest")
            do_unittest=1
            ;;
        "-v" | "--version")
            echo -e "$appname v. $appversion\n"
            exit 0
            ;;
        "-2" | "--python2")
            do_3=0
            ;;
        "-3" | "--python3")
            do_2=0
            ;;
        -*)
            fail_usage "Unknown flag argument: $arg"
            ;;
        *)
            nonflags+=("$arg")
    esac
done

((do_2 || do_3)) || fail_usage "-2 and -3 are useless when used together."

errs=0
declare -a testargs
noseargs=("--exe" "-v")
testcmd2='nosetests-2.7'
testcmd3='nosetests-3.4'
if ((do_nose)); then
    echo 'Using nosetests...'
    testargs=("${noseargs[@]}")
elif ((do_unittest)); then
    echo 'Using unittest...'
    testcmd2='python2.7'
    testcmd3='python3.6'
    testargs=("-m" "unittest" "discover" "-v")
elif hash green2 green3 &>/dev/null; then
    echo 'Using green...'
    testcmd2='green2'
    testcmd3='green3'
    testargs=("-vv")
else
    echo 'Using nosetests because green was not found...'
    testargs=("${noseargs[@]}")
fi

if ((do_runhelp)); then
    testargs+=("--help")
    ((do_3)) && {
        $testcmd3 "${testargs[@]}"
        exit
    }
    $testcmd2 "${testargs[@]}"
    exit
fi

testargs+=("${nonflags[@]}")
((do_2)) && {
    echo -e "\nRunning $testcmd2 ${testargs[*]}"
    if $testcmd2 "${testargs[@]}"; then
       echo_status "\nPython 2 tests passed."
    else
        let errs+=1
        echo_err "Python 2 tests failed."
    fi
}
((do_3)) && {
    echo -e "\nRunning $testcmd3 ${testargs[*]}"
    if $testcmd3 "${testargs[@]}"; then
        echo_status "\nPython 3 tests passed."
    else
        let errs+=1
        echo_err "\nPython 3 tests failed."
    fi
}

((errs)) && {
    plural="runs"
    ((errs == 1)) && plural="run"
    echo_err "$errs test $plural failed!"
    exit 1
}

echo_status "\nAll tests passed."
exit 0
