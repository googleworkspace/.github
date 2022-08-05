#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

repos=$(gh repo list googleworkspace \
    --no-archived \
    --visibility public \
    --source \
    --json name --jq '.[] .name' \
    -L 1000 | sort)

FILE=README.md
ORG=https://github.com/googleworkspace

# delete all lines starting after matching string
sed -n '/WORKFLOWS_INSERT/q;p' <$FILE >$FILE.tmp
mv $FILE.tmp $FILE

echo "Writing to $FILE"
{
    echo ""
    echo "<!-- WORKFLOWS_INSERT -->"
    echo "<!-- textlint-disable -->"
    echo "## Workflows"
    echo ""
    echo "| Repository | Test | Lint | Release |"
    echo "| --- | --- | --- | --- |"
}  >>$FILE

badge() {
    local repo=$1
    local workflow=$2
    echo "[![${repo} ${workflow}](${ORG}/${repo}/actions/workflows/${workflow}.yml/badge.svg?branch=main)](${ORG}/${repo}/actions/workflows/${workflow}.yml)"
}

for repo in $repos; do
    echo "| [${repo}](${ORG}/${repo}) | $(badge "${repo}" test) | $(badge "${repo}" lint) | $(badge "${repo}" release-please) |" >>$FILE
done
echo "<!-- textlint-enable -->" >>$FILE
