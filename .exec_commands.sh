#!/bin/bash
# v1.0 all

#VDR command werden im Hintergrund ausgefuehrt

export EXECUTED_BY_VDR_BG=1
${@}
"${@}" >/dev/null 2>&1 &
exit 0
