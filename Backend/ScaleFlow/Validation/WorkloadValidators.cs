using FluentValidation;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class AssignTaskRequestValidator : AbstractValidator<AssignTaskRequest>
{
    public AssignTaskRequestValidator()
    {
        RuleFor(x => x.AssigneeUserId).GreaterThan(0);
    }
}
