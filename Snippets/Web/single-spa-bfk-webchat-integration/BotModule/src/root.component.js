import React from "react";
import MinimizableWebChat from "./bot/minimizable-web-chat";
import "./root.component.css";

export default function Root(props) {
  return (
    <div className="App">
      <MinimizableWebChat />
    </div>
  );
}
