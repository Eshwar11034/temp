# Dockerfile - For x86_64 (amd64) build using Intel oneAPI TBB
# File: Dockerfile
# -------------------------------------------------------------
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

# 1. Install core build tools, runtime dependencies, and Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        g++ \
        cmake \
        git \
        wget \
        curl \
        python3 \
        python3-pip \
        gpg \
        gpg-agent \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Python packages
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
        pandas \
        numpy \
        matplotlib \
        seaborn \
    && rm -rf /root/.cache/pip

# 2a. Make a convenient `python` alias -> python3
RUN ln -s /usr/bin/python3 /usr/local/bin/python

# 3. Install Intel oneAPI TBB
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
        | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
        | tee /etc/apt/sources.list.d/oneAPI.list && \
    apt-get update && \
    apt-get install -y intel-oneapi-tbb-devel && \
    rm -rf /var/lib/apt/lists/*

# 4. Set up environment for oneAPI TBB (REVISED FOR LINKER)
ENV ONEAPI_ROOT /opt/intel/oneapi
ENV TBB_ROOT ${ONEAPI_ROOT}/tbb/latest
ENV CPATH ${TBB_ROOT}/include:${CPATH}

# Dynamically find the TBB library path and set LD_LIBRARY_PATH and LIBRARY_PATH
# This RUN command determines the path and writes it to a file that can be sourced by subsequent ENV or by an entrypoint.
# Or, we can try to set it directly if the path is predictable after 'latest'.
# Your 'ls' output showed libtbb.so directly in /opt/intel/oneapi/tbb/2022.1/lib
# So, TBB_ROOT/lib should be the directory.
ENV TBB_LIB_DIR_FOR_ENV ${TBB_ROOT}/lib
ENV LIBRARY_PATH ${TBB_LIB_DIR_FOR_ENV}:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH ${TBB_LIB_DIR_FOR_ENV}:${LD_LIBRARY_PATH}

# Additionally, ensure ldconfig knows about this path.
# The intel-oneapi-tbb-devel package *should* do this, but let's be explicit.
RUN echo "${TBB_LIB_DIR_FOR_ENV}" > /etc/ld.so.conf.d/oneapi-tbb.conf && \
    ldconfig

# 5. Quick sanity check (shows in build log)
RUN echo "--- Sanity Checks ---" && \
    echo "Architecture: $(dpkg --print-architecture 2>/dev/null || uname -m)" && \
    echo "CPATH: $CPATH" && \
    echo "LIBRARY_PATH: $LIBRARY_PATH" && \
    echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH" && \
    echo "GCC Version:" && (gcc --version | head -n1 || echo "GCC not found") && \
    echo "G++ Version:" && (g++ --version | head -n1 || echo "G++ not found") && \
    echo "Python Version:" && (python --version || echo "Python alias not found") && \
    echo "Python3 Version:" && (python3 --version || echo "Python3 not found") && \
    echo "Python Deps Check:" && (python -c "import pandas, numpy, matplotlib, seaborn; print('✓ Python scientific stack OK')" || echo "Python scientific stack import failed") && \
    echo "TBB_ROOT Check: ${TBB_ROOT}" && (ls -d ${TBB_ROOT} || echo "TBB_ROOT ${TBB_ROOT} not found") && \
    echo "TBB Include Check:" && (ls ${TBB_ROOT}/include/tbb/tbb.h || echo "TBB headers not found at ${TBB_ROOT}/include/tbb/tbb.h") && \
    echo "TBB Lib Dir (from ENV): ${TBB_LIB_DIR_FOR_ENV}" && \
    (ls ${TBB_LIB_DIR_FOR_ENV}/libtbb.so || echo "libtbb.so not found in ${TBB_LIB_DIR_FOR_ENV}") && \
    echo "ldconfig check for libtbb:" && (ldconfig -p | grep libtbb || echo "libtbb not found by ldconfig -p") && \
    echo "Attempting to compile a TBB test program..." && \
    echo -e '#include <iostream>\n#include <tbb/parallel_for.h>\n#include <tbb/blocked_range.h>\nint main() { tbb::parallel_for(tbb::blocked_range<int>(0,100), [](const tbb::blocked_range<int>& r){ for(int i=r.begin(); i!=r.end(); ++i); }); std::cout << "TBB test compiled and ran." << std::endl; return 0; }' > /tmp/test_tbb.cpp && \
    # The ENV CPATH, LIBRARY_PATH, LD_LIBRARY_PATH should be picked up by g++ here
    (g++ /tmp/test_tbb.cpp -o /tmp/test_tbb_exec -std=c++17 -ltbb && /tmp/test_tbb_exec && echo "✓ TBB Compilation & Runtime Test OK" || echo "✗ TBB Compilation or Runtime Test FAILED. Check CPATH, LIBRARY_PATH, LD_LIBRARY_PATH and linker flags.") && \
    rm -f /tmp/test_tbb.cpp /tmp/test_tbb_exec && \
    echo "--- End Sanity Checks ---"

WORKDIR /workspace

CMD ["/bin/bash"]
