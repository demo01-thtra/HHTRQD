"""
Module AHP (Analytic Hierarchy Process)
Tính toán trọng số tiêu chí theo phương pháp AHP - Thang Saaty 1-9
"""
import numpy as np

# Bảng chỉ số ngẫu nhiên RI (Saaty, 1980)
RI_TABLE = {
    1: 0.0, 2: 0.0, 3: 0.58, 4: 0.90, 5: 1.12,
    6: 1.24, 7: 1.32, 8: 1.41, 9: 1.45, 10: 1.49
}

SAATY_SCALE = {
    1: "Quan trọng bằng nhau",
    2: "Giữa 1 và 3",
    3: "Quan trọng hơn vừa phải",
    4: "Giữa 3 và 5",
    5: "Quan trọng hơn nhiều",
    6: "Giữa 5 và 7",
    7: "Rất quan trọng hơn",
    8: "Giữa 7 và 9",
    9: "Cực kỳ quan trọng hơn",
}

SAATY_VALUES = [1/9, 1/8, 1/7, 1/6, 1/5, 1/4, 1/3, 1/2,
                1, 2, 3, 4, 5, 6, 7, 8, 9]

SAATY_LABELS = [
    "1/9", "1/8", "1/7", "1/6", "1/5", "1/4", "1/3", "1/2",
    "1", "2", "3", "4", "5", "6", "7", "8", "9"
]


def calculate_weights(matrix):
    """
    Tính trọng số ưu tiên từ ma trận so sánh cặp.
    Sử dụng phương pháp eigenvector (vector riêng) theo Saaty.

    Parameters:
        matrix: numpy array (n x n) - Ma trận so sánh cặp

    Returns:
        weights: numpy array - Trọng số các tiêu chí
        lambda_max: float - Giá trị riêng lớn nhất
        ci: float - Chỉ số nhất quán (Consistency Index)
        cr: float - Tỷ số nhất quán (Consistency Ratio)
    """
    n = matrix.shape[0]

    eigenvalues, eigenvectors = np.linalg.eig(matrix)
    max_idx = np.argmax(np.abs(eigenvalues.real))
    lambda_max = eigenvalues[max_idx].real

    weights = np.abs(eigenvectors[:, max_idx].real)
    weights = weights / weights.sum()

    ci = (lambda_max - n) / (n - 1) if n > 1 else 0.0

    ri = RI_TABLE.get(n, 1.49)
    cr = ci / ri if ri > 0 else 0.0

    return weights, float(lambda_max), float(ci), float(cr)


def is_consistent(cr, threshold=0.10):
    """Kiểm tra CR ≤ threshold"""
    return cr <= threshold


def create_default_matrix(n):
    """Tạo ma trận đơn vị n×n (tất cả tiêu chí bằng nhau)"""
    return np.ones((n, n))


def get_ri(n):
    """Lấy Random Index cho n tiêu chí"""
    return RI_TABLE.get(n, 1.49)
