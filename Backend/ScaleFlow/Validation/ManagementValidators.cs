using FluentValidation;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class ProjectRequestValidator : AbstractValidator<ProjectRequest>
{
    public ProjectRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(4000);
        RuleFor(x => x.Status).IsInEnum();
        RuleFor(x => x.Priority).IsInEnum();
        RuleFor(x => x.Budget).GreaterThanOrEqualTo(0).LessThanOrEqualTo(99999999999999.9999m);
        RuleFor(x => x.EndDate).Must((x, end) => !end.HasValue || !x.StartDate.HasValue || end >= x.StartDate)
            .WithMessage("EndDate must be on or after StartDate.");
    }
}
public class TaskDependencyRequestValidator : AbstractValidator<TaskDependencyRequest>
{
    public TaskDependencyRequestValidator()
    {
        RuleFor(x => x.DependsOnTaskId).GreaterThan(0);
        RuleFor(x => x.DependencyType).IsInEnum();
        RuleFor(x => x.Notes).MaximumLength(4000);
    }
}

public class TaskRequestValidator : AbstractValidator<TaskRequest>
{
    public TaskRequestValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(4000);
        RuleFor(x => x.Status).IsInEnum();
        RuleFor(x => x.Priority).IsInEnum();
        RuleFor(x => x.Type).IsInEnum();
        RuleFor(x => x.EstimatedHours).GreaterThanOrEqualTo(0).LessThanOrEqualTo(99999999999999.9999m);
        RuleFor(x => x.CompletionPercent).InclusiveBetween(0, 100);
        RuleFor(x => x.PlannedEnd).Must((x, end) => !end.HasValue || !x.PlannedStart.HasValue || end >= x.PlannedStart)
            .WithMessage("PlannedEnd must be on or after PlannedStart.");
    }
}
