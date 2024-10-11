#!/usr/bin/bash

find . -name "*.graphml" -type f -exec xmllint --output '{}' --format '{}' \;