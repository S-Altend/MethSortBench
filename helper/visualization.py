from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Patch, PathPatch
from matplotlib.ticker import PercentFormatter
from sklearn.metrics import ConfusionMatrixDisplay


category_colors = {
    # Host/Mouse group
    "humanBetter":  "#009E73",
    "human":        "#009E73",
    "graft":        "#009E73",
    "humanOnly":    "#80CEB9",
    "mouseBetter":  "#56B4E9",
    "mouse":        "#56B4E9",
    "host":         "#56B4E9",
    "mouseOnly":    "#AAD9F4",
    "discarded":   "#56B4E9",
    # Ambiguous group
    "both":         "#F0E442",
    "ambiguous":    "#E69F00",
    "neither":      "#D55E00",
    "unmapped":     "#D55E00",

    "sites":        "gray"
}

method_map = {
    "xengsort" : "Xengsort",
    "icrg" : "ICRG",
    "bamcmp" : "bamcmp",
    "xenofilter" : "XenofilteR"
}

def plot_method_comparison(data, pairs, line_pattern, label_str="proportion",
                           title=None, figsize=None, save=False, fig_dir=None, dpi=300):
    """
    data: melted dataframe with columns Sample, Method, Proportion
    pairs: list of (method_x, method_y) tuples to compare
    line_pattern: regex pattern to extract cell line from Sample name
    label_str: string to use in axis labels e.g. "human proportion" or "mouse proportion"
    """
    wide = data.pivot_table(index="Sample", columns="Method", values="Proportion").reset_index()
    wide["line"] = wide["Sample"].str.extract(line_pattern)

    n = len(pairs)
    fig, axes = plt.subplots(1, n, figsize=figsize or mm_to_inches((80 * n, 70)))

    if n == 1:
        axes = [axes]

    for ax, (mx, my) in zip(axes, pairs):
        for line, grp in wide.groupby("line"):
            ax.scatter(grp[mx], grp[my], label=line, s=70, alpha=0.85)
        for _, row in wide.iterrows():
            label = "_".join(row["Sample"].split("-")[-2:])
            ax.annotate(label, (row[mx], row[my]), fontsize=6,
                        xytext=(3, 2), textcoords="offset points")
        lims = [min(ax.get_xlim()[0], ax.get_ylim()[0]),
                max(ax.get_xlim()[1], ax.get_ylim()[1])]
        ax.plot(lims, lims, "--", color="grey", linewidth=0.8)
        ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:.0%}"))
        ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:.0%}"))
        ax.set_xlabel(f"{mx} — {label_str}", fontsize=9)
        ax.set_ylabel(f"{my} — {label_str}", fontsize=9)
        ax.set_title(f"{mx} vs {my}")
        ax.legend(fontsize=7, frameon=False)

    if title:
        plt.suptitle(title)
    plt.tight_layout()
    if save and fig_dir:
        plt.savefig(fig_dir, dpi=dpi, bbox_inches="tight")
    plt.show()


def stacked_barplot(df, percent=True, colors=None, save=False, fig_dir=None, file_name="stacked_barplot.pdf", figsize=None,
                    xlabel_size=10, ylabel_size=10, xtick_size=8, ytick_size=8,
                    title_size=12, legend_size=9, annotation_size=12, dpi=300):
    
    df_pivot = df.pivot_table(index="Sample", columns="Category", values="Reads", aggfunc="sum")
    
    if colors:
        category_order = [c for c in colors.keys() if c in df_pivot.columns]
        df_pivot = df_pivot[category_order]
        color_list = [colors[c] for c in df_pivot.columns]
    else:
        color_list = None

    if percent:
        df_pivot = df_pivot.div(df_pivot.sum(axis=1), axis=0) * 100
        xlabel = "Reads (%)"
    else:
        xlabel = "Reads"
    
    ax = df_pivot.plot(kind="barh", stacked=True, figsize=figsize, color=color_list)
    ax.set_xlabel(xlabel, fontsize=xlabel_size)
    ax.set_ylabel("Sample", fontsize=ylabel_size)
    ax.tick_params(axis="x", labelsize=xtick_size)
    ax.tick_params(axis="y", labelsize=ytick_size)
    ax.legend(title="Category", fontsize=legend_size)
    plt.tight_layout()
    if save and fig_dir:
        plt.savefig(fig_dir / file_name, dpi=dpi, bbox_inches="tight")

    plt.show()
    return df_pivot

