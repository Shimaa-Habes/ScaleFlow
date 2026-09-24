import pandas as pd


TARGET_COLUMN = "Risk_Level"
ID_COLUMNS = ["Project_ID"]


def prepare_features(df: pd.DataFrame):
    df = df.copy()

    # Target
    y = df[TARGET_COLUMN].copy()

    # Remove target and ID columns from features
    columns_to_drop = [TARGET_COLUMN] + ID_COLUMNS

    X = df.drop(columns=columns_to_drop, errors="ignore")

    print("\n=== FEATURE PREPARATION ===")
    print(f"Feature matrix shape: {X.shape}")
    print(f"Target shape: {y.shape}")

    print("\n=== NUMERIC FEATURES ===")
    numeric_features = X.select_dtypes(include=["number"]).columns.tolist()
    print(f"Count: {len(numeric_features)}")
    print(numeric_features)

    print("\n=== CATEGORICAL FEATURES ===")
    categorical_features = X.select_dtypes(
        include=["object", "string", "category"]
    ).columns.tolist()
    print(f"Count: {len(categorical_features)}")
    print(categorical_features)

    print("\n=== TARGET CLASSES ===")
    print(y.value_counts())

    return X, y