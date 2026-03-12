"""Quick integration test for all modules"""
import numpy as np
import pandas as pd
from modules.ahp import calculate_weights, is_consistent
from modules.ml_model import create_binary_label, train_decision_tree, predict_proba_fail
from modules.risk_engine import calculate_ahp_score, calculate_final_score, classify_risk_level

# Test AHP
matrix = np.array([[1, 3, 5], [1/3, 1, 3], [1/5, 1/3, 1]])
weights, lmax, ci, cr = calculate_weights(matrix)
print(f"AHP: weights={np.round(weights, 3)}, CR={cr:.4f}, consistent={is_consistent(cr)}")

# Test ML
df = pd.read_excel("data/1k_Data điểm.xlsx")
df["fail_label"] = create_binary_label(df)
X = df[["Test_Score", "Attendance (%)", "Study_Hours"]]
y = df["fail_label"]
model, metrics, split = train_decision_tree(X, y, max_depth=5, min_samples_leaf=5)
acc = metrics["accuracy"]
f1 = metrics["f1"]
print(f"ML: accuracy={acc:.4f}, f1={f1:.4f}")

# Test Risk Engine
p_fail = predict_proba_fail(model, X)
ahp_score, _ = calculate_ahp_score(df, ["Test_Score", "Attendance (%)", "Study_Hours"], weights)
final = calculate_final_score(p_fail, ahp_score)
levels = classify_risk_level(final)
cao = sum(levels == "Cao")
tb = sum(levels == "Trung bình")
thap = sum(levels == "Thấp")
print(f"Risk: Cao={cao}, TB={tb}, Thap={thap}")
print("ALL TESTS PASSED!")
