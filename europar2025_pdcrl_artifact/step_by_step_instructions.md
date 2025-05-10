This section details how to run the benchmark experiments that correspond to the figures and findings in the paper "Efficient Task Graph Scheduling for Parallel QR Factorization in SLSQP".

**Prerequisites:**

* You must be inside the artifact workspace directory (e.g., `europar2025_pdcrl_artifact/`) created during setup.

**Author's Test Platform (Primary for ParQR Experiments):**

* **CPU:** Intel(R) Xeon(R) Gold 6230R @ 2.10GHz
* **Cores/Threads:** 2 Sockets, 26 Cores/Socket, 2 Threads/Core (104 Logical CPUs)
* **OS:** Ubuntu 20.04 LTS (within Docker: Ubuntu 22.04 as per Dockerfile)
* **Compiler:** g++ (version corresponding to Ubuntu 22.04 default, e.g., 11.x)
* **TBB:** Intel oneAPI TBB (version installed by `intel-oneapi-tbb-devel` package in Docker)

### 2.1. Running Benchmark Experiments

All benchmark experiments are launched using the `run_benchmarks.sh` script. This script provides a menu to select individual experiments or run them in batches.

1. **Ensure you are in the artifact workspace directory.**
2. **Make the benchmark script executable (if not already):**
   ```bash
   chmod +x run_benchmarks.sh
   ```
3. **Launch the benchmark runner:**
   ```bash
   ./run_benchmarks.sh
   ```

   This will display a menu of available benchmark experiments.

### 2.2. Experiment 1: Parameter Tuning (Data for Figure 2)

* **Description:** This experiment performs an exhaustive sweep over `Alpha` and `Beta` parameters (even numbers from 2 to 32) for a fixed matrix size (10800x10800) and thread count (26 threads) for both "Without Priority" and "With Priority" configurations of the Intel TBB-based scheduler.
* **To Run:**

  * Select option **` Parameter Tuning (Generates Fig 2 style data)`** from the `run_benchmarks.sh` menu.
  * **WARNING:** This experiment is long-running (can take several hours).
* **Expected Output:**

  * CSV files will be generated in the `results_param_tuning/` subdirectory (e.g., `param_tuning_without_priority_m10800_t26.csv`, `param_tuning_with_priority_m10800_t26.csv`).
  * Heatmap plots (`.png`) corresponding to Figure 2a and 2b will also be saved in `results_param_tuning/`.
  * The script will print the optimal (Alpha, Beta) pair found for each priority setting.

### 2.3. Experiment 2: Scalability Analysis (Figure 4a, 4b)

* **Description:** This experiment evaluates the execution time of "Barrier", "Without Priority", and "With Priority" methods for increasing matrix sizes (300 to 10800) using fixed thread counts (26 and 52 threads). Optimal Alpha/Beta values (determined from Experiment 1) are used for "Without Priority" and "With Priority".
* **To Run:**

  * Select option **` Scalability Analysis (Generates Fig 4a, 4b style data)`** from the `run_benchmarks.sh` menu.
* **Expected Output:**

  * A CSV file (`scalability_results.csv`) will be generated in the `results_scalability/` subdirectory.
  * Plot files `fig4a_scalability_26threads.png` and `fig4b_scalability_52threads.png` will be generated in `results_scalability/`, corresponding to Figures 4a and 4b in the paper.

### 2.4. Experiment 3: Throughput Evaluation (Figure 5)

* **Description:** This experiment evaluates the execution time of "Barrier", "Without Priority", and "With Priority" methods for a fixed large matrix size (8192x8192) with an increasing number of threads (4 to 104, matching points in Fig 5). Optimal Alpha/Beta values are used.
* **To Run:**

  * Select option **` Throughput Evaluation (Generates Fig 5 style data)`** from the `run_benchmarks.sh` menu.
* **Expected Output:**

  * A CSV file (`throughput_results.csv`) will be generated in the `results_throughput/` subdirectory.
  * A plot file (`fig5_throughput.png`) corresponding to Figure 5 in the paper will be generated in `results_throughput/`.

### 2.5. Running Batched Experiments

The `run_benchmarks.sh` script also provides options to run multiple experiments:

* **Option ` Run ALL Benchmarks (1, 2, and 3)`:** This will execute Parameter Tuning, then Scalability, then Throughput. Be aware this will take a very long time due to the Parameter Tuning experiment.

### 2.6. Interpreting Results

* **CSV Files:** Raw and averaged timing data is stored in CSV files within the respective `results_.../` subdirectories created in your workspace (e.g., `europar2025_pdcrl_artifact_workspace/pdcrl-parqr/Dynamic-Task-Scheduling/results/`).
* **Plot Files (.png):** Generated plots are saved alongside the CSVs. These plots are designed to visually match the corresponding figures in the paper.
* **Qualitative Outcome:** Due to hardware differences, exact execution times will vary. Reviewers should look for similar trends, performance rankings between methods, and scalability patterns as reported in the paper. For example, in Figure 4 and 5, the "Without Priority" and "With Priority" methods should generally outperform the "Barrier" method.
