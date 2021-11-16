# Introduction
Injectable service to manage users in AAD by checking its existence and creating invitations to become a guest user. Sample bases on the built-in authentication, but can be easily adapted.

# Getting Started
Assign the required permissions (application based, not delegated) to the App Registration assigned to you App Service instance. These are:
* `User.Read.All`: If you want to check existance of a user prio to try to create an invitation. This is optional as it is possible to re-generate an invitation for an already existing guest user without causing damage. But it is more clean to do it, especial when there's a mixture of regular AAD users and guest users - when trying to create an invitation for regular AAD users, it throws an exception. This can be catched, but it's hard to differentiate from other potential errors that may occur.
* `User.Invite.All`: Required when you want to create invitations

# Files included
* [`IGraphApiService`](./IGraphApiService.cs) | [`GraphApiService`](./GraphApiService.cs): Service implementation
* [`Constants`](./Constants.cs): Reference to app service configurations and other static settings
* [`BuiltInAuthConfig`](./BuiltInAuthConfig.cs): Wrapper around pre-defined app service configurations resulting from built-in authentication feature
* [`BuiltInAuthProvider`](./BuiltInAuthProvider.cs): MSAL adapter which generates authentication tokens

```csharp
public class Startup : FunctionsStartup
{
    public override void Configure(IFunctionsHostBuilder builder)
    {
        builder.Services.AddSingleton<IGraphApiService, GraphApiService>();
    }
}
```