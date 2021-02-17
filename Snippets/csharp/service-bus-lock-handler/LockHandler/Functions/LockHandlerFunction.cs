using System;
using System.Collections.Concurrent;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using LockHandler.Constants;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.ServiceBus.Messaging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace LockHandler.Functions
{
    public static class LockHandlerFunction
    {
        private const string OrchestratorName = nameof(LockHandlerFunction);
        private const string TerminationEventName = "TerminationEvent";

        private static readonly MessagingFactory ServiceBusFactory = MessagingFactory.CreateFromConnectionString(Environment.GetEnvironmentVariable(ConfigurationValues.ServiceBusConnectionString));

        private static readonly ConcurrentDictionary<string, QueueClient> ServiceBusQueueClients =
            new ConcurrentDictionary<string, QueueClient>();

        [FunctionName(OrchestratorName)]
        public static async Task RunOrchestrator(
            [OrchestrationTrigger] IDurableOrchestrationContext context, 
            ILogger log)
        {
            var message = JObject.Parse(context.GetInput<string>());

            var maxRetryNumber = (int)message[MessagePropertyNames.MaxRetryNumber];
            var renewalIntervalInSeconds = (int)message[MessagePropertyNames.RenewalIntervalInSeconds];

            var contextInstanceId = context.InstanceId;

            log.LogInformation($"ID '{contextInstanceId}': Iteration {message[MessagePropertyNames.RetryCount]}/{maxRetryNumber} started.");

            DateTime deadline = context.CurrentUtcDateTime.Add(TimeSpan.FromSeconds(renewalIntervalInSeconds));

            using (var cts = new CancellationTokenSource())
            {
                Task terminationTask = context.WaitForExternalEvent(TerminationEventName);
                Task timeoutTask = context.CreateTimer(deadline, cts.Token);

                Task winner = await Task.WhenAny(terminationTask, timeoutTask);
                if (winner == terminationTask)
                {
                    // success case
                    log.LogInformation($"ID '{contextInstanceId}': Lock-handling stopped by using instance.");

                    cts.Cancel();
                }
                else if ((int)message[MessagePropertyNames.RetryCount] < maxRetryNumber)
                {
                    // timeout case
                    log.LogInformation($"ID '{contextInstanceId}': Interval reached for lock-renewal.");

                    (bool terminated, string nextMessageJson) = await context.CallActivityAsync<(bool, string)>(nameof(RenewLockActivity), (contextInstanceId, message));

                    if (!terminated)
                    {
                        log.LogInformation($"ID '{contextInstanceId}': Scheduling next iteration.");

                        context.ContinueAsNew(nextMessageJson);
                    }
                }
                else
                {
                    log.LogInformation($"ID '{contextInstanceId}': Maximal number of cycles reached. Aborting lock-handling.");
                }
            }
        }

        [FunctionName(nameof(RenewLockActivity))]
        public static async Task<(bool, string)> RenewLockActivity([ActivityTrigger] (string, JObject) parameters, ILogger log)
        {
            (string instanceId, JObject message) = parameters;

            var lockToken = (Guid)message[MessagePropertyNames.LockToken];
            var queueName = (string)message[MessagePropertyNames.QueueName];

            var client = GetQueueClient(queueName);

            try
            {
                var lockedUntil = await client.RenewMessageLockAsync(lockToken);

                log.LogInformation($"ID '{instanceId}': Lock renewed until '{lockedUntil}'.");
            }
            catch (MessageLockLostException)
            {
                // Happens when message either is completed or abandoned in the meantime
                log.LogInformation($"ID '{instanceId}': Message has been either completed or abandoned (lock not available anymore). Aborting lock-handling.");

                return (true, null);
            }

            message[MessagePropertyNames.RetryCount] = (int)message[MessagePropertyNames.RetryCount] + 1;

            return (false, message.ToString(Formatting.None));
        }

        [FunctionName("Start")]
        public static async Task<string> Start(
            [HttpTrigger(AuthorizationLevel.Function, "post")]HttpRequestMessage req,
            [DurableClient] IDurableOrchestrationClient client,
            ILogger log)
        {
            if (req == null)
            {
                throw new ArgumentNullException(nameof(req));
            }
            if (client == null)
            {
                throw new ArgumentNullException(nameof(client));
            }
            if (log == null)
            {
                throw new ArgumentNullException(nameof(log));
            }

            var messageJson = await req.Content.ReadAsStringAsync();
            if (messageJson == null)
            {
                throw new ArgumentException("The message is not transmitted in the body.", nameof(req));
            }

            log.LogInformation($"Starting lock-handling for '{messageJson}'.");

            var message = JObject.Parse(messageJson);
            if (message.Property(MessagePropertyNames.RetryCount) == null)
            {
                message.Add(MessagePropertyNames.RetryCount, 0);
            }
            if (message.Property(MessagePropertyNames.RenewalIntervalInSeconds) == null)
            {
                message.Add(MessagePropertyNames.RenewalIntervalInSeconds, int.Parse(Environment.GetEnvironmentVariable(ConfigurationValues.RenewalIntervalInSeconds) ?? "0"));
            }
            if (message.Property(MessagePropertyNames.MaxRetryNumber) == null)
            {
                message.Add(MessagePropertyNames.MaxRetryNumber, int.Parse(Environment.GetEnvironmentVariable(ConfigurationValues.MaxRetryNumber) ?? "0"));
            }

            // Function input comes from the request content.
            string instanceId = await client.StartNewAsync(OrchestratorName, message.ToString(Formatting.None));

            log.LogInformation($"Started orchestration with ID = '{instanceId}'.");

            return instanceId;
        }

        [FunctionName("Stop")]
        public static async Task Stop(
            [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestMessage req,
            [DurableClient] IDurableOrchestrationClient client,
            ILogger log)
        {
            if (req == null)
            {
                throw new ArgumentNullException(nameof(req));
            }
            if (client == null)
            {
                throw new ArgumentNullException(nameof(client));
            }

            var instanceId = await req.Content.ReadAsStringAsync();
            if (instanceId == null)
            {
                throw new ArgumentException("The instanceId is not transmitted in the body.", nameof(req));
            }

            log.LogInformation($"Raising event '{TerminationEventName}' for instance '{instanceId}'.");

            await client.RaiseEventAsync(instanceId, TerminationEventName);
        }

        private static QueueClient GetQueueClient(string queueName)
        {
            return ServiceBusQueueClients.GetOrAdd(queueName, qn => ServiceBusFactory.CreateQueueClient(qn));
        }
    }
}