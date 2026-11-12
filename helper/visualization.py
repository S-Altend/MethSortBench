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
    xtick_size=9,
    ytick_size=9,
    title_size=12,
    legend_size=9,
    annotation_size=7,
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
    
    """
    return tuple(mm / 25.4 for mm in mm_tuple)

def lineplot_tools(df, x="Human_Ratio", y="Human_Loss", hue="Method",
                   ylabel=None, ylabel_fs=10, xlabel_fs=10, xlabel="Human Ratio",
                   tick_fs=8, figsize=None, palette=None, errorbar="sd",
                   marker="o", linewidth=1, markersize=4, legend=True, pos=None,
                   xlim=(0, 1), n_xticks=5,
                   percent=False, percent_scale=None, percent_decimals=0,
                   x_percent=True, x_percent_xmax=1, x_percent_decimals=0,
                   save=False, fig_dir="./", file_path="lineplot.png"):

    # ---- percent handling (y-axis) ---------------------------------------
    if percent:
        df = df.copy()
        if percent_scale is None:
            percent_scale = 100 if df[y].max() <= 1.0 else 1
        if percent_scale != 1:
            df[y] = df[y] * percent_scale
    # -----------------------------------------------------------------------

    fig, ax = plt.subplots(figsize=figsize)

    if pos is not None:
        ax.set_position(pos)

    if xlabel is None:
        xlabel = x
    if ylabel is None:
        ylabel = y
    if percent and not ylabel.rstrip().endswith("%"):
        ylabel = f"{ylabel} [%]"
    if palette is None:
        palette = sns.color_palette("Set2")

    hue_order = list(df[hue].dropna().unique())

    sns.lineplot(
        data=df, x=x, y=y, hue=hue, hue_order=hue_order, palette=palette,
        errorbar=errorbar, marker=marker, linewidth=linewidth,
        markersize=markersize, ax=ax, legend=legend,
    )

    ax.set_xlim(*xlim)
    if n_xticks:
        lo, hi = df[x].min(), df[x].max()
        ax.set_xticks(np.linspace(lo, hi, n_xticks))
    if x_percent:
        ax.xaxis.set_major_formatter(
            PercentFormatter(xmax=x_percent_xmax, decimals=x_percent_decimals)
        )

    if percent:
        ax.yaxis.set_major_formatter(PercentFormatter(xmax=100, decimals=percent_decimals))

    ax.set_ylabel(ylabel, fontsize=ylabel_fs)
    ax.set_xlabel(xlabel, fontsize=xlabel_fs)
    ax.tick_params(axis="both", labelsize=tick_fs)

    if save:
        fig.savefig(Path(fig_dir) / file_path, bbox_inches=None)

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
    hue_order=None, xtick_rotation=0, bar_alpha=0.4, bar_lw=1.5,
    margins=(0.22, 0.20, 0.97, 0.97),
    save=False, fig_dir="./", file_name="barplot.png",
    horizontal=False, reverse_order=False
):
    fig, ax = plt.subplots(figsize=figsize)

    if palette is None:
        palette = sns.color_palette("Set2")
    if hue_order is None:
        hue_order = list(df[hue].dropna().unique())

    sample_order = sorted(df[x].unique(), reverse=reverse_order)

    if horizontal:
        plot_x, plot_y = y, x
        xlabel = xlabel or y
        ylabel = ylabel or x
    else:
        plot_x, plot_y = x, y
        xlabel = xlabel or x
        ylabel = ylabel or y

    sns.barplot(
        data=df, x=plot_x, y=plot_y, hue=hue, errorbar=errorbar,
        legend=legend, palette=palette, ax=ax,
        order=sample_order, hue_order=hue_order,
    )

    for p in ax.patches:
        r, g, b, _ = p.get_facecolor()
        p.set_edgecolor((r, g, b, 1))
        p.set_facecolor((r, g, b, bar_alpha))
        p.set_linewidth(bar_lw)

    ax.set_xlabel(xlabel, fontsize=xlabel_fs)
    ax.set_ylabel(ylabel, fontsize=ylabel_fs)
    ax.tick_params(axis="x", labelsize=xtick_fs)
    ax.tick_params(axis="y", labelsize=ytick_fs)

    if xtick_rotation != 0 and not horizontal:
        ax.tick_params(axis="x", rotation=xtick_rotation)
        plt.setp(ax.get_xticklabels(), ha="right")

    if legend:
        ax.legend(title="Method", fontsize=8, title_fontsize=8)
    elif ax.get_legend() is not None:
        ax.get_legend().remove()

    left, bottom, right, top = margins
    fig.subplots_adjust(left=left, bottom=bottom, right=right, top=top)

    if save:
        fig.savefig(Path(fig_dir) / file_name, dpi=300, pad_inches=0)

    return ax, ax.get_position()



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