def plot_delta_comparison(data, pairs, label_str="proportion",
                          title=None, figsize=None, save=False, fig_dir=None, dpi=300):
    """
    data: melted dataframe with columns Sample, Method, Proportion
    pairs: list of (method_a, method_b) tuples — delta = a - b
    label_str: string to use in labels e.g. "human proportion" or "mouse proportion"
    """
    wide = data.pivot_table(index="Sample", columns="Method", values="Proportion").reset_index()

    n = len(pairs)
    fig, axes = plt.subplots(1, n, figsize=figsize or mm_to_inches((80 * n, 70)),
                             sharey=True)

    if n == 1:
        axes = [axes]

    for ax, (ma, mb) in zip(axes, pairs):
        delta = wide.copy()
        delta["delta"] = delta[ma] - delta[mb]
        colors = ["#E87B4C" if d > 0 else "#4C9BE8" for d in delta["delta"]]
        ax.barh(delta["Sample"], delta["delta"], color=colors, alpha=0.85)
        ax.axvline(0, color="black", linewidth=0.8)
        ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:+.1%}"))
        ax.set_title(f"{ma} − {mb}")
        ax.set_xlabel("Proportion difference")

    if title:
        plt.suptitle(title)
    plt.tight_layout()
    if save and fig_dir:
        plt.savefig(fig_dir, dpi=dpi, bbox_inches="tight")
    plt.show()



def plot_assignment_bars_by_total_reads_stacked(
        df,
        assigned_cols=["Human_Assigned", "Mouse_Assigned", "Amb_Human_Assigned", "Amb_Mouse_Assigned"],
        colors=sns.color_palette("Set2"),
        width=0.6,
        save=False,
        save_format="png",
        fig_dir=None):

    # Melt the dataframe
    df_melted = df.melt(
        id_vars=["Sample_Name", "Total_Reads", "Mixture", "Replicate"],
        value_vars=assigned_cols,
        var_name="Assignment_Type",
        value_name="Reads"
    )

    # Clean mixture column
    df_melted["Mixture"] = df_melted["Mixture"].astype(str).str.replace("p", "")
    df_melted["Mixture"] = pd.to_numeric(df_melted["Mixture"], errors="coerce")

    # numeric + drop NA
    for col in ["Mixture", "Total_Reads", "Reads"]:
        df_melted[col] = pd.to_numeric(df_melted[col], errors="coerce")
    df_melted = df_melted.dropna()

    total_reads_list = sorted(df_melted["Total_Reads"].unique())

    for total_reads in total_reads_list:

        df_tr = df_melted[df_melted["Total_Reads"] == total_reads]

        # Aggregate sum of reads per Mixture × Assignment_Type
        agg = df_tr.groupby(["Mixture", "Assignment_Type"])["Reads"].sum().reset_index()

        # Total assigned reads per Mixture
        total_per_mixture = agg.groupby("Mixture")["Reads"].sum().reset_index().rename(columns={"Reads":"Total_Assigned"})

        # Merge to compute percentage per Mixture
        agg = agg.merge(total_per_mixture, on="Mixture")
        agg["Pct"] = agg["Reads"] / agg["Total_Assigned"] * 100

        mixtures = sorted(agg["Mixture"].unique())
        x = np.arange(len(mixtures))

        fig, ax = plt.subplots(figsize=(2*len(mixtures),5))

        # stacked bars
        bottom = np.zeros(len(mixtures))
        for i, assign in enumerate(assigned_cols):
            sub = agg[agg["Assignment_Type"]==assign]
            heights = [sub[sub["Mixture"]==m]["Pct"].values[0] for m in mixtures]

            rects = ax.bar(
                x,
                heights,
                width,
                bottom=bottom,
                color=colors[i],
                label=assign
            )
            # update bottom for stacking
            bottom += heights

            # annotate percentage
            for xi, h, b in zip(x, heights, bottom-heights):
                if h < 1:
                    continue
                ax.text(xi, b + h/2, f"{h:.0f}%", ha='center', va='center', fontsize=12)

        ax.set_xticks(x)
        ax.set_xticklabels([f"{int(m)}p" for m in mixtures])
        ax.set_xlabel("Human Fraction")
        ax.set_ylabel("Percentage of Assigned Reads")
        ax.set_title(f"Assigned reads percentages | Total Reads = {total_reads}")
        ax.legend(title="Assignment Type")
        plt.ylim(0,100)
        plt.tight_layout()

        if save and fig_dir is not None:
            outpath = fig_dir / f"assignment_pct_{total_reads}.{save_format}"
            plt.savefig(outpath, bbox_inches='tight', dpi=300)

        plt.show()

def plot_metric_vs_mixture(df, metric="Accuracy", figsize=None):
    # Aggregate: mean + SE across replicates
    summary = (
        df.groupby(["Total_Reads", "Mixture"])
          .agg(
              mean_metric=(metric, "mean"),
              se_metric=(metric, lambda x: x.std(ddof=1)/np.sqrt(len(x)))
          )
          .reset_index()
    )

    plt.figure(figsize=figsize)

    # Plot one line per Total_Reads
    for reads, sub in summary.groupby("Total_Reads"):
        plt.errorbar(
            sub["Mixture"],
            sub["mean_metric"],
            yerr=sub["se_metric"],
            marker="o",
            capsize=4,
            linewidth=2,
            label=f"{reads:,} reads"
        )

    plt.xlabel("Mixture")
    plt.ylabel(f"{metric} (mean ± SE)")
    plt.title("")
    plt.legend(title="Total_Reads", bbox_to_anchor=(1.05, 1), loc="upper left", frameon=False)
    plt.tight_layout()
    plt.show()
  

