# This script compares the fields documented in a Markdown file (doc.md) with the fields
# defined in YAML files (used in dbt). It performs the following steps:
# 1. Extracts the column names from the `doc.md` file where fields are documented using `{% docs FIELD_NAME %}`.
# 2. Extracts the column names and their respective tables from all YAML files in the specified models directory.
# 3. Compares the two datasets and identifies:
#    - Columns documented in `doc.md` but not present in the YAML files.
#    - Columns present in the YAML files but not documented in `doc.md`.
# 4. Prints warnings if there are discrepancies or indicates if the documentation is consistent.

import re
import os
import yaml
import pandas as pd

# Parse the doc.md file
def extract_docs_from_md(md_file):
    with open(md_file, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Use regex to find all occurrences of `{% docs FIELD_NAME %}`
    documented_fields = re.findall(r"{% docs (\w+) %}", content)
    
    df = pd.DataFrame(documented_fields, columns=["doc_column_name"])
    return df

# Parse all .yml file(s)
import os
import yaml
import pandas as pd

def extract_fields_from_yaml(models_dir):
    data = []  # Store extracted data

    for root, dirs, files in os.walk(models_dir):
        # print(f"Checking directory: {root}")
        for file in files:
            if file.endswith((".yml", ".yaml")):
                yaml_path = os.path.join(root, file)
                # print(f"Found YAML file: {yaml_path}")
                
                with open(yaml_path, "r", encoding="utf-8") as f:
                    try:
                        content = yaml.safe_load(f)  # Load YAML
                        if content and isinstance(content, dict):
                            # Handle "sources" structure
                            if "sources" in content:
                                for source in content["sources"]:
                                    if "tables" in source:
                                        for table in source["tables"]:
                                            table_name = table["name"]
                                            
                                            if "columns" in table:
                                                for column in table["columns"]:
                                                    column_name = column["name"]
                                                    data.append({"yaml_table_name": table_name, 
                                                                  "yaml_column_name": column_name,
                                                                  "yaml_repository": root})
                            
                            # Handle "models" structure (if applicable)
                            if "models" in content:
                                for model in content["models"]:
                                    if "columns" in model:
                                        for column in model["columns"]:
                                            model_name = model["name"]
                                            column_name = column["name"]
                                            data.append({"yaml_table_name": model_name, 
                                                          "yaml_column_name": column_name,
                                                          "yaml_repository": root})
                    except yaml.YAMLError as e:
                        print(f"⚠️ Error parsing {yaml_path}: {e}")
    
    df = pd.DataFrame(data)
    return df

MODELS_DIR = "models"
yaml_fields = extract_fields_from_yaml(MODELS_DIR)
DOCS_FILE = "models/doc.md"
doc_fields = extract_docs_from_md(DOCS_FILE)

# Compare the two dataframes
gap_analysis = pd.merge(doc_fields, yaml_fields, how='outer', left_on='doc_column_name', right_on='yaml_column_name')

# Get the columns without match
missing_yaml_columns = gap_analysis[gap_analysis['yaml_column_name'].isnull()]
missing_doc_columns = gap_analysis[gap_analysis['doc_column_name'].isnull()]

# Print a warning if there are any missing matches
if not missing_yaml_columns.empty:
    print("⚠️ Warning: There are columns in the docs that are missing in the YAML files:")
    print(missing_yaml_columns)

if not missing_doc_columns.empty:
    print("⚠️ Warning: There are columns in the YAML files that are missing in the docs:")
    print(missing_doc_columns)

if missing_yaml_columns.empty and missing_doc_columns.empty:
    print("✅ The documentation is consistent")