using System.Text;
using System.Text.Json;

namespace DSSStudentRisk.Service;
public class RiskService
{
    private readonly HttpClient _httpClient;
    private const string AI_SERVER_URL = "http://localhost:5001/api/ai/predict";

    public RiskService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    /// <summary>
    /// Gọi AI Server để tính risk dùng AHP
    /// final_score = AHP_score (pure AHP)
    /// </summary>
    public async Task<(double finalScore, double pFail, double ahpScore, string riskLevel)> CalculateRiskWithAI(
        double testScore, double attendance, double studyHours,
        double wTest, double wAttendance, double wStudy)
    {
        var payload = new
        {
            testScore = testScore,
            attendance = attendance,
            studyHours = studyHours,
            alpha = 0.0,
            ahpWeights = new
            {
                testWeight = wTest,
                attendanceWeight = wAttendance,
                studyWeight = wStudy
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        var response = await _httpClient.PostAsync(AI_SERVER_URL, content);

        if (!response.IsSuccessStatusCode)
            throw new Exception("AI Server không phản hồi");

        var body = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        return (
            finalScore: root.GetProperty("finalScore").GetDouble(),
            pFail: root.GetProperty("pFail").GetDouble(),
            ahpScore: root.GetProperty("ahpScore").GetDouble(),
            riskLevel: root.GetProperty("riskLevel").GetString() ?? "Unknown"
        );
    }

    /// <summary>
    /// Fallback: chỉ dùng AHP nếu AI Server không chạy
    /// </summary>
    public double CalculateRiskAHPOnly(
        double test, double attendance, double study,
        double wTest, double wAttendance, double wStudy)
    {
        test = Math.Clamp(test, 0, 10);
        attendance = Math.Clamp(attendance, 0, 100);
        study = Math.Clamp(study, 0, 12);
        double rTest = 1 - (test / 10.0);
        double rAttendance = 1 - (attendance / 100.0);
        double rStudy = 1 - (study / 12.0);
        return (rTest * wTest) + (rAttendance * wAttendance) + (rStudy * wStudy);
    }

    public string GetLevel(double score)
    {
        if (score >= 0.61)
            return "High Risk";
        else if (score >= 0.31)
            return "Medium Risk";
        else
            return "Low Risk";
    }
}