def plot_confusion_matrix(df, save=False, fig_dir=None, save_format="png"):
    grouped = df.groupby(["Sample_Name", "Total_Reads", "Mixture"])

    for (sample, total_read, mixture), group in grouped:

        # Build confusion matrix using group means
        cm = np.array([
            [group["TP"].mean(), group["FN"].mean()],
            [group["FP"].mean(), group["TN"].mean()]
        ])

        disp = ConfusionMatrixDisplay(
            confusion_matrix=cm,
            display_labels=["Human", "Mouse"]
        )
        disp.plot()

        ax = plt.gca()
        for text in ax.texts:
            value = float(text.get_text())
            text.set_text(f"{int(value/1e6)}M")

        plt.title(f"{sample} | Reads: {total_read} | Mix: {mixture}")

        if save and fig_dir is not None:
            plt.savefig(
                fig_dir / f"{sample}_{total_read}_{mixture}_confusion_matrix.{save_format}",
                bbox_inches="tight",
                dpi=300
            )

        plt.show()



def plot_confusion_bar(
    df,
    metrics_order=["TP", "TN", "FP", "FN"],
    colors=None,
    save=False,
    save_format="png",
    fig_dir=None,
    figsize=None,
    xlabel_size=10,
    ylabel_size=10,
    xtick_size=8,
    ytick_size=8,
    title_size=12,
    legend_size=9,
    annotation_size=12,
    dpi=300
):
    """
    Plots stacked bar charts of confusion matrix metrics (TP, TN, FP, FN)
    aggregated per Sample_Name, Total_Reads, and Mixture.
    
    Parameters
    ----------
    df : pd.DataFrame
        DataFrame containing columns: TP, TN, FP, FN, Sample_Name, Total_Reads, Mixture
    metrics_order : list of str
        Order of metrics to stack in the bars.
    colors : list of str
        Colors for each metric in the stack. Default: green, blue, red, orange.
    save : bool
        Whether to save figures.
    save_format : str
        File format for saved figures (png, pdf, etc.).
    fig_dir : Path or str
        Directory to save figures if save=True.
    figsize : tuple (width, height)
        Figure size for the plot.
    xlabel_size, ylabel_size, xtick_size, ytick_size, title_size, legend_size, annotation_size : int
        Font sizes for different elements.
    """
    
    if colors is None:
        colors = ["#2ca02c", "#1f77b4", "#d62728", "#ff7f0e"]  # TP, TN, FP, FN
    
    # Aggregate per Sample / Total_Reads / Mixture
    df_agg = df[metrics_order + ["Sample_Name", "Total_Reads", "Mixture"]].groupby(
        ["Sample_Name", "Total_Reads", "Mixture"]
    ).mean().reset_index()
    
    samples = df_agg["Sample_Name"].unique()
    total_reads_list = df_agg["Total_Reads"].unique()
    
    for sample in samples:
        for total_reads in total_reads_list:
            data = df_agg[(df_agg["Sample_Name"] == sample) & 
                          (df_agg["Total_Reads"] == total_reads)]
            if data.empty:
                continue
            
            data = data.sort_values("Mixture")
            x = np.arange(len(data))
            bottom = np.zeros(len(x))
            
            # Set figure size
            if figsize is None:
                fig_width = max(6, 1.5 * len(x))
                fig_height = 5
                figsize = (fig_width, fig_height)
            
            fig, ax = plt.subplots(figsize=figsize)
            
            # Plot stacked bars
            for i, metric in enumerate(metrics_order):
                counts = data[metric].values
                ax.bar(x, counts, bottom=bottom, color=colors[i], label=metric)
                bottom += counts
            
            # Annotate percentages
            for i in range(len(x)):
                total = bottom[i]
                cum_height = 0
                for j, metric in enumerate(metrics_order):
                    val = data.iloc[i][metric]
                    pct = val / total * 100 if total > 0 else 0
                    if pct < 1:
                        continue
                    ax.text(
                        x[i], cum_height + val/2,
                        f"{pct:.1f}%",
                        ha='center', va='center',
                        fontsize=annotation_size, color='black'
                    )
                    cum_height += val
            
            ax.set_xticks(x)
            ax.set_xticklabels(data["Mixture"], fontsize=xtick_size)
            ax.set_ylabel("Counts", fontsize=ylabel_size)
            ax.set_xlabel("Human fraction", fontsize=xlabel_size)
            ax.set_title(f"{sample} | Total Reads: {total_reads}", fontsize=title_size)
            ax.legend(title="Metric", fontsize=legend_size, title_fontsize=legend_size)
            ax.tick_params(axis='y', labelsize=ytick_size)
            
            plt.tight_layout()
            
            if save and fig_dir is not None:
                outpath = fig_dir / f"{sample}_{total_reads}_stacked_bar.{save_format}"
                plt.savefig(outpath, bbox_inches="tight", dpi=dpi)
            
            plt.show()


