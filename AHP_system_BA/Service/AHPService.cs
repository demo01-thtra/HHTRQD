namespace DSSStudentRisk.Service;

public class AhpDetailedCalculation
{
    public double[][] Matrix { get; set; } = [];
    public double[] ColumnSum { get; set; } = [];
    public double[][] NormalizedMatrix { get; set; } = [];
    public double[] Weights { get; set; } = [];
    public double[] AxW { get; set; } = [];
    public double[] LambdaI { get; set; } = [];
    public double LambdaMax { get; set; }
    public double CI { get; set; }
    public double RI { get; set; }
    public double CR { get; set; }
    public string[] CriteriaNames { get; set; } = [];
    public int[] Ranking { get; set; } = [];
}

public class AHPService
{

    public (double test, double attendance, double study, double cr)
        Calculate(double ta, double ts, double as_)
    {
        var detail = CalculateDetailed(ta, ts, as_, ["Test", "Attendance", "Study"]);
        return (detail.Weights[0], detail.Weights[1], detail.Weights[2], detail.CR);
    }

    public AhpDetailedCalculation CalculateDetailed(double ta, double ts, double as_, string[] criteriaNames)
    {
        int n = 3;

        double[][] matrix =
        [
            [1, ta, ts],
            [1.0/ta, 1, as_],
            [1.0/ts, 1.0/as_, 1]
        ];

        // Tổng cột
        double[] colSum = new double[n];
        for (int j = 0; j < n; j++)
            for (int i = 0; i < n; i++)
                colSum[j] += matrix[i][j];

        // Ma trận chuẩn hóa
        double[][] norm = new double[n][];
        for (int i = 0; i < n; i++)
        {
            norm[i] = new double[n];
            for (int j = 0; j < n; j++)
                norm[i][j] = matrix[i][j] / colSum[j];
        }

        // Trọng số (trung bình hàng)
        double[] weight = new double[n];
        for (int i = 0; i < n; i++)
        {
            for (int j = 0; j < n; j++)
                weight[i] += norm[i][j];
            weight[i] /= n;
        }

        // A × W
        double[] axw = new double[n];
        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++)
                axw[i] += matrix[i][j] * weight[j];

        // λ_i
        double[] lambdaI = new double[n];
        for (int i = 0; i < n; i++)
            lambdaI[i] = axw[i] / weight[i];

        // λ_max
        double lambdaMax = lambdaI.Average();

        double CI = (lambdaMax - n) / (n - 1);
        double RI = 0.58;
        double CR = RI > 0 ? CI / RI : 0;

        // Xếp hạng
        int[] ranking = new int[n];
        var indexed = weight.Select((w, i) => new { w, i }).OrderByDescending(x => x.w).ToArray();
        for (int r = 0; r < n; r++)
            ranking[indexed[r].i] = r + 1;

        return new AhpDetailedCalculation
        {
            Matrix = matrix,
            ColumnSum = colSum,
            NormalizedMatrix = norm,
            Weights = weight,
            AxW = axw,
            LambdaI = lambdaI,
            LambdaMax = lambdaMax,
            CI = CI,
            RI = RI,
            CR = CR,
            CriteriaNames = criteriaNames,
            Ranking = ranking
        };
    }

//Bước 6: Tính độ ưu tiên của các phương án theo từng tiêu chí. 
    public AhpMatrixResult CalculateMatrix(string criteria,double[][] matrix)
    {
        int n = matrix.Length;

        double[] columnSum = new double[n];

        for(int j=0;j<n;j++)
        {
            for(int i=0;i<n;i++)
            {
                columnSum[j]+=matrix[i][j];
            }
        }

        double[][] normalized=new double[n][];

        for(int i=0;i<n;i++)
        {
            normalized[i]=new double[n];

            for(int j=0;j<n;j++)
            {
                normalized[i][j]=matrix[i][j]/columnSum[j];
            }
        }

        double[] weights=new double[n];

        for(int i=0;i<n;i++)
        {
            double sum=0;

            for(int j=0;j<n;j++)
            {
                sum+=normalized[i][j];
            }

            weights[i]=sum/n;
        }

        return new AhpMatrixResult
        {
            Criteria=criteria,
            ColumnSum=columnSum,
            NormalizedMatrix=normalized,
            Weights=weights
        };
    }
}