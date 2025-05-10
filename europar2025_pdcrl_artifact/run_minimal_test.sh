#!/bin/bash

# --- Script Configuration ---
# These paths are relative to the location of this script, which should be
# in the main artifact directory (e.g., europar2025_pdcrl_artifact/)

# Directory where ParQR was cloned by setup_artifact.sh
PARQR_HOST_MAIN_DIR="pdcrl-parqr"
# Subdirectory within ParQR containing the Makefile, C++ sources for experiments
PARQR_CODE_SUBDIR="Dynamic-Task-Scheduling"

# Location of scripts and configs to be mounted into Docker
ARTIFACT_SCRIPTS_DIR_HOST="scripts_for_docker" # Contains master_experiment_runner.py
ARTIFACT_CONFIG_DIR_HOST="config"       # Contains minimal_test_config.json
MINIMAL_TEST_CONFIG_FILE="minimal_test_config.json"

# Docker container paths
DOCKER_WORKSPACE="/workspace"
DOCKER_PARQR_MOUNT_NAME="parqr_code" # Name for the mounted ParQR code inside workspace
DOCKER_ARTIFACT_SCRIPTS_MOUNT_NAME="artifact_scripts"
DOCKER_CONFIG_MOUNT_NAME="config"

# File storing the Docker image name (created by setup_artifact.sh)
DOCKER_IMAGE_NAME_FILE=".artifact_docker_image_name"

# --- Helper Functions ---
log_info() {
    echo "[MINIMAL_TEST INFO] $1"
}

log_error() {
    echo "[MINIMAL_TEST ERROR] $1" >&2
}

# --- Main Test Logic ---

log_info "Starting Minimal Test Script..."

# Step 1: Check for necessary files and directories from setup
log_info "Step 1: Verifying setup components..."
if [ ! -f "$DOCKER_IMAGE_NAME_FILE" ]; then
    log_error "Docker image name file ('$DOCKER_IMAGE_NAME_FILE') not found."
    log_error "Please run 'setup_artifact.sh' first."
    exit 1
fi
IMAGE_TO_USE=$(cat "$DOCKER_IMAGE_NAME_FILE")
if [ -z "$IMAGE_TO_USE" ]; then
    log_error "Docker image name is empty in '$DOCKER_IMAGE_NAME_FILE'."
    log_error "Please re-run 'setup_artifact.sh'."
    exit 1
fi
log_info "Using Docker image: $IMAGE_TO_USE"

if [ ! -d "$PARQR_HOST_MAIN_DIR/$PARQR_CODE_SUBDIR" ]; then
    log_error "ParQR code directory ('$PARQR_HOST_MAIN_DIR/$PARQR_CODE_SUBDIR') not found."
    log_error "Please ensure ParQR repository was cloned correctly by 'setup_artifact.sh'."
    exit 1
fi
log_info "ParQR code directory found: $PARQR_HOST_MAIN_DIR/$PARQR_CODE_SUBDIR"

if [ ! -d "$ARTIFACT_SCRIPTS_DIR_HOST" ] || [ ! -f "$ARTIFACT_SCRIPTS_DIR_HOST/master_experiment_runner.py" ]; then
    log_error "Artifact scripts directory ('$ARTIFACT_SCRIPTS_DIR_HOST') or master_experiment_runner.py not found."
    exit 1
fi
log_info "Artifact scripts directory found."

if [ ! -d "$ARTIFACT_CONFIG_DIR_HOST" ] || [ ! -f "$ARTIFACT_CONFIG_DIR_HOST/$MINIMAL_TEST_CONFIG_FILE" ]; then
    log_error "Artifact config directory ('$ARTIFACT_CONFIG_DIR_HOST') or $MINIMAL_TEST_CONFIG_FILE not found."
    exit 1
fi
log_info "Minimal test configuration file found."

# Step 2: Define paths for Docker volumes and commands
# Absolute path to the ParQR code subdirectory on the host (e.g., .../europar2025_pdcrl_artifact/pdcrl-parqr/Dynamic-Task-Scheduling)
HOST_PARQR_CODE_PATH_ABS="$(cd "$PARQR_HOST_MAIN_DIR/$PARQR_CODE_SUBDIR" && pwd)"
if [ -z "$HOST_PARQR_CODE_PATH_ABS" ]; then
    log_error "Could not resolve absolute path for '$PARQR_HOST_MAIN_DIR/$PARQR_CODE_SUBDIR'."
    exit 1
fi

# Absolute path to the artifact scripts directory on the host
HOST_ARTIFACT_SCRIPTS_PATH_ABS="$(cd "$ARTIFACT_SCRIPTS_DIR_HOST" && pwd)"
if [ -z "$HOST_ARTIFACT_SCRIPTS_PATH_ABS" ]; then
    log_error "Could not resolve absolute path for '$ARTIFACT_SCRIPTS_DIR_HOST'."
    exit 1