def plot_stacked_confusion_bar(
    df,
    metrics_order=["TP", "TN", "FP", "FN"],
    colors=None,
    save=False,
    save_format="png",
    title="",
    fig_dir=None,
    figsize=None,
    xlabel_size=10,
    ylabel_size=10,
    xtick_size=8,
    ytick_size=8,
    title_size=12,
    legend_size=9,
    annotation_size=12,
    dpi=300
):
    """
    Plots stacked bar charts of confusion matrix metrics (TP, TN, FP, FN)
    aggregated over all Sample_Name and Total_Reads, grouped by Mixture.
    """
    
    if colors is None:
        colors = ["#2ca02c", "#1f77b4", "#d62728", "#ff7f0e"]  # TP, TN, FP, FN

    # Aggregate over Sample_Name and Total_Reads
    df_agg = df.groupby("Mixture")[metrics_order].sum().reset_index()
    
    x = np.arange(len(df_agg))
    bottom = np.zeros(len(x))
    
    # Set figure size
    if figsize is None:
        fig_width = max(6, 1.5 * len(x))
        fig_height = 5
        figsize = (fig_width, fig_height)
    
    fig, ax = plt.subplots(figsize=figsize)
    
    # Plot stacked bars
    for i, metric in enumerate(metrics_order):
        counts = df_agg[metric].values
        ax.bar(x, counts, bottom=bottom, color=colors[i], label=metric)
        bottom += counts
    
    # Annotate percentages
    for i in range(len(x)):
        total = bottom[i]
        cum_height = 0
        for j, metric in enumerate(metrics_order):
            val = df_agg.iloc[i][metric]
            pct = val / total * 100 if total > 0 else 0
            if pct < 1:  # skip tiny percentages
                cum_height += val
                continue
            ax.text(
                x[i], cum_height + val/2,
                f"{pct:.1f}%",
                ha='center', va='center',
                fontsize=annotation_size, color='black'
            )
            cum_height += val
    
    # Set axis labels and title
    ax.set_xticks(x)
    ax.set_xticklabels(df_agg["Mixture"], fontsize=xtick_size)
    ax.set_ylabel("Counts", fontsize=ylabel_size)
    ax.set_xlabel("Mixture", fontsize=xlabel_size)
    ax.set_title(title, fontsize=title_size)
    ax.legend(title="Metric", fontsize=legend_size, title_fontsize=legend_size)
    ax.tick_params(axis='y', labelsize=ytick_size)
    
    plt.tight_layout()
    
    if save and fig_dir is not None:
        outpath = fig_dir / f"stacked_bar.{save_format}"
        plt.savefig(outpath, bbox_inches="tight", dpi=dpi)
    
    plt.show()

def mm_to_inches(mm_tuple):
    """
    Convert a tuple of millimeters to a tuple of inches.
    
    Parameters
    ----------
    mm_tuple : tuple of float or int
        Lengths in millimeters.
    
    Returns
    -------
    tuple of float
        Lengths in inches.
    """
    return tuple(mm / 25.4 for mm in mm_tuple)

