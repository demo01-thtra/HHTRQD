using DSSStudentRisk.Data;
using DSSStudentRisk.Models;
using DSSStudentRisk.Service;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace DSSStudentRisk.Controllers;

[ApiController]
[Route("api/ahp")]
public class AHPController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly AHPService _ahp;

    public AHPController(AppDbContext context, AHPService ahp)
    {
        _context = context;
        _ahp = ahp;
    }

   
    [HttpPost]
    public async Task<IActionResult> Create(AHPCriteria input)
    {
        var result = _ahp.Calculate(
            input.Test_Attendance,
            input.Test_Study,
            input.Attendance_Study
        );

        if (!IsValid(result.test) ||
            !IsValid(result.attendance) ||
            !IsValid(result.study) ||
            !IsValid(result.cr))
        {
            return BadRequest("Invalid AHP result");
        }

        input.TestWeight = result.test;
        input.AttendanceWeight = result.attendance;
        input.StudyWeight = result.study;
        input.ConsistencyRatio = result.cr;
        input.IsActive = true;
        input.CreatedDate = DateTime.Now;

        // Tắt tất cả bản ghi cũ trước khi thêm mới
        var oldCriteria = _context.AHPCriteria.Where(x => x.IsActive).ToList();
        var oldActiveId = oldCriteria.OrderByDescending(x => x.CreatedDate).FirstOrDefault()?.Id;

        foreach (var old in oldCriteria)
            old.IsActive = false;

        _context.AHPCriteria.Add(input);
        await _context.SaveChangesAsync();

        // Copy alternative weights & matrices từ criteria cũ sang criteria mới
        if (oldActiveId.HasValue)
        {
            var oldAlternatives = _context.AHPAlternativeWeights
                .Where(x => x.AHPCriteriaId == oldActiveId.Value).ToList();
            foreach (var alt in oldAlternatives)
            {
                _context.AHPAlternativeWeights.Add(new AHPAlternativeWeight
                {
                    CriteriaName = alt.CriteriaName,
                    A1 = alt.A1,
                    A2 = alt.A2,
                    A3 = alt.A3,
                    AHPCriteriaId = input.Id,
                    CreatedDate = DateTime.Now
                });
            }

            var oldMatrices = _context.AHPMatrices
                .Where(x => x.AHPCriteriaId == oldActiveId.Value).ToList();
            foreach (var mat in oldMatrices)
            {
                _context.AHPMatrices.Add(new AHPMatrix
                {
                    CriteriaName = mat.CriteriaName,
                    MatrixJson = mat.MatrixJson,
                    AHPCriteriaId = input.Id,
                    CreatedDate = DateTime.Now
                });
            }

            // Tính lại final result cho criteria mới
            var test = oldAlternatives.FirstOrDefault(x => x.CriteriaName == "TestScore");
            var att = oldAlternatives.FirstOrDefault(x => x.CriteriaName == "Attendance");
            var study = oldAlternatives.FirstOrDefault(x => x.CriteriaName == "StudyHours");
            if (test != null && att != null && study != null)
            {
                double a1 = test.A1 * input.TestWeight + att.A1 * input.AttendanceWeight + study.A1 * input.StudyWeight;
                double a2 = test.A2 * input.TestWeight + att.A2 * input.AttendanceWeight + study.A2 * input.StudyWeight;
                double a3 = test.A3 * input.TestWeight + att.A3 * input.AttendanceWeight + study.A3 * input.StudyWeight;
                string best = "A1"; double max = a1;
                if (a2 > max) { max = a2; best = "A2"; }
                if (a3 > max) { max = a3; best = "A3"; }

                _context.AHPFinalResults.Add(new AhpFinalResult
                {
                    A1 = a1, A2 = a2, A3 = a3,
                    BestAlternative = best,
                    AHPCriteriaId = input.Id,
                    CreatedDate = DateTime.Now
                });
            }

            await _context.SaveChangesAsync();
        }

        return Ok(new
        {
            success = result.cr < 0.1,
            data = input
        });
    }

    // ================== CALCULATE CRITERIA MATRIX ==================
    [HttpPost("criteria")]
    public async Task<IActionResult> CalculateCriteria(AhpMatrixRequest request)
    {
        var result = _ahp.CalculateMatrix(request.CriteriaName, request.Matrix);

        var criteria = _context.AHPCriteria
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (criteria == null)
            return BadRequest("No active criteria");

        // Check existing matrix → update nếu đã có
        var existingMatrix = _context.AHPMatrices
            .FirstOrDefault(x => x.AHPCriteriaId == criteria.Id && x.CriteriaName == request.CriteriaName);

        if (existingMatrix != null)
        {
            existingMatrix.MatrixJson = JsonSerializer.Serialize(request.Matrix);
            existingMatrix.CreatedDate = DateTime.Now;
        }
        else
        {
            var matrixEntity = new AHPMatrix
            {
                CriteriaName = request.CriteriaName,
                MatrixJson = JsonSerializer.Serialize(request.Matrix),
                AHPCriteriaId = criteria.Id,
                CreatedDate = DateTime.Now
            };
            _context.AHPMatrices.Add(matrixEntity);
        }

        await _context.SaveChangesAsync();
        return Ok(result);
    }

    // ================== CALCULATE ALTERNATIVE WEIGHTS ==================
    [HttpPost("alternative")]
    public async Task<IActionResult> CalculateAlternative(AhpMatrixRequest request)
    {
        var result = _ahp.CalculateMatrix(request.CriteriaName, request.Matrix);

        var criteria = _context.AHPCriteria
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (criteria == null)
            return BadRequest("No active criteria");

        // Check existing alternative weight → update nếu đã có
        var existingAlt = _context.AHPAlternativeWeights
            .FirstOrDefault(x => x.AHPCriteriaId == criteria.Id && x.CriteriaName == request.CriteriaName);

        if (existingAlt != null)
        {
            existingAlt.A1 = result.Weights[0];
            existingAlt.A2 = result.Weights[1];
            existingAlt.A3 = result.Weights[2];
            existingAlt.CreatedDate = DateTime.Now;
        }
        else
        {
            var altEntity = new AHPAlternativeWeight
            {
                CriteriaName = request.CriteriaName,
                A1 = result.Weights[0],
                A2 = result.Weights[1],
                A3 = result.Weights[2],
                AHPCriteriaId = criteria.Id,
                CreatedDate = DateTime.Now
            };
            _context.AHPAlternativeWeights.Add(altEntity);
        }

        // Also save the matrix
        var existingMatrix = _context.AHPMatrices
            .FirstOrDefault(x => x.AHPCriteriaId == criteria.Id && x.CriteriaName == request.CriteriaName);

        if (existingMatrix != null)
        {
            existingMatrix.MatrixJson = JsonSerializer.Serialize(request.Matrix);
            existingMatrix.CreatedDate = DateTime.Now;
        }
        else
        {
            var matrixEntity = new AHPMatrix
            {
                CriteriaName = request.CriteriaName,
                MatrixJson = JsonSerializer.Serialize(request.Matrix),
                AHPCriteriaId = criteria.Id,
                CreatedDate = DateTime.Now
            };
            _context.AHPMatrices.Add(matrixEntity);
        }

        await _context.SaveChangesAsync();
        return Ok(result);
    }

    // ================== CALCULATE FINAL RESULT ==================
    [HttpGet("final")]
    public async Task<IActionResult> FinalResult()
    {
        var criteria = _context.AHPCriteria
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (criteria == null)
            return BadRequest("No criteria");

        var test = _context.AHPAlternativeWeights
            .FirstOrDefault(x => x.CriteriaName == "TestScore" && x.AHPCriteriaId == criteria.Id);
        var att = _context.AHPAlternativeWeights
            .FirstOrDefault(x => x.CriteriaName == "Attendance" && x.AHPCriteriaId == criteria.Id);
        var study = _context.AHPAlternativeWeights
            .FirstOrDefault(x => x.CriteriaName == "StudyHours" && x.AHPCriteriaId == criteria.Id);

        if (test == null || att == null || study == null)
            return BadRequest("Missing alternative weights");

        double a1 = test.A1 * criteria.TestWeight +
                    att.A1 * criteria.AttendanceWeight +
                    study.A1 * criteria.StudyWeight;

        double a2 = test.A2 * criteria.TestWeight +
                    att.A2 * criteria.AttendanceWeight +
                    study.A2 * criteria.StudyWeight;

        double a3 = test.A3 * criteria.TestWeight +
                    att.A3 * criteria.AttendanceWeight +
                    study.A3 * criteria.StudyWeight;

        string best = "A1";
        double max = a1;
        if (a2 > max) { max = a2; best = "A2"; }
        if (a3 > max) { max = a3; best = "A3"; }

        var existing = _context.AHPFinalResults
            .FirstOrDefault(x => x.AHPCriteriaId == criteria.Id);

        if (existing != null)
        {
            existing.A1 = a1;
            existing.A2 = a2;
            existing.A3 = a3;
            existing.BestAlternative = best;
            existing.CreatedDate = DateTime.Now;
        }
        else
        {
            var final = new AhpFinalResult
            {
                A1 = a1,
                A2 = a2,
                A3 = a3,
                BestAlternative = best,
                AHPCriteriaId = criteria.Id,
                CreatedDate = DateTime.Now
            };
            _context.AHPFinalResults.Add(final);
        }

        await _context.SaveChangesAsync();

        return Ok(new { a1, a2, a3, best });
    }

    // ================== GET FULL REPORT ==================
    [HttpGet("report")]
    public IActionResult GetFullReport()
    {
        var criteria = _context.AHPCriteria
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedDate)
            .FirstOrDefault();
        if (criteria == null)
            return BadRequest("No criteria");

        // Tính lại chi tiết AHP cho ma trận tiêu chí
        var detail = _ahp.CalculateDetailed(
            criteria.Test_Attendance,
            criteria.Test_Study,
            criteria.Attendance_Study,
            ["Test", "Attendance", "Study"]
        );

        var matrices = _context.AHPMatrices
            .Where(x => x.AHPCriteriaId == criteria.Id)
            .GroupBy(x => x.CriteriaName)
            .Select(g => g.OrderByDescending(x => x.CreatedDate).First())
            .ToList();

        var alternatives = _context.AHPAlternativeWeights
            .Where(x => x.AHPCriteriaId == criteria.Id)
            .GroupBy(x => x.CriteriaName)
            .Select(g => g.OrderByDescending(x => x.CreatedDate).First())
            .ToList();

        var final_ = _context.AHPFinalResults
            .FirstOrDefault(x => x.AHPCriteriaId == criteria.Id);

        return Ok(new
        {
            // Chi tiết tính toán AHP
            criteriaDetail = new
            {
                matrix = detail.Matrix,
                columnSum = detail.ColumnSum,
                normalizedMatrix = detail.NormalizedMatrix,
                weights = detail.Weights,
                axW = detail.AxW,
                lambdaI = detail.LambdaI,
                lambdaMax = detail.LambdaMax,
                ci = detail.CI,
                ri = detail.RI,
                cr = detail.CR,
                criteriaNames = detail.CriteriaNames,
                ranking = detail.Ranking
            },
            criteriaWeights = new
            {
                criteria.TestWeight,
                criteria.AttendanceWeight,
                criteria.StudyWeight
            },
            cr = criteria.ConsistencyRatio,
            matrices = matrices.Select(x => new
            {
                x.CriteriaName,
                matrix = JsonSerializer.Deserialize<List<List<double>>>(x.MatrixJson)
            }),
            alternativeWeights = alternatives.Select(x => new
            {
                x.CriteriaName,
                weights = new[] { x.A1, x.A2, x.A3 }
            }),
            finalScores = new[] { final_?.A1 ?? 0, final_?.A2 ?? 0, final_?.A3 ?? 0 },
            best = final_?.BestAlternative ?? ""
        });
    }

    private bool IsValid(double v)
    {
        return !(double.IsNaN(v) || double.IsInfinity(v));
    }
}