fi

# Absolute path to the config directory on the host
HOST_CONFIG_PATH_ABS="$(cd "$ARTIFACT_CONFIG_DIR_HOST" && pwd)"
if [ -z "$HOST_CONFIG_PATH_ABS" ]; then
    log_error "Could not resolve absolute path for '$ARTIFACT_CONFIG_DIR_HOST'."
    exit 1
fi

# Paths inside the Docker container
CONTAINER_PARQR_CODE_PATH="${DOCKER_WORKSPACE}/${DOCKER_PARQR_MOUNT_NAME}"
CONTAINER_ARTIFACT_SCRIPTS_PATH="${DOCKER_WORKSPACE}/${DOCKER_ARTIFACT_SCRIPTS_MOUNT_NAME}"
CONTAINER_CONFIG_PATH="${DOCKER_WORKSPACE}/${DOCKER_CONFIG_MOUNT_NAME}"
CONTAINER_MINIMAL_TEST_CONFIG_FILE_PATH="${CONTAINER_CONFIG_PATH}/${MINIMAL_TEST_CONFIG_FILE}"

# The master_experiment_runner.py will be executed from within CONTAINER_PARQR_CODE_PATH
# So, paths to its own location and config file need to be relative to that or absolute inside container.
COMMAND_IN_DOCKER="python3 ${CONTAINER_ARTIFACT_SCRIPTS_PATH}/master_experiment_runner.py --config ${CONTAINER_MINIMAL_TEST_CONFIG_FILE_PATH}"

# Step 3: Run the minimal test inside Docker
log_info "Step 2: Running minimal test inside Docker container..."
log_info "Host ParQR code path: $HOST_PARQR_CODE_PATH_ABS"
log_info "Host artifact scripts path: $HOST_ARTIFACT_SCRIPTS_PATH_ABS"
log_info "Host config path: $HOST_CONFIG_PATH_ABS"
log_info "Container ParQR code mount: $CONTAINER_PARQR_CODE_PATH"
log_info "Container artifact scripts mount: $CONTAINER_ARTIFACT_SCRIPTS_PATH"
log_info "Container config mount: $CONTAINER_CONFIG_PATH"
log_info "Container working directory: $CONTAINER_PARQR_CODE_PATH"
log_info "Command to execute in Docker: bash -c \"$COMMAND_IN_DOCKER\""
echo # Blank line for clarity

# Using sudo for docker command
# -it: Interactive TTY (good for seeing output live)
# --rm: Remove container after exit
# -v: Mount volumes
# -w: Set working directory inside container
DOCKER_RUN_OUTPUT_FILE="minimal_test_docker_output.log"
if sudo docker run -it --rm \
    -v "${HOST_PARQR_CODE_PATH_ABS}:${CONTAINER_PARQR_CODE_PATH}" \
    -v "${HOST_ARTIFACT_SCRIPTS_PATH_ABS}:${CONTAINER_ARTIFACT_SCRIPTS_PATH}" \
    -v "${HOST_CONFIG_PATH_ABS}:${CONTAINER_CONFIG_PATH}" \
    -w "${CONTAINER_PARQR_CODE_PATH}" \
    "${IMAGE_TO_USE}" \
    bash -c "${COMMAND_IN_DOCKER}" | tee "$DOCKER_RUN_OUTPUT_FILE"; then
    
    # Check the output file for success message from master_experiment_runner.py
    if grep -q "MINIMAL_TEST_PASSED" "$DOCKER_RUN_OUTPUT_FILE"; then
        log_info "--- Minimal Test PASSED successfully! ---"
        log_info "Detailed log from Docker run is in: $(pwd)/$DOCKER_RUN_OUTPUT_FILE"
        # Any files created by master_experiment_runner.py inside the mounted
        # CONTAINER_PARQR_CODE_PATH (e.g., in a 'results' subdir) will be in
        # HOST_PARQR_CODE_PATH_ABS on the host.
        log_info "If the test produces files, they would be within: $HOST_PARQR_CODE_PATH_ABS"
        exit 0
    else
        log_error "--- Minimal Test FAILED. ---"
        log_error "The script inside Docker did not report MINIMAL_TEST_PASSED."
        log_error "Please check the output above and in: $(pwd)/$DOCKER_RUN_OUTPUT_FILE"
        exit 1
    fi
else
    local exit_code=$?
    log_error "--- Minimal Test FAILED (Docker run command failed with exit code $exit_code). ---"
    log_error "Please check the output above and in: $(pwd)/$DOCKER_RUN_OUTPUT_FILE"
    if [ $exit_code -eq 126 ] || [ $exit_code -eq 127 ]; then
         log_error "Exit code $exit_code often indicates 'Command invoked cannot execute' or 'Command not found'."
         log_error "This might suggest an issue with bash, python3, or the script path inside the container, or an architecture mismatch if emulation isn't working."
    fi
    exit 1
fi
