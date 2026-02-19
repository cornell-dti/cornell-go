import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useState,
} from 'react';

import { GoogleLogin } from '@react-oauth/google';
import { GoogleOAuthProvider } from '@react-oauth/google';

import { io, Socket } from 'socket.io-client';
import styled from 'styled-components';
import isDev from '../development';
import { postRequest } from '../post';
import { Modal } from './Modal';

const serverUrl = isDev() ? 'http://localhost:8080' : '';

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
            | undefined = await postRequest(serverUrl + '/google', {
            idToken,
            lat: 1,
            long: 1,
            username: 'guest',
            college: 'Arts and Sciences',
            major: 'Computer Science',
            year: '2025',
            interests: '',
            aud: 'web',
            enrollmentType: 'UNDERGRADUATE',
          });

          if (!loginResponse) {
            return false;
          }

          const socket = io(serverUrl, {
            auth: { token: loginResponse.accessToken },
            autoConnect: false,
            reconnection: true,
            reconnectionAttempts: Infinity,
            reconnectionDelay: 1000,
            reconnectionDelayMax: 5000,
          });

          socket.on('connect', () => {
            setConnection(socket);
          });

          socket.on('connect_error', err => {
            console.error('Socket connection error:', err);
          });

          socket.on('disconnect', reason => {
            console.log('Socket disconnected:', reason);
            // Only permanently close if server kicked us
            if (reason === 'io server disconnect') {
              this.disconnect();
            }
            // For other reasons (transport close, ping timeout), socket.io will auto-reconnect
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
  margin-bottom: 8px;
  width: 100%;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
`;

export function AuthenticationGuard(props: { children: ReactNode }) {
  const connection = useContext(ServerConnectionContext);
  const [loginMessage, setLoginMessage] = useState('');

  const connect = async (response: any) => {
    //New package returns key 'clientId'
    if ('clientId' in response) {
      const state = await connection.connect(response.credential);
    } else {
      setLoginMessage('Connection error');
    }
  };

  useEffect(() => {
    if (connection.connection) setLoginMessage('');
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
        <GoogleOAuthProvider clientId="757523123677-2nv6haiqnvklhb134cgg5qe8bia4du4q.apps.googleusercontent.com">
          <GoogleButtonBox>
            <GoogleLogin
              // Call connect on credential response
              onSuccess={(credentialResponse: any) => {
                connect(credentialResponse);
              }}
              onError={() => {
                console.log('Login Failed');
                setLoginMessage('An error occured while signing you in.');
              }}
            />
          </GoogleButtonBox>
        </GoogleOAuthProvider>
        <b>{loginMessage}</b>
      </Modal>
    );
  }
}
