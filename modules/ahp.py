"""
Module AHP (Analytic Hierarchy Process)
Tinh toan trong so tieu chi theo phuong phap AHP - Thang Saaty 1-9
"""
import numpy as np

# Bang chi so ngau nhien RI (Saaty, 1980)
RI_TABLE = {
    1: 0.0, 2: 0.0, 3: 0.58, 4: 0.90, 5: 1.12,
    6: 1.24, 7: 1.32, 8: 1.41, 9: 1.45, 10: 1.49
}

SAATY_SCALE = {
    1: "Quan trong bang nhau",
    2: "Giua 1 va 3",
    3: "Quan trong hon vua phai",
    4: "Giua 3 va 5",
    5: "Quan trong hon nhieu",
    6: "Giua 5 va 7",
    7: "Rat quan trong hon",
    8: "Giua 7 va 9",
    9: "Cuc ky quan trong hon",
}

SAATY_VALUES = [1/9, 1/8, 1/7, 1/6, 1/5, 1/4, 1/3, 1/2,
                1, 2, 3, 4, 5, 6, 7, 8, 9]

SAATY_LABELS = [
    "1/9", "1/8", "1/7", "1/6", "1/5", "1/4", "1/3", "1/2",
    "1", "2", "3", "4", "5", "6", "7", "8", "9"
]


def calculate_weights(matrix):
    """
    Tinh trong so uu tien tu ma tran so sanh cap.
    Su dung phuong phap eigenvector (vector rieng) theo Saaty.

    Parameters:
        matrix: numpy array (n x n) - Ma tran so sanh cap

    Returns:
        weights: numpy array - Trong so cac tieu chi
        lambda_max: float - Gia tri rieng lon nhat
        ci: float - Chi so nhat quan (Consistency Index)
        cr: float - Ty so nhat quan (Consistency Ratio)
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
    """Kiem tra CR <= threshold"""
    return cr <= threshold


def create_default_matrix(n):
    """Tao ma tran don vi nxn (tat ca tieu chi bang nhau)"""
    return np.ones((n, n))


def get_ri(n):
    """Lay Random Index cho n tieu chi"""
    return RI_TABLE.get(n, 1.49)
