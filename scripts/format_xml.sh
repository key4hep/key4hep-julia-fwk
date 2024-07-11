#!/usr/bin/bash

find . -name "*.graphml" -type f -not -path "./deps/*" -exec xmllint --output '{}' --format '{}' \;