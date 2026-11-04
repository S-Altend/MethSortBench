# Visualization of benchmark results
In this subdirectory, we compared read sorting tool performances and scalability.

## Performance & Scalability metrics

$\text{Accuracy Score} = 0.7 \times \text{Precision} + 0.3 \times \text{Sensitivity}$

$\text{Runtime Score} =  1- min\_max( \text{Runtime})$

$\text{Max. Memory Score} = 1- min\_max( \text{Max. Memory})$

$\text{Efficiency Score} = 0.5 \times \text{Runtime Score} + 0.5 \times \text{Max. Memory Score}$

$\text{Overall Score} =  0.7 \times \text{Accuracy Score} + 0.3 \times \text{Efficiency Score}$



## Scripts
| Script | Usage | Requirement |
|--------|-------|-------------|
| [07.1_xengsort_metrics.ipynb](./07.1_xengsort_metrics.ipynb) | Calculate performance metrics and visualize results for Xengsort | [data_science.yml](../environments/data_science.yml) |
| [07.2_icrg_metrics.ipynb](./07.2_icrg_metrics.ipynb) | Calculate performance metrics and visualize results for ICRG | [data_science.yml](../environments/data_science.yml) |
| [07.3_bamcmp_metrics.ipynb](./07.3_bamcmp_metrics.ipynb) | Calculate performance metrics and visualize results for bamcmp | [data_science.yml](../environments/data_science.yml) |
| [07.4_xenofilter_metrics.ipynb](./07.4_xenofilter_metrics.ipynb) | Calculate performance metrics and visualize results for XenofilteR| [data_science.yml](../environments/data_science.yml) |
| [07.5_compare_performances.ipynb](./07.5_compare_performances.ipynb) | Compare performances between read sorting tools | [data_science.yml](../environments/data_science.yml) |
| [07.6_summary.ipynb](./07.6_summary.ipynb) | Summarize performance and scalability metrics (Fig. 2) | [data_science.yml](../environments/data_science.yml) |