def plot_assignment_bars(df, 
                        assigned_cols=["Human_Assigned", "Mouse_Assigned", "Amb_Human_Assigned", "Amb_Mouse_Assigned"],
                        colors=None,
                        width=0.2,
                        save=False,
                        save_format="png",
                        fig_dir=None):
    """
    Melt the dataframe and plot grouped barplots of assigned reads
    with mean ± SE and percentage annotations.

    Parameters
    ----------
    df : pd.DataFrame
        Original dataframe containing Sample_Name, Total_Reads, Mixture, Replicate, and assigned columns.
    assigned_cols : list of str
        Columns representing assignment types (e.g., ['Human', 'Mouse', 'Amb_Human', 'Amb_Mouse']).
    assignment_order : list of str, optional
        Order of assignment types in the plot. Default: same as assigned_cols.
    colors : list of str, optional
        Colors for each assignment type. Default: matplotlib default palette.
    width : float, optional
        Width of each bar in the grouped bar plot.

    Returns
    -------
    None
    """

    if colors is None:
        # default color palette
        colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728"][:len(assigned_cols)]
    
    # --- Melt dataframe ---
    df_melted = df.melt(
        id_vars=["Sample_Name", "Total_Reads", "Mixture", "Replicate"],
        value_vars=assigned_cols,
        var_name="Assignment_Type",
        value_name="Reads"
    )
    df_melted["Mixture"] = df_melted["Mixture"].str.replace("p","").astype(float)

    # --- Convert numeric and drop NaNs ---
    for col in ["Mixture", "Total_Reads", "Reads"]:
        df_melted[col] = pd.to_numeric(df_melted[col], errors="coerce")
    df_melted = df_melted.dropna(subset=["Mixture", "Total_Reads", "Reads"])
    # --- Aggregate mean and SE ---
    agg = df_melted.groupby(
        ["Sample_Name", "Total_Reads", "Mixture", "Assignment_Type"]
    ).agg(
        Mean_Reads=("Reads", "mean"),
        SE_Reads=("Reads", lambda x: x.std()/len(x)**0.5)
    ).reset_index()
    # --- Plotting ---
    samples = agg["Sample_Name"].unique()
    total_reads_list = agg["Total_Reads"].unique()

    for sample in samples:
        for total_reads in total_reads_list:
            data = agg[(agg["Sample_Name"] == sample) & (agg["Total_Reads"] == total_reads)]
            if data.empty:
                continue

            mixtures = sorted(data["Mixture"].unique())
    
            x = np.arange(len(mixtures))  # label locations

            fig, ax = plt.subplots(figsize=(2*len(mixtures), 4))

            # --- Plot bars for each assignment type ---
            for i, assign in enumerate(assigned_cols):
                assign_data = data[data["Assignment_Type"] == assign]
                means = [assign_data[assign_data["Mixture"] == m]["Mean_Reads"].values[0] for m in mixtures]
                ses = [assign_data[assign_data["Mixture"] == m]["SE_Reads"].values[0] for m in mixtures]
                rects = ax.bar(
                    x + i*width - width*len(assigned_cols)/2 + width/2,
                    means, width,
                    yerr=ses,
                    label=assign,
                    color=colors[i],
                    capsize=4
                )

                # Annotate percentage for this assignment type
                for rect, m in zip(rects, mixtures):
                    # Get the Total_Reads for this mixture (all rows for this sample & total_reads have same value)
                    total_reads_value = data[data["Mixture"] == m]["Total_Reads"].values[0]
                    pct = rect.get_height() / total_reads_value * 100 
                    ax.text(
                        rect.get_x() + rect.get_width()/2,
                        rect.get_height() + total_reads_value*0.01,
                        f"{pct:.0f}%",
                        ha='center', va='bottom', fontsize=9
                    )

            # --- Formatting (outside inner loop) ---
            ax.set_xticks(x)
            ax.set_xticklabels([f"{int(mixture)}p" for mixture in mixtures])
            ax.set_ylabel("Assigned Reads")
            ax.set_xlabel("Human Fraction")
            ax.set_title(f"{sample} | Total Reads: {total_reads}")
            ax.legend(title="Assignment Type")
            plt.tight_layout()

            # --- Save / show ---
            if save and fig_dir is not None:
                outpath = fig_dir / f"{sample}_{total_reads}_assigned_reads.{save_format}"
        
                plt.savefig(outpath, bbox_inches="tight", dpi=300)

            plt.show()

def errorplot_by_reads(df_metrics, metric="Accuracy", xcol="Human_Ratio", figsize=None, save=False, save_format="png", fig_dir=None, set_title=True, legend=True, ylim=None, palette=None):
    samples = df_metrics["Sample_Name"].unique()

    for sample in samples:
        plt.figure(figsize=figsize)
        sns.lineplot(
            data=df_metrics,
            x=xcol,
            y=metric,
            hue="Total_Reads",
            dashes=False,
            errorbar="se",
            legend=legend,
            marker="o",
            markersize=10,
            palette=palette
        )
        if set_title:
            plt.title(sample)
        plt.ylim(ylim)
        plt.ylabel(metric)
        plt.tight_layout()

        if save and fig_dir is not None:
            outpath = fig_dir / f"{sample}_{metric}.{save_format}"
            plt.savefig(outpath, bbox_inches="tight", dpi=300)

        plt.show()

def errorplot_by_sample(
    df_metrics,
    metric="Accuracy",
    xcol="Human_Ratio",
    save=False,
    save_format="png",
    fig_dir=None,
    set_title=True,
    figsize=None,
    legend=True,
    ylim=None,
    palette=None
):
    samples = df_metrics["Sample_Name"].unique()

    plt.figure(figsize=figsize)
    sns.lineplot(
        data=df_metrics,
        x=xcol,
        y=metric,
        hue="Sample_Name",     # <-- CHANGED
        dashes=False,
        errorbar="se",
        legend=legend,
        marker="o",
        markersize=10,
        palette=palette
    )

    if set_title:
        plt.title(f"{metric} across samples")

    if ylim:
        plt.ylim(ylim)

    plt.ylabel(metric)
    plt.tight_layout()

    if save and fig_dir is not None:
        outpath = fig_dir / f"errorplot_by_sample_{metric}.{save_format}"
        plt.savefig(outpath, bbox_inches="tight", dpi=300)

    plt.show()

