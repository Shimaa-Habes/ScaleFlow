using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/ai-chat")]
[AllowAnonymous]
public class AiChatController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public AiChatController(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    [HttpPost]
    public async Task<IActionResult> Chat(
        [FromBody] ChatRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new
            {
                message = "Message is required."
            });
        }

        var apiKey = _configuration["Gemini:ApiKey"];

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            return StatusCode(500, new
            {
                message = "Gemini API key is not configured."
            });
        }

        var client = _httpClientFactory.CreateClient();

        var url =
            $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={apiKey}";

        var body = new
        {
            system_instruction = new
            {
                parts = new[]
                {
                    new
                    {
                        text =
                            "You are ScaleFlow AI Assistant. " +
                            "You help users with project management, tasks, " +
                            "project risks, delays, bottlenecks and project health. " +
                            "Give clear, concise and professional answers."
                    }
                }
            },

            contents = new[]
            {
                new
                {
                    parts = new[]
                    {
                        new
                        {
                            text = request.Message
                        }
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(body);

        using var content = new StringContent(
            json,
            Encoding.UTF8,
            "application/json");

        var response = await client.PostAsync(
            url,
            content,
            cancellationToken);

        var responseBody =
            await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            return StatusCode(
                (int)response.StatusCode,
                new
                {
                    message = "Gemini API request failed.",
                    details = responseBody
                });
        }

        using var document =
            JsonDocument.Parse(responseBody);

        var reply = document
            .RootElement
            .GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString();

        return Ok(new
        {
            reply
        });
    }
}

public record ChatRequest(string Message);