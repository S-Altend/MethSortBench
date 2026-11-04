import re
import pandas as pd
from pathlib import Path
import numpy as np

sample_map = {
    "wgbs-human-brca-cl1_wgbs-mouse-bm-hsc1": "Mixture 1",
    "wgbs-human-pancreas-organoid1_wgbs-mouse-pancreas-organoid1": "Mixture 2",
    "wgbs-human-pancreas-organoid2_wgbs-mouse-pancreas-organoid2" : "Mixture 3",
    "wgbs-human-pancreas-organoid3_wgbs-mouse-pancreas-organoid3" : "Mixture 4"

}

sample_map_short = {
    "cellline": "M1",
    "organoid1": "M2",
    "organoid2" : "M3",
    "organoid3" : "M4"
}

sample_map_short1 = {
    "wgbs-human-brca-cl1_wgbs-mouse-bm-hsc1": "M1",
    "wgbs-human-pancreas-organoid1_wgbs-mouse-pancreas-organoid1": "M2",
    "wgbs-human-pancreas-organoid2_wgbs-mouse-pancreas-organoid2" : "M3",
    "wgbs-human-pancreas-organoid3_wgbs-mouse-pancreas-organoid3" : "M4"

}

def read_pdx_evaluations(results_dir, method):
    """Read evaluation.tsv files from PDX method results.

    Each evaluation.tsv is produced by the 08_pdx evaluate scripts and has
    columns: Category, Reads, Sample, Method.

    Parameters
    ----------
    results_dir : str or Path
        Base results directory containing per-method subdirectories.
        E.g. '<repo>/08_pdx/results/'.
    method : str
        Method subdirectory name, e.g. 'icrg'.

    Returns
    -------
    pd.DataFrame
        Concatenated long-format table with columns: Category, Reads, Sample, Method.
    """
    results_dir = Path(results_dir)
    files = list((results_dir / method).rglob("evaluation.tsv"))
    if not files:
        raise FileNotFoundError(f"No evaluation.tsv files found in {results_dir / method}")
    return pd.concat([pd.read_table(f) for f in files], ignore_index=True)


def read_evaluations(data_dir, method, exclude=None):
    # --- Collect all evaluation.tsv files at once ---
    all_files = [f for f in (data_dir / method).rglob("evaluation.tsv")]
    if exclude is not None:
        all_files = [path for path in all_files if exclude not in str(path)]

    # --- Read all files into a single DataFrame ---
    df_list = []
    for f in all_files:
        df_temp = pd.read_table(f)
        df_list.append(df_temp)

    df = pd.concat(df_list, ignore_index=True)
    df["Sample_Name"] = df["Sample_Prefix"].map(sample_map)

    return df
    
def calculate_accuracy(tp, tn, total):
    accuracy = (tp + tn) / total
    return accuracy

def calculate_recall(tp, fn):
    recall = tp / (tp + fn)
    return recall

def calculate_fpr(fp, tn):
    fpr = fp / (fp + tn)
    return fpr

def calculate_f1(tp, fp, fn):
    f1 = 2 * (tp / (tp + fp)) * (tp / (tp + fn)) / ((tp / (tp + fp)) + (tp / (tp + fn)))
    return f1

def calculate_mcc(tp, tn, fp, fn, epsilon=1e-10):
    numerator = (tp * tn) - (fp * fn)
    denominator = np.sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn)) + epsilon
    mcc = numerator / denominator
    return mcc

def calculate_human_loss(fn, tp):
  # 1 - Recall
  human_loss = fn / (tp + fn)
  return human_loss

def calculate_contamination_rate(fp, tp):
    # fraction of mouse in predicted human reads
    contamination_rate = fp / (tp + fp)
    return contamination_rate

def calculate_mouse_leakage(fp, tn):
    # fraction of mouse reads incorrectly classified as human
    mouse_leakage = fp / (fp + tn)
    return mouse_leakage

def calculate_precision(tp, fp, epsilon=1e-10):
    # purity of positive predictions
    precision = tp / (tp + fp + epsilon)
    return precision

def calculate_weighted_score(contamination_rate, human_loss, weight1=0.7, weight2=0.3):
    score = (1 - contamination_rate) * weight1 + (1 - human_loss) * weight2
    return score


