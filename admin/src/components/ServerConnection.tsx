import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";
import GoogleLogin, {
  GoogleLoginResponse,
  GoogleLoginResponseOffline,
} from "react-google-login";
import { io, Socket } from "socket.io-client";
import styled from "styled-components";
import isDev from "../development";
import { postRequest } from "../post";
import { Modal } from "./Modal";

const serverUrl = isDev() ? "http://localhost" : "";

export const ServerConnectionContext = createContext<{
  connection?: Socket;
  connect: (idToken: string) => Promise<boolean>;
  disconnect: () => Promise<void>;
}>({
  async connect() {
    return false;
  },
  async disconnect() {},
});

export function ServerConnectionProvider(props: { children: ReactNode }) {
  const [connection, setConnection] = useState<Socket | undefined>(undefined);

  useEffect(() => {}, [setConnection]);

  return (
    <ServerConnectionContext.Provider
      value={{
        connection,
        async connect(idToken: string) {
          const loginResponse:
            | {
                refreshToken: string;
                accessToken: string;
              }
            | undefined = await postRequest(serverUrl + "/google", {
            idToken,
            lat: 1,
            long: 1,
            aud: "web",
          });

          if (!loginResponse) {
            return false;
          }

          const socket = io(serverUrl, {
            auth: { token: loginResponse.accessToken },
            autoConnect: false,
          });

          socket.on("connect", () => {
            setConnection(socket);
          });

          socket.on("connect_error", () => {});

          socket.on("disconnect", () => {
            this.disconnect();
          });

          socket.connect();

          return true;
        },
        async disconnect() {
          connection?.close();
          connection?.removeAllListeners();
          setConnection(undefined);
        },
      }}
    >
      {props.children}
    </ServerConnectionContext.Provider>
  );
}

const GoogleButtonBox = styled.div`
  margin-top: 16px;
  width: 100%;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
`;

export function AuthenticationGuard(props: { children: ReactNode }) {
  const connection = useContext(ServerConnectionContext);
  const [loginMessage, setLoginMessage] = useState(
    "After logging in for the first time, make sure you have requested access from an admin."
  );

  const connect = async (
    response: GoogleLoginResponse | GoogleLoginResponseOffline
  ) => {
    if ("tokenId" in response) {
      const state = await connection.connect(
        response.getAuthResponse().id_token
      );
      setLoginMessage("Connection error");
    }
  };

  useEffect(() => {
    if (connection.connection) setLoginMessage("");
  }, [connection, setLoginMessage]);

  if (connection.connection) {
    return <>{props.children}</>;
  } else {
    return (
      <Modal
        title="Connect to Dashboard"
        isOpen={true}
        onButtonClick={() => {}}
        buttons={[]}
      >
        <GoogleButtonBox>
          <GoogleLogin
            clientId="757523123677-2nv6haiqnvklhb134cgg5qe8bia4du4q.apps.googleusercontent.com"
            buttonText="Continue with Google"
            onSuccess={connect}
            onFailure={(e) => console.log(e)}
            cookiePolicy={"single_host_origin"}
          />
          <br />
          <b>{loginMessage}</b>
        </GoogleButtonBox>
      </Modal>
    );
  }
}
