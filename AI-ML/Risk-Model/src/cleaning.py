import pandas as pd


TARGET_COLUMN = "Risk_Level"


def clean_risk_dataset(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Remove rows without target
    df = df.dropna(subset=[TARGET_COLUMN])

    # Clean target labels
    df[TARGET_COLUMN] = (
        df[TARGET_COLUMN]
        .astype(str)
        .str.strip()
        .str.title()
    )

    # Remove duplicate rows
    df = df.drop_duplicates()

    print("\n=== CLEANING ===")
    print(f"Rows after cleaning: {len(df)}")
    print(f"Columns: {len(df.columns)}")
    print(f"Duplicates: {df.duplicated().sum()}")

    print("\n=== TARGET DISTRIBUTION ===")
    print(df[TARGET_COLUMN].value_counts())

    print("\n=== MISSING VALUES ===")
    missing = df.isnull().sum()
    missing = missing[missing > 0].sort_values(ascending=False)

    if len(missing) > 0:
        print(missing)
    else:
        print("No missing values.")

    return df