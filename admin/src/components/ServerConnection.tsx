import { createContext, ReactNode, useContext } from "react";
import GoogleButton from "react-google-button";
import GoogleLogin, {
  GoogleLoginResponse,
  GoogleLoginResponseOffline,
} from "react-google-login";
import { Socket } from "socket.io-client";
import styled from "styled-components";
import { Modal } from "./Modal";

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
  return (
    <ServerConnectionContext.Provider
      value={{
        async connect() {
          return false;
        },
        async disconnect() {},
      }}
    >
      {props.children}
    </ServerConnectionContext.Provider>
  );
}

const GoogleButtonBox = styled.div`
  margin-top: 16px;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
`;

export function AuthenticationGuard(props: { children: ReactNode }) {
  const connection = useContext(ServerConnectionContext);

  const connect = async (
    response: GoogleLoginResponse | GoogleLoginResponseOffline
  ) => {
    console.log(response);
    const state = await connection.connect("");
  };

  if (connection.connection) {
    return <>props.children</>;
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
        </GoogleButtonBox>
      </Modal>
    );
  }
}
