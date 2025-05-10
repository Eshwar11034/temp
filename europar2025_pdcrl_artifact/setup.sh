#!/bin/bash

# --- Script Configuration ---
DOCKER_IMAGE_TO_PULL="parsqp/temp:latest" 
PARQR_REPO_URL="https://github.com/PDCRL/ParQR.git"
PARSQP_REPO_URL="https://github.com/PDCRL/ParSQP.git"
PARQR_LOCAL_DIR_NAME="pdcrl-parqr"
PARSQP_LOCAL_DIR_NAME="pdcrl-parsqp"

# --- Helper Functions ---
log_info() { echo "[SETUP INFO] $1"; }
log_warn() { echo "[SETUP WARN] $1"; }
log_error() { echo "[SETUP ERROR] $1" >&2; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

get_docker_platform() {
    local arch; arch=$(uname -m)
    case $arch in
        x86_64) echo "linux/amd64" ;;
        aarch64) echo "linux/arm64" ;;
        arm64) echo "linux/arm64" ;;
        *) log_error "Unsupported host architecture for build: $arch"; return 1 ;;
    esac
    return 0
}

# --- Main Setup Logic ---
log_info "Starting Artifact Setup Script..."
if [ "$(id -u)" -ne 0 ]; then
    log_warn "This script uses 'sudo' for Docker commands. You might be prompted for your password."
    if ! sudo -n true 2>/dev/null; then
        log_info "Attempting to acquire sudo privileges..."
        if ! sudo true; then log_error "Failed to acquire sudo privileges."; exit 1; fi
    fi
fi

log_info "Step 1: Checking prerequisites..."
if ! command_exists docker; then log_error "Docker not found."; exit 1; fi
if ! command_exists git; then log_error "Git not found."; exit 1; fi
if ! command_exists uname; then log_error "'uname' not found."; exit 1; fi
log_info "Verifying Docker daemon access..."
if ! sudo docker info > /dev/null 2>&1; then log_error "Cannot access Docker daemon with sudo."; exit 1; fi
log_info "Prerequisites met. Docker daemon accessible."

log_info "Step 2: Setting up Docker image..."
IMAGE_TO_USE="" 
log_info "Attempting to pull Docker image: $DOCKER_IMAGE_TO_PULL..."
if sudo docker pull "$DOCKER_IMAGE_TO_PULL"; then
    log_info "Docker image '$DOCKER_IMAGE_TO_PULL' pulled successfully."
    IMAGE_TO_USE="$DOCKER_IMAGE_TO_PULL"
    PULLED_ARCH=$(sudo docker image inspect "$DOCKER_IMAGE_TO_PULL" --format '{{.Architecture}}' 2>/dev/null)
    HOST_ARCH_RAW=$(uname -m)
    HOST_ARCH_DOCKER_FORMAT=$(get_docker_platform | cut -d'/' -f2)
    log_info "Pulled image arch: $PULLED_ARCH. Host arch for Docker: $HOST_ARCH_DOCKER_FORMAT (raw: $HOST_ARCH_RAW)."
    if [[ "$PULLED_ARCH" != "$HOST_ARCH_DOCKER_FORMAT" ]]; then
        log_warn "----------------------------------------------------------------------------------";
        log_warn "POTENTIAL ARCHITECTURE MISMATCH: PULLED IMAGE ($PULLED_ARCH) vs HOST ($HOST_ARCH_DOCKER_FORMAT)!";
        log_warn "If host is ARM and image AMD64, ensure Docker emulation (Rosetta/QEMU) is active.";
        log_warn "Experiments might run very slowly or fail.";
        log_warn "----------------------------------------------------------------------------------";
    fi
else
    log_warn "Failed to pull '$DOCKER_IMAGE_TO_PULL'..."
    fi

if [ -z "$IMAGE_TO_USE" ]; then log_error "Failed to obtain Docker image. Setup cannot continue."; exit 1; fi
log_info "Using Docker image: $IMAGE_TO_USE for subsequent steps."

# --- >>> SAVE THE IMAGE NAME TO .artifact_docker_image_name <<< ---
echo "$IMAGE_TO_USE" > .artifact_docker_image_name
if [ $? -ne 0 ]; then
    log_error "Failed to write Docker image name to .artifact_docker_image_name file in $(pwd)."
    exit 1
else
    log_info "Docker image name '$IMAGE_TO_USE' saved to $(pwd)/.artifact_docker_image_name"
fi
# --- >>> END OF CHANGE <<< ---

log_info "Step 3: Cloning Git repositories..."
if [ -d "$PARQR_LOCAL_DIR_NAME/.git" ]; then log_info "Repo '$PARQR_LOCAL_DIR_NAME' exists.";
elif [ -d "$PARQR_LOCAL_DIR_NAME" ]; then log_warn "'$PARQR_LOCAL_DIR_NAME' exists but not a Git repo."; exit 1;
else
    log_info "Cloning ParQR ($PARQR_REPO_URL)..."
    if git clone "$PARQR_REPO_URL" "$PARQR_LOCAL_DIR_NAME"; then log_info "ParQR cloned to '$PARQR_LOCAL_DIR_NAME'.";
    else log_error "Failed to clone ParQR."; exit 1; fi
fi

if [ -d "$PARSQP_LOCAL_DIR_NAME/.git" ]; then log_info "Repo '$PARSQP_LOCAL_DIR_NAME' exists.";
elif [ -d "$PARSQP_LOCAL_DIR_NAME" ]; then log_warn "'$PARSQP_LOCAL_DIR_NAME' exists but not a Git repo."; exit 1;
else
    log_info "Cloning ParSQP ($PARSQP_REPO_URL)..."
    if git clone "$PARSQP_REPO_URL" "$PARSQP_LOCAL_DIR_NAME"; then log_info "ParSQP cloned to '$PARSQP_LOCAL_DIR_NAME'.";
    else log_error "Failed to clone ParSQP."; exit 1; fi
fi

log_info "Step 4: Setup Complete!"
echo
log_info "--------------------------------------------------------------------"
log_info "Artifact Setup Summary:"
log_info "1. Main artifact directory: $(pwd)"
log_info "2. Docker image for use: $IMAGE_TO_USE (name stored in .artifact_docker_image_name)"
log_info "3. ParQR repository in: $(pwd)/$PARQR_LOCAL_DIR_NAME"
log_info "4. ParSQP repository in: $(pwd)/$PARSQP_LOCAL_DIR_NAME"
log_info "--------------------------------------------------------------------"
echo
log_info "Next Steps:"
log_info "1. You are currently in the artifact directory: $(pwd)"
log_info "2. To run a quick minimal test, execute from this directory:"
log_info "   ./run_minimal_test.sh"
log_info "3. To run full benchmarks, execute from this directory:"
log_info "   ./run_benchmarks.sh"
log_info "--------------------------------------------------------------------"

exit 0
