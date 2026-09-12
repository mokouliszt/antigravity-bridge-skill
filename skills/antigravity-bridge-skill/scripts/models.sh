#!/usr/bin/env bash
# Lists models currently available through this subscription. Always call
# this instead of assuming a model name/list — Google ships new models
# under this CLI frequently and old names get retired.
set -euo pipefail
exec agy models
