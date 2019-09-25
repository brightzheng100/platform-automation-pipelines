#! /bin/bash

set -euo pipefail

show_usage () {
    pipeline_name=$1
    cat << EOF
Usage: $(basename "$0") -t <Concourse target name> -p <PCF platform code> -n <pipeline name> [OPTION]

  -t <Concourse target name>          the logged in fly's target name
  -p <PCF platform code>              the PCF platform code the pipeline is created for, e.g. prod
  -n <pipeline name>                  the pipeline name

  -o <ops files seperated by comma>   the ops files, seperated by comma, e.g. file1.yml,file2.yml
  -h                                  display this help and exit

Examples:
  $(basename "$0") -t prod -p prod -n ${pipeline_name}
  $(basename "$0") -t prod -p prod -n ${pipeline_name} -o ops-file1.yml
  $(basename "$0") -t prod -p prod -n ${pipeline_name} -o ops-file1.yml,ops-file1.yml

EOF
}

opt_t=''    # fly target name
opt_p=''    # PCF platform code
opt_n=''    # pipeline name
opt_o=()    # ops files seperated by comma

suggested_pipeline_name="upgrade-opsman"

while getopts "t:p:n:s:o:h" opt; do
    case $opt in
        t)  opt_t=$OPTARG
            ;;
        p)  opt_p=$OPTARG
            ;;
        n)  opt_n=$OPTARG
            ;;
        o)  opt_o+=("$OPTARG")
            ;;
        h)
            show_usage "$suggested_pipeline_name"
            exit 0
            ;;
        ?)
            show_usage "$suggested_pipeline_name" >&2
            exit 1
            ;;
    esac
done

if [ -z "$opt_t" ] || [ -z "$opt_p" ] || [ -z "$opt_n" ]; then
    echo -e "ERROR: please specify Concourse's target name with '-t', PCF platform code with '-p', and pipeline name with '-n' \n"
    show_usage "$suggested_pipeline_name"
    exit 0
fi

config_file="cat"
if [[ ${#opt_o[@]} > 0 ]]; then
    if ! [ -x "$(command -v yaml-patch)" ]; then
        echo "yaml-patch tool is required for ops-files. Please get it from https://github.com/krishicks/yaml-patch/releases"
        exit 1
    fi

    config_file=" yaml-patch "
    for ops_file in "${opt_o[@]}"; do
        config_file+=" -o ${ops_file} "
    done
fi

fly -t $opt_t set-pipeline -p $opt_n \
    -c <( cat pipelines/${suggested_pipeline_name}.yml | $config_file ) \
    -l vars-${opt_p}/vars-common.yml
