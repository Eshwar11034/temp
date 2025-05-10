This guide outlines the steps to set up the artifact environment and run a minimal test.

### 1.1. Prerequisites

Ensure your system (Linux x86_64 recommended) has the following installed:

* **Docker Engine** (v20.10+): Daemon must be running.
* **Git** (v2.25+).
* **Bash Shell**.
* **`sudo` access** (for Docker commands).
* **Internet Connection** (for initial setup).

### 1.2. Artifact Download & Initial Setup

1. **Download and Extract:**
   Download the artifact ZIP file (e.g., `europar2025_pdcrl_artifact.zip`) and extract it.

   ```bash
   unzip europar2025_pdcrl_artifact.zip -d <your_chosen_artifact_directory>
   cd <your_chosen_artifact_directory> 
   ```
2. **Run Setup Script:**
   This script prepares the Docker image and clones source code into a workspace.

   ```bash
   chmod +x setup.sh
   ./setup.sh 
   ```
3. **Navigate to Workspace:**
   Change into the workspace directory created by the setup script.

   ```bash
   cd europar2025_artifact
   ```

### 1.3. Run Minimal Test

This quick test verifies the core functionality.

1. **Ensure you are in the workspace directory** (e.g., `europar2025_pdcrl_artifact/`).
2. **Run the Minimal Test Script:**

   ```bash
   chmod +x run_minimal_test.sh
   ./run_minimal_test.sh
   ```

**If the minimal test passes, the setup is complete and correct.** You can now proceed to Part 2 to reproduce the full benchmark results. If errors occur, please review the prerequisites and the output logs.
