using FluentValidation;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class GenerateReportRequestValidator : AbstractValidator<GenerateReportRequest>
{
    private static readonly string[] AllowedReportTypes = ["Summary", "Performance", "Risk", "FullAi"];

    public GenerateReportRequestValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.ReportType)
            .Must(type => AllowedReportTypes.Contains(type, StringComparer.OrdinalIgnoreCase))
            .WithMessage("ReportType must be one of: Summary, Performance, Risk, FullAi.");
        RuleFor(x => x.PeriodTo)
            .Must((req, to) => !to.HasValue || !req.PeriodFrom.HasValue || to.Value >= req.PeriodFrom.Value)
            .WithMessage("PeriodTo must be on or after PeriodFrom.");
    }
}
