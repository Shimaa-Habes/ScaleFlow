using FluentValidation;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class AiAnalysisRequestValidator : AbstractValidator<AiAnalysisRequest>
{
    public AiAnalysisRequestValidator()
    {
        RuleFor(request => request.InputWindowDays).InclusiveBetween(1, 365);
    }
}