def boxplot_by_samples(
    df_metrics,
    metric="Accuracy",
    save=False,
    save_format="png",
    fig_dir=None,
    set_title=True,
    palette=None,
    legend=True,
    dot_size=10,
    figsize=None
):
    plt.figure(figsize=figsize)

    if palette is None:
        mixtures = df_metrics["Human_Ratio"].unique()  
        mixtures = np.sort(mixtures)
        cmap = LinearSegmentedColormap.from_list("dkfz_cmap", dkfz_colors)

        n = len(mixtures)
        palette_list = [cmap(i/(n-1)) for i in range(n)]

        palette = dict(zip(mixtures, palette_list))


    # --- Boxplot: ONE box per sample, no hue ---
    sns.boxplot(
        data=df_metrics,
        x="Sample_Name",
        y=metric,
        color="white",
        boxprops=dict(edgecolor="black", linewidth=1.5),
        medianprops=dict(color="black", linewidth=1.2),
        whiskerprops=dict(color="black"),
        capprops=dict(color="black"),
        fliersize=0
    )

    # --- Colored dots by mixture ---
    sns.stripplot(
        data=df_metrics,
        x="Sample_Name",
        y=metric,
        hue="Human_Ratio",
        palette=palette,
        dodge=False,
        size=dot_size,
        alpha=0.7,
        jitter=True
    )

    # Legend for mixture
    # --- Legend ---
    if legend:
        handles, labels = plt.gca().get_legend_handles_labels()
        # sort legend numerically
        labels_numeric = [float(l) for l in labels]
        sorted_pairs = sorted(zip(labels_numeric, handles), key=lambda x: x[0])
        sorted_labels, sorted_handles = zip(*sorted_pairs)
        plt.legend(sorted_handles, [str(l) for l in sorted_labels], title="Human Ratio", bbox_to_anchor=(1.05, 1), loc='upper left')
    else:
        plt.legend([], [], frameon=False)

    if set_title:
        plt.title(f"{metric} across samples")

    plt.ylabel(metric)
    plt.xlabel("Sample")
    plt.tight_layout()

    if save and fig_dir is not None:
        outpath = fig_dir / f"boxplot_samples_colored_{metric}.{save_format}"
        plt.savefig(outpath, dpi=300, bbox_inches="tight")

    plt.show()


def lineplot_tools(df, x="Human_Ratio", y="Human_Loss", hue="Method",
                   ylabel=None, ylabel_fs=8, xlabel_fs=8, xlabel="Human Ratio",
                   tick_fs=7, figsize=None, palette=None, errorbar="ci", marker="o",
                   linewidth=1, markersize=4, legend=True, pos=None,
                   save=False, fig_dir="./", file_path="lineplot.png"):
    fig, ax = plt.subplots(figsize=figsize)
    if pos is not None:
        ax.set_position(pos)
    if xlabel is None:
        xlabel = x
    if ylabel is None:
        ylabel = y
    if palette is None:
        palette = sns.color_palette("Set2")
    hue_order = list(df["Method"].dropna().unique())
    sns.lineplot(
        data=df, x=x, y=y, hue=hue, hue_order=hue_order,
        palette=palette, errorbar=errorbar, marker=marker,
        linewidth=linewidth, markersize=markersize, ax=ax, legend=legend,
    )
    ax.set_xlim(0.1, 0.9)
    ax.xaxis.set_major_formatter(PercentFormatter(xmax=1))
    ax.set_ylabel(ylabel, fontsize=ylabel_fs)
    ax.set_xlabel(xlabel, fontsize=xlabel_fs)
    ax.tick_params(axis="both", labelsize=tick_fs)
    if save:
        plt.savefig(fig_dir / file_path)
    return ax


