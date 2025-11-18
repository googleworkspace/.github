gh search repos --owner googleworkspace --archived=false --json name --limit 200 -q '.[].name' | while read -r repo; do
  gh pr list --repo "googleworkspace/$repo" \
    --search "is:pr is:open \"chore: Synced file(s) with googleworkspace/.github\"" \
    --json url --jq '.[].url' | while read -r pr_url; do
      echo "Processing $pr_url..."
      gh pr review "$pr_url" --approve </dev/null
      gh pr merge "$pr_url" --admin --squash --subject "$(gh pr view "$pr_url" --json title --jq .title)" </dev/null
  done
done