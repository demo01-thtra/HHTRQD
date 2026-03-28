using DSSStudentRisk.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MailKit.Net.Smtp;
using MimeKit;

namespace DSSStudentRisk.Controllers;

[ApiController]
[Route("api/notification")]
public class NotificationController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;

    public NotificationController(AppDbContext context, IConfiguration config)
    {
        _context = context;
        _config = config;
    }

    public class SendEmailRequest
    {
        public int StudentId { get; set; }
        public string Subject { get; set; } = "";
        public string Body { get; set; } = "";
    }

    public class SendBatchEmailRequest
    {
        public List<SendEmailRequest> Emails { get; set; } = new();
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendEmail([FromBody] SendEmailRequest request)
    {
        var student = await _context.Students.FindAsync(request.StudentId);
        if (student == null)
            return NotFound("Student not found");

        if (string.IsNullOrWhiteSpace(student.Email))
            return BadRequest("Student has no email address");

        var emailSettings = _config.GetSection("EmailSettings");
        var senderEmail = emailSettings["SenderEmail"];
        var senderPassword = emailSettings["SenderPassword"];
        var smtpServer = emailSettings["SmtpServer"] ?? "smtp.gmail.com";
        var smtpPort = int.Parse(emailSettings["SmtpPort"] ?? "587");
        var senderName = emailSettings["SenderName"] ?? "DSS Cảnh Báo Sớm";

        if (string.IsNullOrWhiteSpace(senderEmail) || string.IsNullOrWhiteSpace(senderPassword))
            return BadRequest("Email settings not configured. Please set SenderEmail and SenderPassword in appsettings.json");

        try
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(senderName, senderEmail));
            message.To.Add(new MailboxAddress(student.Name ?? "", student.Email));
            message.Subject = request.Subject;

            message.Body = new TextPart("plain")
            {
                Text = request.Body
            };

            using var client = new SmtpClient();
            await client.ConnectAsync(smtpServer, smtpPort, MailKit.Security.SecureSocketOptions.StartTls);
            await client.AuthenticateAsync(senderEmail, senderPassword);
            await client.SendAsync(message);
            await client.DisconnectAsync(true);

            return Ok(new { message = $"Email sent to {student.Email}", studentId = student.Id });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = $"Failed to send email: {ex.Message}" });
        }
    }

    [HttpPost("send-batch")]
    public async Task<IActionResult> SendBatch([FromBody] SendBatchEmailRequest request)
    {
        var emailSettings = _config.GetSection("EmailSettings");
        var senderEmail = emailSettings["SenderEmail"];
        var senderPassword = emailSettings["SenderPassword"];
        var smtpServer = emailSettings["SmtpServer"] ?? "smtp.gmail.com";
        var smtpPort = int.Parse(emailSettings["SmtpPort"] ?? "587");
        var senderName = emailSettings["SenderName"] ?? "DSS Cảnh Báo Sớm";

        if (string.IsNullOrWhiteSpace(senderEmail) || string.IsNullOrWhiteSpace(senderPassword))
            return BadRequest("Email settings not configured");

        var results = new List<object>();

        try
        {
            using var client = new SmtpClient();
            await client.ConnectAsync(smtpServer, smtpPort, MailKit.Security.SecureSocketOptions.StartTls);
            await client.AuthenticateAsync(senderEmail, senderPassword);

            foreach (var req in request.Emails)
            {
                var student = await _context.Students.FindAsync(req.StudentId);
                if (student == null || string.IsNullOrWhiteSpace(student.Email))
                {
                    results.Add(new { studentId = req.StudentId, success = false, error = "No email" });
                    continue;
                }

                try
                {
                    var message = new MimeMessage();
                    message.From.Add(new MailboxAddress(senderName, senderEmail));
                    message.To.Add(new MailboxAddress(student.Name ?? "", student.Email));
                    message.Subject = req.Subject;
                    message.Body = new TextPart("plain") { Text = req.Body };

                    await client.SendAsync(message);
                    results.Add(new { studentId = req.StudentId, success = true, email = student.Email });
                }
                catch (Exception ex)
                {
                    results.Add(new { studentId = req.StudentId, success = false, error = ex.Message });
                }
            }

            await client.DisconnectAsync(true);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = $"SMTP connection failed: {ex.Message}" });
        }

        return Ok(results);
    }
}