def boxplot_tools(df, x="Sample_Name", y="Contamination_Rate", hue="Method",
                  figsize=None, xlabel=None, ylabel=None, xlabel_fs=8, ylabel_fs=8,
                  xtick_fs=7, ytick_fs=7, boxplot_width=0.8,
                  whisker_lw=0.3, cap_lw=0.3, median_lw=0.3, box_lw=0.3,
                  palette=None, dot_size=1, dot_alpha=0.7, dot_lw=0.05,
                  legend=True, save=False, fig_dir="./", file_path="boxplot.png"):
    if palette is None:
        palette = sns.color_palette("Set2")
    if xlabel is None:
        xlabel = x
    if ylabel is None:
        ylabel = y
    sample_order = sorted(df[x].unique())
    hue_order = list(df[hue].dropna().unique())

    fig, ax = plt.subplots(figsize=figsize)
    sns.boxplot(
        data=df, x=x, y=y, hue=hue,
        order=sample_order, hue_order=hue_order, palette=palette,
        width=boxplot_width, dodge=True, showfliers=False, ax=ax,
        whiskerprops={"linewidth": whisker_lw}, capprops={"linewidth": cap_lw},
        medianprops={"linewidth": median_lw}, legend=False, linewidth=box_lw,
    )
    for p in [p for p in ax.patches if isinstance(p, PathPatch)]:
        fc = p.get_facecolor()
        p.set_facecolor((fc[0], fc[1], fc[2], 0.4))
        p.set_edgecolor((0, 0, 0, 1))
        p.set_linewidth(0.5)
    sns.stripplot(
        data=df, x=x, y=y, hue=hue,
        order=sample_order, hue_order=hue_order, palette=palette,
        dodge=True, jitter=True, size=dot_size, alpha=dot_alpha,
        linewidth=dot_lw, legend=False, ax=ax,
    )
    ax.set_ylabel(ylabel, fontsize=ylabel_fs)
    ax.set_xlabel(xlabel, fontsize=xlabel_fs)
    ax.tick_params(axis="x", labelsize=xtick_fs)
    ax.tick_params(axis="y", labelsize=ytick_fs)
    if legend:
        ax.legend(
            handles=[
                Patch(facecolor=c, edgecolor="black", linewidth=0.5, alpha=1, label=lab)
                for lab, c in zip(hue_order, palette[:len(hue_order)])
            ],
            title="Method", frameon=True, fontsize=8, title_fontsize=8,
        )
    plt.tight_layout()
    if save:
        plt.savefig(fig_dir / file_path, dpi=300)
    return ax, ax.get_position()


def barplot_runmem(
    df, x="sample", y="peak_rss_gb", hue="method",
    xlabel=None, ylabel=None, figsize=None, errorbar=None, legend=True,
    palette=None, ylabel_fs=10, xlabel_fs=10, xtick_fs=8, ytick_fs=8,
    hue_order=None, xtick_rotation=0,
    save=False, fig_dir="./", file_name="barplot.png", pos=None,
    horizontal=False, reverse_order=False
):
    fig, ax = plt.subplots(figsize=figsize)

    if palette is None:
        palette = sns.color_palette("Set2")

    sample_order = sorted(df[x].unique(), reverse=reverse_order)

    if hue_order is None:
        hue_order = list(df[hue].dropna().unique())

    if horizontal:
        plot_x, plot_y = y, x
        xlabel = xlabel or y
        ylabel = ylabel or x
    else:
        plot_x, plot_y = x, y
        xlabel = xlabel or x
        ylabel = ylabel or y

    sns.barplot(
        data=df,
        x=plot_x,
        y=plot_y,
        hue=hue,
        errorbar=errorbar,
        legend=legend,
        palette=palette,
        ax=ax,
        order=sample_order,
        hue_order=hue_order
    )

    ax.set_xlabel(xlabel, fontsize=xlabel_fs)
    ax.set_ylabel(ylabel, fontsize=ylabel_fs)
    ax.tick_params(axis="x", labelsize=xtick_fs)
    ax.tick_params(axis="y", labelsize=ytick_fs)

    if xtick_rotation != 0 and not horizontal:
        ax.set_xticklabels(ax.get_xticklabels(), rotation=xtick_rotation, ha="right")

    if pos is not None:
        ax.set_position(pos)

    if legend:
        ax.legend(title="Method", fontsize=8, title_fontsize=8)
    elif ax.get_legend() is not None:
        ax.get_legend().remove()

    if save:
        plt.savefig(fig_dir / file_name, dpi=300, bbox_inches="tight")

    return ax, ax.get_position()


