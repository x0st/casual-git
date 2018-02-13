#!/bin/bash
echo "$(awk 'NR==1,/pick/{sub(/pick/, "edit")} 1' ${1})" > ${1}