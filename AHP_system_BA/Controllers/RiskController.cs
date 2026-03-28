using DSSStudentRisk.Data;
using DSSStudentRisk.Models;
using DSSStudentRisk.Service;
using Microsoft.AspNetCore.Mvc;
namespace DSSStudentRisk.Controllers;
[ApiController]
[Route("api/risk")]
public class RiskController : ControllerBase
{

    private readonly AppDbContext _context;
    private readonly RiskService _risk;

    public RiskController(AppDbContext context, RiskService risk)
    {
        _context = context;
        _risk = risk;
    }

    [HttpPost("{studentId}")]
    public async Task<IActionResult> Calculate(int studentId)
    {
       var perf = _context.StudentPerformances
            .Where(x => x.StudentId == studentId)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (perf == null)
            return NotFound("Student performance not found");

        var criteria = _context.AHPCriteria
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (criteria == null)
            return BadRequest("No active AHP criteria");

        // Gọi AI Server: kết hợp AHP + Decision Tree
        try
        {
            var (finalScore, pFail, ahpScore, riskLevel) = await _risk.CalculateRiskWithAI(
                perf.TestScore, perf.Attendance, perf.StudyHours,
                criteria.TestWeight, criteria.AttendanceWeight, criteria.StudyWeight);

            var result = new RiskResult
            {
                StudentId = studentId,
                RiskScore = finalScore,
                RiskLevel = riskLevel,
                CalculatedDate = DateTime.Now
            };

            var existing = _context.RiskResults.FirstOrDefault(r => r.StudentId == studentId);
            if (existing != null)
            {
                existing.RiskScore = finalScore;
                existing.RiskLevel = riskLevel;
                existing.CalculatedDate = DateTime.Now;
            }
            else
            {
                _context.RiskResults.Add(result);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                studentId = studentId,
                riskScore = finalScore,
                riskLevel = riskLevel,
                pFail = pFail,
                ahpScore = ahpScore,
                method = "AHP + Decision Tree",
                calculatedDate = DateTime.Now
            });
        }
        catch
        {
            // Fallback: chỉ dùng AHP nếu AI Server không chạy
            var final_ = _context.AHPFinalResults
                .OrderByDescending(x => x.CreatedDate)
                .FirstOrDefault();
            if (final_ == null)
                return BadRequest("AHP final result not calculated");

            double score = _risk.CalculateRiskAHPOnly(
                perf.TestScore, perf.Attendance, perf.StudyHours,
                criteria.TestWeight, criteria.AttendanceWeight, criteria.StudyWeight);

            string level = _risk.GetLevel(score);

            var result = new RiskResult
            {
                StudentId = studentId,
                RiskScore = score,
                RiskLevel = level,
                CalculatedDate = DateTime.Now
            };

            var existing = _context.RiskResults.FirstOrDefault(r => r.StudentId == studentId);
            if (existing != null)
            {
                existing.RiskScore = score;
                existing.RiskLevel = level;
                existing.CalculatedDate = DateTime.Now;
            }
            else
            {
                _context.RiskResults.Add(result);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                studentId = studentId,
                riskScore = score,
                riskLevel = level,
                pFail = 0.0,
                ahpScore = score,
                method = "AHP Only (AI Server offline)",
                calculatedDate = DateTime.Now
            });
        }
    }
    [HttpPost("calculate-all")]
    public async Task<IActionResult> CalculateAll()
    {
        var criteria = _context.AHPCriteria
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (criteria == null)
            return BadRequest("Chưa có trọng số AHP");

        var performances = _context.StudentPerformances
            .GroupBy(p => p.StudentId)
            .Select(g => g.OrderByDescending(p => p.CreatedDate).First())
            .ToList();

        int added = 0, updated = 0;
        bool usedAI = true;

        foreach (var perf in performances)
        {
            double newScore;
            string newLevel;

            try
            {
                var (finalScore, pFail, ahpScore, riskLevel) = await _risk.CalculateRiskWithAI(
                    perf.TestScore, perf.Attendance, perf.StudyHours,
                    criteria.TestWeight, criteria.AttendanceWeight, criteria.StudyWeight);
                newScore = finalScore;
                newLevel = riskLevel;
            }
            catch
            {
                // Fallback: chỉ dùng AHP
                usedAI = false;
                var final_ = _context.AHPFinalResults
                    .OrderByDescending(x => x.CreatedDate)
                    .FirstOrDefault();
                if (final_ == null)
                    return BadRequest("AHP final result not calculated");

                newScore = _risk.CalculateRiskAHPOnly(
                    perf.TestScore, perf.Attendance, perf.StudyHours,
                    criteria.TestWeight, criteria.AttendanceWeight, criteria.StudyWeight);
                newLevel = _risk.GetLevel(newScore);
            }

            var existing = _context.RiskResults
                .FirstOrDefault(r => r.StudentId == perf.StudentId);

            if (existing == null)
            {
                var result = new RiskResult
                {
                    StudentId = perf.StudentId,
                    RiskScore = newScore,
                    RiskLevel = newLevel,
                    CalculatedDate = DateTime.Now
                };
                _context.RiskResults.Add(result);
                added++;
            }
            else
            {
                existing.RiskScore = newScore;
                existing.RiskLevel = newLevel;
                existing.CalculatedDate = DateTime.Now;
                updated++;
            }
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = usedAI
                ? "Calculated risk with AHP + Decision Tree"
                : "Calculated risk with AHP Only (AI Server offline)",
            added,
            updated,
            total = performances.Count
        });
    }
 
    [HttpGet("results")]    public IActionResult GetResults()
    {
        var results = _context.RiskResults
            .AsEnumerable()
            .GroupBy(x => x.StudentId)
            .Select(g => g.OrderByDescending(x => x.CalculatedDate).First())
            .OrderByDescending(x => x.RiskScore)
            .ToList();
        return Ok(results);
    }
  [HttpGet("top-risk")]
    public IActionResult GetTop10Risk()
    {
        var results = _context.RiskResults
            .OrderByDescending(x => x.RiskScore)
            .Take(10)
            .ToList();

        return Ok(results);
    }
    [HttpGet("summary")]
    public IActionResult GetRiskSummary()
    {
        var latestResults=_context.RiskResults
        .GroupBy(x=>x.StudentId)
        .Select(g=>g.OrderByDescending(x=>x.CalculatedDate).First()).ToList();
        var summary=new
        {
            low=latestResults.Count(x=>x.RiskLevel=="Low Risk"),
             medium = latestResults.Count(x => x.RiskLevel == "Medium Risk"),
        high = latestResults.Count(x => x.RiskLevel == "High Risk"),
        total = latestResults.Count
        };
        return Ok(summary);
    }
}