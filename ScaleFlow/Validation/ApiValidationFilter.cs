using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using ScaleFlow.DTOs;

namespace ScaleFlow.Validation;

public class ApiValidationFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var errors = new Dictionary<string, string[]>();
        foreach (var argument in context.ActionArguments.Values.Where(x => x is not null))
        {
            var validatorType = typeof(IValidator<>).MakeGenericType(argument!.GetType());
            if (context.HttpContext.RequestServices.GetService(validatorType) is not IValidator validator) continue;
            var result = await validator.ValidateAsync(new ValidationContext<object>(argument), context.HttpContext.RequestAborted);
            foreach (var group in result.Errors.GroupBy(x => x.PropertyName))
                errors[group.Key] = group.Select(x => x.ErrorMessage).Distinct().ToArray();
        }
        if (errors.Count > 0)
        {
            context.Result = new BadRequestObjectResult(ApiResponse<object>.Fail("Validation failed.", errors));
            return;
        }
        await next();
    }
}
