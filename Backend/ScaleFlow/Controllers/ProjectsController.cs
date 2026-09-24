using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProjectsController : ControllerBase
{
    private readonly IProjectService _projectService;
    private readonly ScaleFlowDbContext _context;
    private readonly IWebHostEnvironment _environment;

    public ProjectsController(
        IProjectService projectService,
        ScaleFlowDbContext context,
        IWebHostEnvironment environment)
    {
        _projectService = projectService;
        _context = context;
        _environment = environment;
    }

    // ============================================================
    // GET ALL PROJECTS
    // ============================================================

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] QueryParameters queryParameters,
        CancellationToken cancellationToken)
    {
        var projects = await _projectService.ListProjects(
            User,
            queryParameters.Page,
            queryParameters.PageSize,
            cancellationToken);

        return Ok(
            ApiResponse<IReadOnlyList<ProjectResponse>>.Ok(
                projects));
    }

    // ============================================================
    // GET PROJECT BY ID
    // ============================================================

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(
        int id,
        CancellationToken cancellationToken)
    {
        var project = await _projectService.GetProject(
            User,
            id,
            cancellationToken);

        return Ok(
            ApiResponse<ProjectResponse>.Ok(
                project));
    }

    // ============================================================
    // CREATE PROJECT
    // ============================================================

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] ProjectRequest request,
        CancellationToken cancellationToken)
    {
        var project = await _projectService.CreateProject(
            User,
            request,
            cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { id = project.Id },
            ApiResponse<ProjectResponse>.Ok(
                project,
                "Project created."));
    }

    // ============================================================
    // UPDATE PROJECT
    // ============================================================

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(
        int id,
        [FromBody] ProjectRequest request,
        CancellationToken cancellationToken)
    {
        var project = await _projectService.UpdateProject(
            User,
            id,
            request,
            cancellationToken);

        return Ok(
            ApiResponse<ProjectResponse>.Ok(
                project,
                "Project updated."));
    }

    // ============================================================
    // UPLOAD PROJECT IMAGE
    // ============================================================

   [HttpPost("{id}/image")]
