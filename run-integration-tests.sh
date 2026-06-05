#!/bin/bash
set -euo pipefail

# BoogieToStrata Integration Test Runner
echo "Running BoogieToStrata Integration Tests..."
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STRATA_CLI_DIR="${SCRIPT_DIR}/StrataCLI"

# -------------------------------------------------------
# Step 1: Clone and build strata-org/Strata-CLI to get
#         the 'strata' executable for verification tests.
# -------------------------------------------------------
if [ ! -d "${STRATA_CLI_DIR}" ]; then
    echo "Cloning strata-org/Strata-CLI..."
    git clone https://github.com/strata-org/Strata-CLI.git "${STRATA_CLI_DIR}"
fi

echo "Building Strata-CLI (lake build)..."
(cd "${STRATA_CLI_DIR}" && lake build)

STRATA_BIN="${STRATA_CLI_DIR}/.lake/build/bin/strata"
if [ ! -f "${STRATA_BIN}" ]; then
    echo "ERROR: strata binary not found at ${STRATA_BIN}" >&2
    exit 1
fi
echo "Strata verifier built successfully: ${STRATA_BIN}"

# Export so the integration tests can find it via STRATA_VERIFIER_PATH
export STRATA_VERIFIER_PATH="${STRATA_BIN}"

# -------------------------------------------------------
# Step 2: Build the main BoogieToStrata project
# -------------------------------------------------------
echo "Building BoogieToStrata project..."
dotnet build Source/BoogieToStrata.csproj

if [ $? -ne 0 ]; then
    echo "Failed to build main project. Exiting."
    exit 1
fi

LOG_ARGS=
#LOG_ARGS='--logger "console;verbosity=normal"'

# -------------------------------------------------------
# Step 3: Build and run the integration tests
# -------------------------------------------------------
echo "Building and running integration tests..."
dotnet test IntegrationTests/BoogieToStrata.IntegrationTests.csproj $LOG_ARGS

echo "Integration tests completed."
