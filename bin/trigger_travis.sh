# Please see https://github.com/mernst/plume-lib/blob/master/bin/trigger-travis.sh for reference

if [ "$#" -lt 3 ] || [ "$#" -ge 7 ]; then
  echo "Wrong number of arguments $# to trigger-travis.sh; run like:"
  echo " trigger-travis.sh [--pro] [--branch BRANCH] GITHUBID GITHUBPROJECT TRAVIS_ACCESS_TOKEN [MESSAGE]" >&2
  exit 1
fi

if [ "$1" = "--pro" ] ; then
  TRAVIS_URL=travis-ci.com
  shift
else
  TRAVIS_URL=travis-ci.org
fi

if [ "$1" = "--branch" ] ; then
  shift
  BRANCH="$1"
  shift
else
  BRANCH=master
fi

USER=$1
REPO=$2
TOKEN=$3
if [ $# -eq 4 ] ; then
    MESSAGE=",\"message\": \"$4\""
elif [ -n "$TRAVIS_REPO_SLUG" ] ; then
    MESSAGE=",\"message\": \"Triggered by upstream build of $TRAVIS_REPO_SLUG commit "`git rev-parse --short HEAD`"\""
else
    MESSAGE=""
fi
## For debugging:
# echo "USER=$USER"
# echo "REPO=$REPO"
# echo "TOKEN=$TOKEN"
# echo "MESSAGE=$MESSAGE"

body="{
\"request\": {
  \"branch\":\"$BRANCH\"
  $MESSAGE,
  \"config\": {
    \"merge_mode\": [\"deep_merge\"],
	\"script\": [\"bin/install_package_dependencies.sh\",
	             \"bin/check_package.sh\",
	             \"bin/run_test.sh\",
	             \"bin/install_package.sh\",
	             \"bin/run_model.sh\"]
  }
  }
}"

# It does not work to put / in place of %2F in the URL below.  I'm not sure why.
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token ${TOKEN}" \
  -d "$body" \
  https://api.${TRAVIS_URL}/repo/${USER}%2F${REPO}/requests \
 | tee /tmp/travis-request-output.$$.txt

if grep -q '"@type": "error"' /tmp/travis-request-output.$$.txt; then
    exit 1
fi
if grep -q 'access denied' /tmp/travis-request-output.$$.txt; then
    exit 1
fi
