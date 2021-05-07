// Adapted from: https://github.com/microsoft/BotFramework-WebChat/tree/main/samples/06.recomposing-ui/a.minimizable-web-chat

import React, { useEffect, useMemo } from 'react';
import ReactWebChat, { createDirectLine, createStyleSet } from 'botframework-webchat';

import './web-chat.css';

const WebChat = ({ className, onFetchToken, store, token }) => {
  const directLine = useMemo(() => createDirectLine({ token }), [token]);

  const styleSet = useMemo(
    () =>
      createStyleSet({
        // https://github.com/microsoft/BotFramework-WebChat/blob/master/packages/api/src/StyleOptions.ts
        backgroundColor: 'Transparent',
        bubbleBackground: "#36424a",
        bubbleTextColor: "#ffffff",
        bubbleBorderRadius: 8,
        bubbleFromUserBackground: "#a7a486",
        bubbleFromUserBorderRadius: 10,
        sendBoxHeight: 55,
        sendBoxBorderTop: "solid 1px #BDB7B7",
        sendBoxBorderBottom: "solid 1px #BDB7B7",
        sendBoxBorderLeft: "solid 1px #BDB7B7",
        sendBoxBorderRight: "solid 1px #BDB7B7",
        sendBoxBackground: "#ffffff",
        sendBoxTextWrap: false,
        sendBoxButtonColor: "#a7a486",
        sendBoxButtonColorOnFocus: "#34b6e4",
        sendBoxButtonColorOnHover: "#34b6e4",
        suggestedActionBackground: "#34b6e4",
        suggestedActionBorderColor: "#ffffff",
        suggestedActionTextColor: "#ffffff",
        suggestedActionBorderRadius: 10,
      }),
    []
  );

  useEffect(() => {
    onFetchToken();
  }, [onFetchToken]);

  return token ? (
    <ReactWebChat 
      className={`${className || ''} web-chat`} 
      directLine={directLine} 
      store={store} 
      styleSet={styleSet} 
      userID="1234"
      username="GARAIO Customer"
      locale="de-de"
    />
  ) : (
    <div className={`${className || ''} connect-spinner`}>
      <div className="content">
        <div className="icon">
          <span className="ms-Icon ms-Icon--Robot" />
        </div>
        <p>Please wait while we are connecting.</p>
      </div>
    </div>
  );
};

export default WebChat;