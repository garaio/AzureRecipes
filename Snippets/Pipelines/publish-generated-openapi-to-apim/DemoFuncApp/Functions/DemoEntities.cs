using DemoFuncApp.Model;
using DemoFuncApp.OpenApiDefinitions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using Newtonsoft.Json;
using System;
using System.IO;
using System.Net;
using System.Threading.Tasks;

namespace DemoFuncApp.Functions
{
    public static class DemoEntities
    {
        [OpenApiOperation(operationId: "Create Demo Entity", tags: new[] { Constants.ApiCategories.Management }, Description = "Creates a new demo entity")]
        [OpenApiParameter(name: Constants.RouteParams.EntityId, In = ParameterLocation.Path, Required = true, Type = typeof(string), Description = "Entity identifier")]
        [OpenApiRequestBody(contentType: "application/json", bodyType: typeof(DemoRequest), Example = typeof(DemoRequestExample), Required = true, Description = "The demo entity to create")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(DemoResponse), Example = typeof(DemoResponseExample), Description = "When demo entity successfully")]
        [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.BadRequest, Description = "When specified entity id is malformed or missing")]
        [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.NotFound, Description = "When the entity with specified id does not exist or the user does not have permissions for it")]
        [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.UnprocessableEntity, Description = "When provided data cannot be processed")]
        [OpenApiResponseWithoutBody(statusCode: HttpStatusCode.Unauthorized, Description = "When provided authentication token is not valid")]
        [FunctionName(nameof(Create) + nameof(DemoEntities))]
        public static async Task<IActionResult> Create(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = Constants.Routes.DemoEntities + "/{" + Constants.RouteParams.EntityId + "}")] HttpRequest req,
            string id,
            ILogger log)
        {
            var apiVersion = FunctionHelper.GetApiVersion(req);

            if (string.IsNullOrWhiteSpace(id) || Guid.TryParse(id, out var entityId) != true)
            {
                return new BadRequestResult();
            }

            if (id.StartsWith("1"))
            {
                log.LogWarning($"Blocked access for '{new { user = "demo"}}'");
                return new UnauthorizedResult();
            }

            // Parse DTO
            DemoRequest dto = null;
            try
            {
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                dto = JsonConvert.DeserializeObject<DemoRequest>(requestBody);
            }
            catch (JsonException ex)
            {
                log.LogError(ex, $"Failed to parse body: {ex.Message}");
            }

            if (dto == null || string.IsNullOrWhiteSpace(dto.Name))
            {
                return new UnprocessableEntityResult();
            }

            // Generate response object
            var result = new DemoResponse { Version = apiVersion.ToString() };

            return new OkObjectResult(result);
        }
    }
}
