import os
import glob
import pandas as pd
import re

def natural_sort_key(path):
    """
    Extract numeric lane value from a path like L1/Reports/Demultiplex_Stats.csv
    so sorting is L1, L2, L3, ... instead of L1, L10, L2
    """
    match = re.search(r"L(\d+)", path)
    return int(match.group(1)) if match else float("inf")

def concat_csv(pattern, output_file):
    # Look for files matching pattern in L*/Reports/
    csv_files = glob.glob(f"L*/Reports/{pattern}")
    csv_files.sort(key=natural_sort_key)

    if not csv_files:
        print(f"No {pattern} files found.")
        return

    print(f"Found {len(csv_files)} {pattern} files.")

    df_list = []
    for file in csv_files:
        df = pd.read_csv(file)
        df_list.append(df)
        print(f"Merged: {file} ({len(df)} rows)")

    combined = pd.concat(df_list, ignore_index=True)
    combined.to_csv(output_file, index=False)
    print(f"Combined file written to: {os.path.abspath(output_file)}")

if __name__ == "__main__":
    concat_csv("Demultiplex_Stats.csv", "Demultiplex_Stats.csv")
    concat_csv("Top_Unknown_Barcodes.csv", "Top_Unknown_Barcodes.csv")

df1 = pd.read_csv('Demultiplex_Stats.csv')
#df2 = pd.read_csv('Quality_Metrics.csv')
df3 = pd.read_csv('Top_Unknown_Barcodes.csv')

df1 = df1[['Lane', 'Sample_Project', 'Sample_Name', 'Index', '# Reads', '% Perfect Index Reads', '% One Mismatch Index Reads']]
#df2 = df2[['Lane', 'Sample_Project', 'Sample_Name', 'index', 'index2', 'ReadNumber', 'YieldQ30', 'Mean Quality Score (PF)', '% Q30']]
df3 = df3[['Lane', 'index', 'index2', '# Reads']]

# Format Total Reads in df1
df1.loc[:, "Total Reads"] = df1["# Reads"].map('{:,d}'.format)
df1a = df1.drop(["# Reads"], axis=1)
df1a = df1a[['Lane', 'Sample_Project', 'Sample_Name', 'Index', 'Total Reads', '% Perfect Index Reads', '% One Mismatch Index Reads']]

# Format Top Unknowns
df3.loc[:, "Total Reads"] = df3["# Reads"].map('{:,d}'.format)
df3a = df3.drop(["# Reads"], axis=1)
df3a = df3a[['Lane', 'index', 'index2', 'Total Reads']]

# Flowcell Summary Total
df4 = pd.DataFrame(df1['# Reads'])
df6 = df4
df6a = df6.sum().to_frame().T
df6a.loc[:, "Total Reads"] = df6a["# Reads"].map('{:,.0f}'.format)
df6b = df6a[["Total Reads"]]

# Total Reads Per Project
#project_reads = df1.groupby("Sample_Project")["# Reads"].sum().reset_index()
#project_reads["Total Reads"] = project_reads["# Reads"].map('{:,d}'.format)
#project_reads = project_reads.drop("# Reads", axis=1)

df_proj_sum = df1.groupby(['Sample_Project'], sort=False)['# Reads'].sum().reset_index()
df_proj_sum['Total Reads'] = df_proj_sum['# Reads'].map('{:,d}'.format)
df_proj_sum = df_proj_sum.drop(columns=['# Reads'])

# Count unique samples per project (ignores lanes)
sample_counts = df1.drop_duplicates(['Sample_Project', 'Sample_Name']) \
                   .groupby('Sample_Project')['Sample_Name'] \
                   .count().reset_index()
sample_counts = sample_counts.rename(columns={'Sample_Name': 'Total Samples'})

# Merge counts into project summary
df_proj_sum = df_proj_sum.merge(sample_counts, on='Sample_Project', how='left')

first_proj_order = df1.drop_duplicates('Sample_Project')[['Sample_Project']]
project_reads = first_proj_order.merge(df_proj_sum, on='Sample_Project', how='left')

# Total Reads Per Sample
sample_reads = df1.groupby(["Sample_Project", "Sample_Name"])["# Reads"].sum().reset_index()
sample_reads["Total Reads"] = sample_reads["# Reads"].map('{:,d}'.format)
sample_reads = sample_reads.drop("# Reads", axis=1)
sample_reads = sample_reads.sort_values("Sample_Project")

# Report titles
page_title_text = 'Demultiplexing Report'
Demul = 'Demultiplexing Statistics'
Unknowns = 'Top 10 Unknown Barcodes Per Lane'
Summary = 'Flowcell Summary'
ProjectSummary = 'Total Reads Per Project'
SampleSummary = 'Total Reads Per Sample'

#  HTML Report
html = f'''
    <html>
        <head>
            <title>{page_title_text}</title>
        </head>
        <body>
            <h1>{Summary}</h1>
            {df6b.to_html(index=False, justify='center')}
            <h2>{Demul}</h2>
            {df1a.to_html(index=False, justify='center')}
            <h2>{ProjectSummary}</h2>
            {project_reads.to_html(index=False, justify='center')}
            <h2>{SampleSummary}</h2>
            {sample_reads.to_html(index=False, justify='center')}
            <h2>{Unknowns}</h2>
            {df3a.to_html(index=False, justify='center')}
        </body>
    </html>
'''

#  Save HTML
with open('laneBarcode.html', 'w') as f:
    f.write(html)
