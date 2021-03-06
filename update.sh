#!/usr/bin/env bash
set -Eeuo pipefail

ql_versions=( "$@" )
if [ ${#ql_versions[@]} -eq 0 ]; then
	ql_versions=( */ )
fi
ql_versions=( "${ql_versions[@]%/}" )

# see http://stackoverflow.com/a/2705678/433558
sed_escape_lhs() {
	echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
}
sed_escape_rhs() {
	echo "$@" | sed -e 's/[\/&]/\\&/g' | sed -e ':a;N;$!ba;s/\n/\\n/g'
}

declare -A python_alpine_versions
python_alpine_versions=( ["3.6.4"]="3.4;3.6;3.7" ["3.5.5"]="3.4")

#for i in "${pages[@]}"
#do
#        arr=(${i//;/ })
#        site=${arr[0]}
#        language=${arr[1]}
#        protocol=${arr[2]}
#done

#python_versions=(3.6.4 3.5.5)
#alpine_versions=(3.6 3.7)

for ql_version in "${ql_versions[@]}"; do
    for python_version in ${!python_alpine_versions[@]}; do
        echo "Generating Dockerfiles for QuantLib version ${ql_version} and Python version ${python_version}."
        template=alpine
        echo "Generating templates for ${template}"
        python_lib_path=python${python_version:0:3}
	alpine_versions=(${python_alpine_versions[$python_version]//;/ })

        for alpine_version in ${alpine_versions[@]}; do
	    dockerfile_path=$ql_version/python$python_version/$template/$alpine_version 
	    mkdir -p $dockerfile_path
	    ql_builder_tag=$ql_version-$template$alpine_version
            python_tag=$python_version-$template$alpine_version

	    sed -r \
	        -e 's!%%QL_BUILDER_TAG%%!'"$ql_builder_tag"'!g' \
		-e 's!%%PYTHON_TAG%%!'"$python_tag"'!g' \
	        -e 's!%%QUANTLIB_SWIG_VERSION%%!'"$ql_version"'!g' \
		-e 's!%%PYTHON_LIB_PATH%%!'"$python_lib_path"'!g' \
                "Dockerfile-${template}.template" > "$dockerfile_path/Dockerfile"
	    echo "Generated ${dockerfile_path}/Dockerfile"
        done
    done
done
