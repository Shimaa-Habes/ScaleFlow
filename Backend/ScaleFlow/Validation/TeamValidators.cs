using FluentValidation;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class TeamRequestValidator : AbstractValidator<TeamRequest>
{
    public TeamRequestValidator()
    {
        RuleFor(request => request.Name).NotEmpty().MaximumLength(200);
        RuleFor(request => request.Description).MaximumLength(4000);
        RuleFor(request => request.LeadUserId).GreaterThan(0);
    }
}

public class AddTeamMemberRequestValidator : AbstractValidator<AddTeamMemberRequest>
{
    public AddTeamMemberRequestValidator()
    {
        RuleFor(request => request.UserId).GreaterThan(0);
        RuleFor(request => request.RoleInTeam).MaximumLength(100);
    }
}

public class UpdateTeamMemberRequestValidator : AbstractValidator<UpdateTeamMemberRequest>
{
    public UpdateTeamMemberRequestValidator()
    {
        RuleFor(request => request.RoleInTeam).MaximumLength(100);
    }
}