def assign_confusion_matrix(df, method):
    """
    Assign TP/TN/FP/FN columns based on tool-specific output columns.

    Parameters
    ----------
    df : pd.DataFrame   Raw evaluation dataframe from read_evaluations()
    method : str        One of 'xengsort', 'icrg', 'bamcmp', 'xenofilter'
    """
    df = df.copy()
    if method == "xengsort":
        df["TP"] = df["Human_Human"]
        df["TN"] = df["Mouse_Mouse"] + df["Amb_Mouse"] + df["Both_Mouse"] + df["Neither_Mouse"]
        df["FP"] = df["Human_Mouse"]
        df["FN"] = df["Mouse_Human"] + df["Amb_Human"] + df["Both_Human"] + df["Neither_Human"]
    elif method == "icrg":
        df["TP"] = df["Human_Human"]
        df["TN"] = df["Mouse_Mouse"] + df["Unmapped_Mouse"]
        df["FP"] = df["Human_Mouse"]
        df["FN"] = df["Mouse_Human"] + df["Unmapped_Human"]
    elif method == "bamcmp":
        df["TP"] = df["Human_Human"] + df["Amb_Human_Human"]
        df["TN"] = df["Mouse_Mouse"] + df["Amb_Mouse_Mouse"]
        df["FP"] = df["Human_Mouse"] + df["Amb_Human_Mouse"]
        df["FN"] = df["Mouse_Human"] + df["Amb_Mouse_Human"]
    elif method == "xenofilter":
        df["TP"] = df["Human_Human"] 
        df["TN"] = df["Mouse_Mouse"] 
        df["FP"] = df["Human_Mouse"] 
        df["FN"] = df["Mouse_Human"] 
    else:
        raise ValueError(f"Unknown method '{method}'. Choose from: xengsort, icrg, bamcmp, xenofilter")
    return df


def calculate_metrics(df, weight1=0.7, weight2=0.3):
    """
    Computes standard classification metrics, human loss, contamination
    and a weighted performance score.

    Returns a dataframe with original columns + Accuracy, Recall, FPR, Precision,
    F1, MCC, Human_Loss, Contamination_Rate, Mouse_Leakage, Human_Ratio, Score.
    """
    df = df.copy().reset_index(drop=True)

    # --- Standard metrics ---
    tp = df["TP"].astype(float)
    tn = df["TN"].astype(float)
    fp = df["FP"].astype(float)
    fn = df["FN"].astype(float)
    
    total = df["Total_Reads"]
    
    metrics = pd.DataFrame({
        "Accuracy": calculate_accuracy(tp=tp, tn=tn, total=total),
        "Recall": calculate_recall(tp=tp, fn=fn),
        "FPR": calculate_fpr(fp=fp, tn=tn),
        "Precision": calculate_precision(tp=tp, fp=fp),
        "F1": calculate_f1(tp=tp, fp=fp, fn=fn),
        "MCC": calculate_mcc(tp=tp, tn=tn, fp=fp, fn=fn),
        "Human_Loss" : calculate_human_loss(fn=fn, tp=tp),
        "Contamination_Rate" : calculate_contamination_rate(fp=fp, tp=tp),
        "Mouse_Leakage" : calculate_mouse_leakage(fp=fp, tn=tn)
    })
    # Combine original df with metrics
    df_metrics = pd.concat([df.reset_index(drop=True), metrics], axis=1)
    df_metrics["Human_Ratio"] = [(int(re.search(r"\d+", v).group()) / 100) for v in df["Mixture"]]
    df_metrics["Score"] = calculate_weighted_score(df_metrics["Contamination_Rate"], df_metrics["Human_Loss"], weight1=weight1, weight2=weight2)
    return df_metrics

def load_method(result_dir, method_name):
    files = sorted(result_dir.rglob("evaluation.tsv"))
    df = pd.concat([pd.read_table(f) for f in files], ignore_index=True)
    df["Method"] = method_name
    return df

def get_proportion(dfs_cats: dict, category_label: str):
    """
    dfs_cats: dict of {method_name: (df, [categories])}
    e.g. {"ICRG": (icrg, ["human"]), "Xengsort": (xengsort, ["graft"]), ...}
    """
    proportions = []
    for method, (df, cats) in dfs_cats.items():
        pivot = df.pivot_table(index="Sample", columns="Category", values="Reads", aggfunc="sum")
        pivot = pivot.div(pivot.sum(axis=1), axis=0)
        prop = pivot[cats].sum(axis=1).rename(method).reset_index()
        proportions.append(prop)
    
    combined = proportions[0]
    for p in proportions[1:]:
        combined = combined.merge(p, on="Sample")
    return combined.melt(id_vars="Sample", var_name="Method", value_name="Proportion")

def split_guillen_names(df, key="Sample"):
    df[key] = df[key].str.split("_").apply(lambda x: "_".join(x[0:2]))
    return(df)