def barplot_category_reads(
    df,
    category_col="Category",
    reads_col="Reads",
    sample_col="Sample",
    order=None,
    palette=None,
    errorbar=("ci", 95),
    xlabel=None, ylabel=None,
    title=None,
    xlabel_fs=10, ylabel_fs=10,
    xtick_fs=8, ytick_fs=8,
    title_fs=10,
    figsize=None,
    horizontal=False,
    label_bars=False,
    label_fs=7,
    label_fmt="{:.2f}%",
    save=False, fig_dir="./", file_name="barplot_categories.pdf",
):
    df = df.copy()
    df["Reads [%]"] = df.groupby(sample_col)[reads_col].transform(lambda x: x / x.sum() * 100)

    if horizontal:
        plot_x, plot_y = "Reads [%]", category_col
        xlabel = xlabel or "Reads [%]"
        ylabel = ylabel or "Category"
    else:
        plot_x, plot_y = category_col, "Reads [%]"
        xlabel = xlabel or "Category"
        ylabel = ylabel or "Reads [%]"

    fig, ax = plt.subplots(figsize=figsize)
    sns.barplot(
        data=df,
        x=plot_x,
        y=plot_y,
        errorbar=errorbar,
        order=order,
        palette=palette,
        ax=ax,
    )
    ax.set_xlabel(xlabel, fontsize=xlabel_fs)
    ax.set_ylabel(ylabel, fontsize=ylabel_fs)
    ax.tick_params(axis="x", labelsize=xtick_fs)
    ax.tick_params(axis="y", labelsize=ytick_fs)
    if horizontal:
        ax.set_xlim(left=0)
    else:
        ax.set_ylim(bottom=0)
    if title is not None:
        ax.set_title(title, fontsize=title_fs)

    if label_bars:
        cats = order if order is not None else df[category_col].unique().tolist()
        means = df.groupby(category_col)["Reads [%]"].mean()
        xlim = ax.get_xlim() if horizontal else None
        ylim = ax.get_ylim() if not horizontal else None
        for i, cat in enumerate(cats):
            val = means.get(cat, 0.0)
            label = label_fmt.format(val)
            if horizontal:
                offset = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.01
                ax.text(val + offset, i, label, va="center", ha="left", fontsize=label_fs)
            else:
                offset = (ax.get_ylim()[1] - ax.get_ylim()[0]) * 0.01
                ax.text(i, val + offset, label, va="bottom", ha="center", fontsize=label_fs)

    plt.tight_layout()
    if save:
        plt.savefig(Path(fig_dir) / file_name, dpi=300, bbox_inches="tight")
    return ax, ax.get_position()


def barplot_mspi_filter(
    sites,
    figsize=None,
    xlabel_fs=10,
    ylabel_fs=10,
    xtick_fs=8,
    ytick_fs=8,
    save=False,
    fig_dir="./",
    file_name="sites.pdf"
):
    fig, ax = plt.subplots(figsize=figsize)

    sns.barplot(
        data=sites,
        x="sites",
        y="Sample",
        ax=ax
    )

    ax.set_xlabel("non-MspI reads [%]", fontsize=xlabel_fs)
    ax.set_ylabel("Sample", fontsize=ylabel_fs)

    ax.tick_params(axis="x", labelsize=xtick_fs)
    ax.tick_params(axis="y", labelsize=ytick_fs)

    if save:
        plt.savefig(fig_dir / file_name, dpi=300, bbox_inches="tight")
        print(f"Saved plot to {fig_dir / file_name}")

    return ax

def plot_xengsort_summary(df, figsize=None, save=False, figure_dir="./", file_name="xengsort_summary.pdf",
                          xlabel_fs=9, ylabel_fs=9, title_fs=10, xtick_fs=8, ytick_fs=8,
                          legend_fs=8, legend_title_fs=9, percent=False, size=5, legend=False,
                          title="Xengsort Classification Summary", xticks=None):
    df = df.copy()
    df = df.sort_values("Category", key=lambda x: x.map(lambda cat: list(category_colors.keys()).index(cat)))
    if percent:
        df["Reads"] = df.groupby("Sample")["Reads"].transform(lambda x: x / x.sum() * 100)

    plt.figure(figsize=figsize)

    # Bars first (lowest layer)
    sns.barplot(
        df, x="Reads", y="Category", hue="Category",
        palette=category_colors, errorbar=None, alpha=0.5,
        zorder=1,
    )
    # Dots in the middle
    sns.swarmplot(
        df, x="Reads", y="Category", hue="Category",
        palette=category_colors, size=size, legend=False,
        zorder=2,
    )
    # Error bars on top
    sns.barplot(
        df, x="Reads", y="Category",
        errorbar="sd", alpha=0,                   # transparent bars, just for the errors
        capsize=0.3,
        err_kws={"linewidth": 1, "color": "black", "zorder": 3},
    )

    plt.title(title, fontsize=title_fs)
    plt.xlabel("Reads [%]" if percent else "Number of Reads", fontsize=xlabel_fs)
    plt.ylabel("Category", fontsize=ylabel_fs)
    if xticks is not None:
        plt.xticks(xticks, fontsize=xtick_fs)
    else:
        plt.xticks(fontsize=xtick_fs)
    plt.yticks(fontsize=ytick_fs)
    if legend:
        ax = plt.gca()
        handles = [Patch(color=color, label=cat) for cat, color in category_colors.items() if cat in df["Category"].values]
        leg = ax.legend(handles=handles, title="Category")
        leg.get_title().set_fontsize(legend_title_fs)
        for text in leg.get_texts():
            text.set_fontsize(legend_fs)
    plt.tight_layout()
    if save:
        plt.savefig(Path(figure_dir) / file_name, bbox_inches="tight")
    plt.show()

    return df