[Consumes("multipart/form-data")]
[RequestSizeLimit(5 * 1024 * 1024)]
public async Task<IActionResult> UploadImage(
    int id,
    IFormFile image,
    CancellationToken cancellationToken)
    {
        // --------------------------------------------------------
        // Basic validation
        // --------------------------------------------------------

        if (image == null || image.Length == 0)
        {
            throw new ApiException(
                400,
                "Invalid file. Please select an image.");
        }

        // --------------------------------------------------------
        // Maximum file size: 5 MB
        // --------------------------------------------------------

        const long maxFileSize = 5 * 1024 * 1024;

        if (image.Length > maxFileSize)
        {
            throw new ApiException(
                400,
                "Project image must be 5 MB or smaller.");
        }

        // --------------------------------------------------------
        // Get current user
        // --------------------------------------------------------

        var userIdClaim = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier);

        if (!int.TryParse(
                userIdClaim?.Value,
                out var userId))
        {
            throw new ApiException(
                401,
                "Invalid user identity.");
        }

        // --------------------------------------------------------
        // Find project
        // --------------------------------------------------------

        var project = await _context.Projects
            .SingleOrDefaultAsync(
                x =>
                    x.Id == id &&
                    x.OwnerId == userId &&
                    !x.IsDeleted,
                cancellationToken);

        if (project is null)
        {
            throw new ApiException(
                404,
                "Project not found.");
        }

        // --------------------------------------------------------
        // File information
        // --------------------------------------------------------

        var originalExtension =
            Path.GetExtension(image.FileName)
                .ToLowerInvariant();

        var contentType =
            image.ContentType?.Trim().ToLowerInvariant() ?? string.Empty;

        // --------------------------------------------------------
        // WEBP is explicitly NOT allowed
        // --------------------------------------------------------

        if (originalExtension == ".webp" ||
            contentType == "image/webp")
        {
            throw new ApiException(
                400,
                "WEBP images are not supported. Please select another image format.");
        }

        // --------------------------------------------------------
        // Accept:
        //
        // 1. Any image/* MIME type
        // 2. application/octet-stream when the filename has
        //    a normal image extension.
        //
        // This is important because Flutter's
        // MultipartFile.fromBytes can send application/octet-stream.
        // --------------------------------------------------------

        var isImageMimeType =
            contentType.StartsWith(
                "image/",
                StringComparison.OrdinalIgnoreCase);

        var commonImageExtensions = new HashSet<string>(
            StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".gif",
            ".bmp",
            ".tif",
            ".tiff",
            ".ico",
            ".jfif",
            ".pjpeg",
            ".pjp",
            ".avif",
            ".heic",
            ".heif",
            ".raw",
            ".cr2",
            ".nef",
            ".arw",
            ".dng",
            ".orf",
            ".rw2",
            ".raf",
            ".3fr"
        };

        var hasKnownImageExtension =
            !string.IsNullOrWhiteSpace(originalExtension) &&
            commonImageExtensions.Contains(
                originalExtension);

        if (!isImageMimeType && !hasKnownImageExtension)
        {
            throw new ApiException(
                400,
                "Invalid file. Please select a valid image.");
        }

        // --------------------------------------------------------
        // Determine extension
        // --------------------------------------------------------

        var extension = originalExtension;

        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = contentType switch
            {
                "image/jpeg" => ".jpg",
                "image/png" => ".png",
                "image/gif" => ".gif",
                "image/bmp" => ".bmp",
                "image/tiff" => ".tiff",
                "image/avif" => ".avif",
                "image/heic" => ".heic",
                "image/heif" => ".heif",
                "image/x-icon" => ".ico",
                _ => ".img"
            };
        }

        // --------------------------------------------------------
        // Upload directory
        // --------------------------------------------------------

        var webRootPath =
            _environment.WebRootPath;

        if (string.IsNullOrWhiteSpace(webRootPath))
        {
            webRootPath = Path.Combine(
                _environment.ContentRootPath,
                "wwwroot");
        }

        var uploadDirectory = Path.Combine(
            webRootPath,
            "uploads",
            "projects");

        Directory.CreateDirectory(
            uploadDirectory);

        // --------------------------------------------------------
        // Delete old project image
        // --------------------------------------------------------

        if (!string.IsNullOrWhiteSpace(project.ImageUrl))
        {
            var oldImageUrl =
                project.ImageUrl.Trim();

            if (oldImageUrl.StartsWith(
                    "/uploads/projects/",
                    StringComparison.OrdinalIgnoreCase))
            {
                var oldRelativePath =
                    oldImageUrl
                        .TrimStart('/')
                        .Replace(
                            '/',
                            Path.DirectorySeparatorChar);

                var oldFullPath =
                    Path.Combine(
                        webRootPath,
                        oldRelativePath);

                if (System.IO.File.Exists(oldFullPath))
                {
                    try
                    {
                        System.IO.File.Delete(
                            oldFullPath);
                    }
                    catch
                    {
                        // Do not fail the new upload
                        // because the old file could not
                        // be deleted.
                    }
                }
            }
        }

        // --------------------------------------------------------
        // Generate unique filename
        // --------------------------------------------------------

        var fileName =
            $"{Guid.NewGuid():N}{extension}";

        var filePath =
            Path.Combine(
                uploadDirectory,
                fileName);

        // --------------------------------------------------------
        // Save file
        // --------------------------------------------------------

        await using (var stream = new FileStream(
            filePath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None))
        {
            await image.CopyToAsync(
                stream,
                cancellationToken);
        }

        // --------------------------------------------------------
        // Save URL in database
        // --------------------------------------------------------

        project.ImageUrl =
            $"/uploads/projects/{fileName}";

        project.UpdatedAt =
            DateTimeOffset.UtcNow;

        await _context.SaveChangesAsync(
            cancellationToken);

        // --------------------------------------------------------
        // Response
        // --------------------------------------------------------

        return Ok(
            ApiResponse<object>.Ok(
                new
                {
                    projectId = project.Id,
                    imageUrl = project.ImageUrl,
                    fileName,
                    contentType,
                    size = image.Length
                },
                "Project image uploaded."));
    }

    // ============================================================
    // DELETE PROJECT
    // ============================================================

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(
        int id,
        CancellationToken cancellationToken)
    {
        await _projectService.DeleteProject(
            User,
            id,
            cancellationToken);

        return Ok(
            ApiResponse<object>.Ok(
                null,
                "Project deleted."));
    }
}