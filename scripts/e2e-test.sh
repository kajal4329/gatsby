#!/bin/bash
set -e # bail on errors

SRC_PATH=$1
CUSTOM_COMMAND="${2:-yarn test}"
eval GATSBY_PATH=${CIRCLE_WORKING_DIRECTORY:-../..}
TMP_LOCATION=$(mktemp -d);

mkdir -p $TMP_LOCATION/$SRC_PATH
TMP_TEST_LOCATION=$TMP_LOCATION/$SRC_PATH

mkdir -p $TMP_LOCATION/scripts/
mkdir -p $TMP_TEST_LOCATION

# cypress docker does not support sudo and does not need it, but the default node executor does
command -v gatsby-dev || (command -v sudo && sudo npm install -g gatsby-dev-cli@next) || npm install -g gatsby-dev-cli@next

echo "Copy $SRC_PATH into $TMP_LOCATION to isolate test"
cp -Rv $SRC_PATH/. $TMP_TEST_LOCATION
cp -Rv $GATSBY_PATH/scripts/. $TMP_LOCATION/scripts/

# setting up child integration test link to gatsby packages
cd "$TMP_TEST_LOCATION"

# gatsby-dev --set-path-to-repo "$GATSBY_PATH"
# gatsby-dev --force-install --scan-once  # Do not copy files, only install through npm, like our users would

yarn add gatsby@circleci gatsby-cypress@circleci gatsby-plugin-image@circleci gatsby-plugin-less@circleci gatsby-plugin-manifest@circleci gatsby-plugin-offline@circleci gatsby-plugin-react-helmet@circleci gatsby-plugin-sass@circleci gatsby-plugin-sharp@circleci gatsby-plugin-stylus@circleci gatsby-source-filesystem@circleci --registry=http://loclahost:4873

if test -f "./node_modules/.bin/gatsby"; then
  chmod +x ./node_modules/.bin/gatsby # this is sometimes necessary to ensure executable
  echo "Gatsby bin chmoded"
else
  echo "Gatsby bin doesn't exist. Skipping chmod."
fi

sh -c "$CUSTOM_COMMAND"
echo "e2e test run succeeded"
