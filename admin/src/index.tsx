import "./index.css";
import "typeface-roboto";
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";
import reportWebVitals from "./reportWebVitals";
import { MemoryRouter } from "react-router-dom";
import {
  AuthenticationGuard,
  ServerConnectionProvider,
} from "./components/ServerConnection";
import { ServerDataProvider } from "./components/ServerData";

ReactDOM.render(
  <React.StrictMode>
    <ServerConnectionProvider>
      <AuthenticationGuard>
        <ServerDataProvider>
          <MemoryRouter>
            <App />
          </MemoryRouter>
        </ServerDataProvider>
      </AuthenticationGuard>
    </ServerConnectionProvider>
  </React.StrictMode>,
  document.getElementById("root"),
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
