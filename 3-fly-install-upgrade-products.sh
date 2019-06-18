#! /bin/bash

concourse_target="$1" && shift
platform_code="$1" && shift
pipeline_name="$1" && shift
ops_files=($@)

if [ -z "$concourse_target" ] || [ -z "$platform_code" ] || [ -z "$pipeline_name" ]; then
    echo -e "USAGE: $0 <CONCOURSE_TARGET> <PLATFORM_CODE> <PIPELINE_NAME> <OPS_FILES, optional> \n
For example: \n
$0 dev dev install-upgrade-products \n
Or if we have some ops files: \n
$0 dev dev install-upgrade-products ops-files/a.yml ops-files/b.yml
"
    exit 1
fi

if ! [ -x "$(command -v ytt)" ]; then
    echo "ytt is required. Please get it from https://github.com/k14s/ytt/releases"
    exit 1
fi

config_file="cat"
if [[ ${#ops_files[@]} > 0 ]]; then
    config_file=" yaml-patch "
    for ops_file in "${ops_files[@]}"; do
        config_file+=" -o ${ops_file} "
    done
fi

fly -t $concourse_target set-pipeline -p $pipeline_name \
    -c <( ytt template \
            -f pipelines/install-upgrade-products.yml \
            -f templates/functions.lib.yml \
            -f templates/groups.lib.yml \
            -f templates/resource-types.lib.yml \
            -f templates/resources-install-upgrade.lib.yml \
            -f templates/jobs-install-upgrade.lib.yml  \
            -f vars-$platform_code/vars-products.yml  \
            | $config_file \
        ) \
    -l vars-$platform_code/vars-common.yml
