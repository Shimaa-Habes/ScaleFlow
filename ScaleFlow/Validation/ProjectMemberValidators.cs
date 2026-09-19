using FluentValidation;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class AddProjectMemberRequestValidator : AbstractValidator<AddProjectMemberRequest>
{
    public AddProjectMemberRequestValidator()
    {
        RuleFor(request => request.UserId).GreaterThan(0);
        RuleFor(request => request.HourlyRate).GreaterThanOrEqualTo(0).LessThanOrEqualTo(99999999999999.9999m);
        RuleFor(request => request.RoleOverride).MaximumLength(100);
    }
}

public class UpdateProjectMemberRequestValidator : AbstractValidator<UpdateProjectMemberRequest>
{
    public UpdateProjectMemberRequestValidator()
    {
        RuleFor(request => request.HourlyRate).GreaterThanOrEqualTo(0).LessThanOrEqualTo(99999999999999.9999m);
        RuleFor(request => request.RoleOverride).MaximumLength(100);
    }
}
