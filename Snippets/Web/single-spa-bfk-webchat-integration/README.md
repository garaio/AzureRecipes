# Introduction
The integration of the BotFramework web-chat component in the popular micro-frontend framework `single-spa` can be tricky. This reference implementation is created with:
1. The single-spa CLI by [generating a React module](https://single-spa.js.org/docs/create-single-spa#--framework) (Note: pure JS)
1. Adoption of the official sample ["06.recomposing-ui/a.minimizable-web-chat"](https://github.com/microsoft/BotFramework-WebChat/tree/master/samples/06.recomposing-ui/a.minimizable-web-chat)

Additionally, some useful styling is provided as template as well as the automatic start of a conversation (welcome message) as soon as the component is loaded and the enrichment of each user input with additional piggyback/backchannel data.

Notes / learnings:
* The current npm package ([botframework-webchat v4.13.0](https://www.npmjs.com/package/botframework-webchat/v/4.13.0)) does not properly work in a TypeScript-based application
* It is compatible (without errors and warnings) with React version 16.8.6
* With Webpack 5+ polyfills for `crypto`, `stream` and `path` seemed to be required as well as a rather strange plugin registration for `process` (all included in `webpack.config.js`)

# Getting Started
Deploy your bot service to Azure (no special configurations or prerequists necessary) and enable the Directline channel.

1. Adjust the directline secret in `minimizable-web-chat.js` (or replace the method with a call to an according backend service)
1. Run `npm ci`
1. Run `npm run start:standalone` for local testing

The module can be integrated to the single-spa shell as any other module. If [Content Security Policy (CSP)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) is configured in the shell application (meta property in `index.html` or `index.ejs`), make sure it allows to access the directline API. The definition may look like:

```html
<meta http-equiv="Content-Security-Policy" content="default-src 'self' https: localhost:*; script-src 'unsafe-inline' https: localhost:*; connect-src https: localhost:* ws://localhost:* ws://realtime-notifications.service.signalr.net ws://gxp-portal-signalr-d.service.signalr.net wss://directline.botframework.com ; style-src 'unsafe-inline' https:; object-src 'none'; font-src 'self' data:; img-src 'self' data: blob:">
```

# References
* [MSDN WebChat documentation](https://docs.microsoft.com/en-us/azure/bot-service/bot-builder-webchat-overview?view=azure-bot-service-4.0)
* [BotFramework-WebChat Component](https://github.com/microsoft/BotFramework-WebChat)
* [single-spa React library](https://single-spa.js.org/docs/ecosystem-react/)
