#!/usr/bin/env bash

#==========================================================================
#
#   Copyright Insight Software Consortium
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#          http://www.apache.org/licenses/LICENSE-2.0.txt
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#==========================================================================*/

# This script validates that all hash file names match their hash.


die() {
  echo "$@" 1>&2; exit 1
}

do_fixup=false
object_store=""
help=false

while [[ $# -gt 0 ]] ;
do
    opt="$1";
    shift;
    case "$opt" in
        "-h"|"--help")
           help=true;;
        "--fixup" )
           do_fixup=true;;
        *) if test "${object_store}" = "" ; then object_store=$opt; else echo >&2 "Invalid option: $opt"; exit 1; fi;;
   esac
done


if test "${object_store}" = "" || $help; then
  die "Usage: $0 <ExternalData_OBJECT_STORES path> [--fixup]"
fi

if ! type md5sum > /dev/null; then
  die "Please install the md5sum executable."
fi
if ! type sha512sum > /dev/null; then
  die "Please install the sha512sum executable."
fi

cd ${object_store}


verify_and_create() {
  algo=$1
  alt_algo=$2

  algo_upper=$(echo $algo | awk '{print toupper($0)}')
  alt_algo_upper=$(echo $alt_algo | awk '{print toupper($0)}')


  for object_file in ${object_store}/${algo_upper}/*; do
    echo "Data object ${object_file} ..."
    if test -z "${object_file}"; then
      die "Empty data object!"
      continue
    fi

    file_hash=$(basename "${object_file}")

    #alt_algo_file=${algo_file%\.*}.${alt_algo}

    echo "Verifying  ${object_file}..."
    object_file_hash=$(${algo}sum "${object_store}/${algo_upper}/${file_hash}" | cut -f 1 -d ' ')
    if test "${file_hash}" != "${object_file_hash}"; then
      die "${algo} for ${object_store}/${algo_upper}/${file_hash} does not equal hash of file (${object_file_hash})!"
    fi

    
    object_alt_algo_file_hash=$(${alt_algo}sum "${object_file}" | cut -f 1 -d ' ')
    echo "Checking for ${object_alt_algo_file_hash}..."
    if test ! -e "${object_store}/${alt_algo_upper}/${object_alt_algo_file_hash}"; then
        if $do_fixup; then
            echo "Creating ${alt_algo_upper}/${object_alt_algo_file_hash}."
            cp "${object_file}" "${object_store}/${alt_algo_upper}/${object_alt_algo_file_hash}"
        else
            die "${alt_algo} object file for ${object_store}/${algo_upper}/${file_hash} does not exist!"
        fi
    fi
  done || exit 1
}

verify_and_create md5 sha512
verify_and_create sha512 md5

echo ""
echo "Verification completed successfully."
echo ""
