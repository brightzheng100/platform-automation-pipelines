#! /bin/bash

concourse_target="$1" && shift
platform_code="$1" && shift
pipeline_name="$1" && shift
ops_files=($@)

if [ -z "$concourse_target" ] || [ -z "$platform_code" ] || [ -z "$pipeline_name" ]; then
    echo -e "USAGE: $0 <CONCOURSE_TARGET> <PLATFORM_CODE> <PIPELINE_NAME> <OPS_FILES, optional> \n
For example: \n
$0 dev dev upgrade-opsman \n
Or if we have some ops files: \n
$0 dev dev upgrade-opsman ops-files/a.yml ops-files/b.yml
"
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
    -c <( cat pipelines/upgrade-opsman.yml | $config_file ) \
    -l vars-${platform_code}/vars-common.yml
