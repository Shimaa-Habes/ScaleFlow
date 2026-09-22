using System.Text;

using FluentValidation;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

using ScaleFlow.Constants;
using ScaleFlow.DTOs;
using ScaleFlow.Hubs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;
using ScaleFlow.Options;
using ScaleFlow.Services;
using ScaleFlow.Validation;

namespace ScaleFlow;

public class Program
{
    public static async Task Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // CORS
        builder.Services.AddCors(options =>
        {
            options.AddPolicy("AllowAll",
                policy => policy
                    .AllowAnyOrigin()
                    .AllowAnyMethod()
                    .AllowAnyHeader());
        });

        // SignalR
        builder.Services.AddSignalR();

        // JWT settings
        builder.Services.Configure<JwtSettings>(
            builder.Configuration.GetSection("JwtSettings"));

        // Validation
        builder.Services.AddValidatorsFromAssemblyContaining<ProjectRequestValidator>();
        builder.Services.AddScoped<ApiValidationFilter>();

        // Application services
        builder.Services.AddScoped<IProjectService, ProjectManagementService>();
        builder.Services.AddScoped<ITaskService, TaskService>();
        builder.Services.AddScoped<IProjectProgressService, ProjectProgressService>();
        builder.Services.AddScoped<IProjectMemberService, ProjectMemberService>();
        builder.Services.AddScoped<ITeamService, TeamService>();
        builder.Services.AddScoped<IMlService, UnavailableMlService>();
        builder.Services.AddScoped<IProjectAiService, ProjectAiService>();
        builder.Services.AddScoped<INotificationService, NotificationService>();
        builder.Services.AddScoped<IWorkloadService, WorkloadService>();
        builder.Services.AddScoped<IReportService, ReportService>();

        // Controllers
        builder.Services.AddControllers(options =>
                options.Filters.Add<ApiValidationFilter>())
            .ConfigureApiBehaviorOptions(options =>
                options.InvalidModelStateResponseFactory = context =>
                    new BadRequestObjectResult(
                        ApiResponse<object>.Fail(
                            "Validation failed.",
                            context.ModelState
                                .Where(x => x.Value!.Errors.Count > 0)
                                .ToDictionary(
                                    x => x.Key,
                                    x => x.Value!.Errors
                                        .Select(e =>
                                            string.IsNullOrWhiteSpace(e.ErrorMessage)
                                                ? "Invalid value."
                                                : e.ErrorMessage)
                                        .ToArray()))));

        // Swagger
        builder.Services.AddEndpointsApiExplorer();

        builder.Services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc(
                "v1",
                new OpenApiInfo
                {
                    Title = "ScaleFlow API",
                    Version = "v1"
                });

            options.AddSecurityDefinition(
                "Bearer",
                new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "Bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Description = "Enter JWT token"
                });

            options.AddSecurityRequirement(
                new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
        });

        // Database
        var connectionString =
            builder.Configuration.GetConnectionString(
                "ScaleFlowConnection");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Connection string 'ScaleFlowConnection' was not found.");
        }

        builder.Services.AddDbContext<ScaleFlowDbContext>(options =>
            options.UseSqlServer(connectionString));

        // ASP.NET Identity
        builder.Services.AddIdentity<User, Role>(options =>
            {
                options.Password.RequireDigit = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = true;
                options.Password.RequiredLength = 8;
                options.User.RequireUniqueEmail = true;
            })
            .AddEntityFrameworkStores<ScaleFlowDbContext>()
            .AddDefaultTokenProviders();

        // JWT configuration
        var jwtSettings =
            builder.Configuration
                .GetSection("JwtSettings")
                .Get<JwtSettings>()
            ?? new JwtSettings();

        // Authentication
        builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme =
                    JwtBearerDefaults.AuthenticationScheme;

                options.DefaultChallengeScheme =
                    JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.Events = new JwtBearerEvents
                {
                    OnChallenge = async context =>
                    {
                        context.HandleResponse();

                        context.Response.StatusCode = 401;

                        context.Response.Headers.WWWAuthenticate =
                            "Bearer";

                        await context.Response.WriteAsJsonAsync(
                            ApiResponse<object>.Fail(
                                "Authentication is required."));
                    },

                    OnForbidden = context =>
                    {
                        context.Response.StatusCode = 403;

                        return context.Response.WriteAsJsonAsync(
                            ApiResponse<object>.Fail(
                                "Access denied."));
                    },

                    OnMessageReceived = context =>
                    {
                        var accessToken = context.Request.Query["access_token"];
                        var path = context.HttpContext.Request.Path;
                        if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                        {
                            context.Token = accessToken;
                        }

                        return Task.CompletedTask;
                    }
                };

                options.TokenValidationParameters =
                    new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,

                        ValidIssuer = jwtSettings.Issuer,
                        ValidAudience = jwtSettings.Audience,

                        IssuerSigningKey =
                            new SymmetricSecurityKey(
                                Encoding.UTF8.GetBytes(
                                    jwtSettings.SecretKey)),

                        ClockSkew = TimeSpan.FromMinutes(1)
                    };
            });

        // Authorization
        builder.Services.AddAuthorization();

        // JWT + Auth services
        builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
        builder.Services.AddScoped<IAuthService, AuthService>();

        // Build application
        var app = builder.Build();

        // Database migration + role + default organization seeding
        if (!app.Environment.IsEnvironment("Testing"))
        {
            using var scope = app.Services.CreateScope();
            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<ScaleFlowDbContext>();

            // Apply pending migrations.
            if (dbContext.Database.IsRelational())
            {
                await dbContext.Database.MigrateAsync();
            }

            // ---------------------------------------------------------
            // Seed default organization
            // ---------------------------------------------------------
            var defaultOrganization =
                await dbContext.Organizations
                    .FirstOrDefaultAsync(
                        organization =>
                            organization.Code == "SCALEFLOW" &&
                            !organization.IsDeleted);

            if (defaultOrganization is null)
            {
                defaultOrganization = new Organization
                {
                    Name = "ScaleFlow",
                    Slug = "scaleflow",
                    Code = "SCALEFLOW",
                    Industry = "Software",
                    Timezone = "Asia/Hebron",
                    IsDeleted = false,
                    CreatedAt = DateTimeOffset.UtcNow
                };

                dbContext.Organizations.Add(defaultOrganization);

                await dbContext.SaveChangesAsync();
            }

            // ---------------------------------------------------------
            // Seed roles
            // ---------------------------------------------------------
            var roleManager =
                scope.ServiceProvider
                    .GetRequiredService<RoleManager<Role>>();

            foreach (var roleName in RoleConstants.All)
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    var result =
                        await roleManager.CreateAsync(
                            new Role
                            {
                                Name = roleName,
                                Code = roleName,
                                Scope = RoleScope.Global,
                                IsSystem = true
                            });

                    if (!result.Succeeded)
                    {
                        throw new InvalidOperationException(
                            $"Unable to seed role '{roleName}': " +
                            $"{string.Join(
                                "; ",
                                result.Errors.Select(
                                    error => error.Description))}");
                    }
                }
            }
        }

        // Swagger
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        // Middleware order
        app.UseCors("AllowAll");

        app.UseMiddleware<ApiExceptionMiddleware>();

        app.UseStatusCodePages(async context =>
            await context.HttpContext.Response.WriteAsJsonAsync(
                ApiResponse<object>.Fail(
                    "Request failed with status " +
                    context.HttpContext.Response.StatusCode +
                    ".")));

        app.UseHttpsRedirection();

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();
        app.MapHub<ScaleFlowHub>("/hubs/scaleflow");

        app.Run();
    }
}

