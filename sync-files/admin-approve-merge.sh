#!/bin/bash
# Copyright 2026 Google LLC
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

set -euo pipefail

EXPECTED_TITLE="chore: Synced file(s) with googleworkspace/.github"
EXPECTED_AUTHOR="googleworkspace-bot"
EXPECTED_OWNER="googleworkspace"
EXPECTED_LABEL="sync-files"
EXPECTED_BRANCH_PREFIX="sync-files-"

gh search repos --owner "$EXPECTED_OWNER" --archived=false --json name --limit 200 -q '.[].name' | while read -r repo; do
  gh pr list --repo "$EXPECTED_OWNER/$repo" \
    --state open \
    --author "$EXPECTED_AUTHOR" \
    --label "$EXPECTED_LABEL" \
    --json url,title,author,isCrossRepository,headRepositoryOwner,headRefName,labels \
    --jq '.[] | select(
      .author.login == "'"$EXPECTED_AUTHOR"'" and
      .isCrossRepository == false and
      .headRepositoryOwner.login == "'"$EXPECTED_OWNER"'" and
      (.headRefName | startswith("'"$EXPECTED_BRANCH_PREFIX"'")) and
      .title == "'"$EXPECTED_TITLE"'" and
      any(.labels[]; .name == "'"$EXPECTED_LABEL"'")
    ) | .url' | while read -r pr_url; do
      [ -z "$pr_url" ] && continue

      # Re-verify PR metadata via gh pr view before taking privileged action
      verified_title="$(gh pr view "$pr_url" \
        --json title,state,author,isCrossRepository,headRepositoryOwner,headRefName,labels \
        --jq 'select(
          .state == "OPEN" and
          .author.login == "'"$EXPECTED_AUTHOR"'" and
          .isCrossRepository == false and
          .headRepositoryOwner.login == "'"$EXPECTED_OWNER"'" and
          (.headRefName | startswith("'"$EXPECTED_BRANCH_PREFIX"'")) and
          .title == "'"$EXPECTED_TITLE"'" and
          any(.labels[]; .name == "'"$EXPECTED_LABEL"'")
        ) | .title')"

      if [ "$verified_title" != "$EXPECTED_TITLE" ]; then
        echo "Skipping unverified PR $pr_url" >&2
        continue
      fi

      echo "Processing $pr_url..."
      gh pr review "$pr_url" --approve </dev/null
      gh pr merge "$pr_url" --admin --squash --subject "$verified_title" </dev/null
  done
done
