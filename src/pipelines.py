"""
pipelines.py
------------
Step 5: build the sklearn preprocessing + model pipelines.

Two flavors of preprocessing are provided because different models expect
different input shapes:
 - "sparse" pipeline: keeps the text as a big sparse TF-IDF matrix.
   Fast and works great for linear models (Logistic Regression, Linear SVM).
 - "dense" pipeline: reduces the text down to a small number of dense
   components with SVD (like a lightweight PCA for text). Needed for
   tree-based models and neural nets, which don't handle huge sparse
   matrices well.
"""

from sklearn.compose import ColumnTransformer
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from .config import CACHE_DIR
from .features import NUMERIC_FEATURES


def sparse_preprocessor():
    """ColumnTransformer that keeps everything as a sparse matrix (TF-IDF text)."""
    return ColumnTransformer(
        [
            # TF-IDF on 1-word and 2-word phrases ("unigrams + bigrams"), capped at 20k features.
            # sublinear_tf softens the effect of very frequent words (uses log scaling).
            ("text", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=20000, sublinear_tf=True, stop_words="english"), "text"),
            # token_pattern=r"[^ ]+" treats each space-separated label as one whole token
            # (so "hr" and "kicker" are separate tokens, not split into letters).
            ("labels", TfidfVectorizer(token_pattern=r"[^ ]+", min_df=1), "labels_clean"),
            ("priority", OneHotEncoder(handle_unknown="ignore"), ["Priority"]),
            ("numeric", StandardScaler(), NUMERIC_FEATURES),
        ]
    )


def dense_preprocessor(svd_components=80):
    """ColumnTransformer that produces a dense matrix (text compressed via SVD)."""
    return ColumnTransformer(
        [
            (
                "text",
                Pipeline(
                    [
                        ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=6000, sublinear_tf=True, stop_words="english")),
                        # TruncatedSVD compresses thousands of TF-IDF columns down to `svd_components`
                        # dense columns - like PCA, but works directly on sparse text matrices.
                        ("svd", TruncatedSVD(svd_components, random_state=42)),
                    ]
                ),
                "text",
            ),
            ("labels", CountVectorizer(token_pattern=r"[^ ]+", min_df=3, binary=True), "labels_clean"),
            ("priority", OneHotEncoder(handle_unknown="ignore", sparse_output=False), ["Priority"]),
            ("numeric", "passthrough", NUMERIC_FEATURES),  # already numeric, no transformation needed
        ],
        sparse_threshold=0,  # force a fully dense output matrix
    )


def sparse_pipeline(model):
    """Full pipeline: sparse preprocessing + a model. `memory=` caches the
    preprocessing step to disk so re-fitting the same data is faster."""
    return Pipeline([("prep", sparse_preprocessor()), ("model", model)], memory=str(CACHE_DIR))


def dense_pipeline(model, scale=False):
    """Full pipeline: dense preprocessing + optional scaling + a model."""
    steps = [("prep", dense_preprocessor())]
    if scale:
        steps.append(("scale", StandardScaler()))
    steps.append(("model", model))
    return Pipeline(steps, memory=str(CACHE_DIR))
