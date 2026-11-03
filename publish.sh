#V=$(grep -p ^version build.gradle* | sed "s/.*['\"]\(.*\)['\"].*/v\1/")
V=v1
git tag -d $V || true
git push origin :refs/tags/$V || true
git tag $V
git push origin $V
