import { Home } from "./components/Home";
import { Rewards } from "./components/Rewards";
import { Admins } from "./components/Admins";
import { Challenges } from "./components/Challenges";
import { Events } from "./components/Events";
import { Restrictions } from "./components/Restrictions";
import { ErrorAlert } from "./components/ErrorAlert";

import {
  AppBar,
  AppLayout,
  Container,
  Sidebar,
  SidebarButton,
} from "./components/Layout";

import {
  faHome,
  faLocationDot,
  faPersonWalking,
  faTrophy,
  faUnlink,
  faUserShield,
  faLock,
} from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import { Route, Routes, useLocation, useNavigate } from "react-router-dom";
import styled from "styled-components";
import { useContext } from "react";
import { ServerConnectionContext } from "./components/ServerConnection";
import { ServerDataContext } from "./components/ServerData";
import { AlertModal } from "./components/AlertModal";

const routes = [
  {
    path: "/",
    element: <Home />,
    icon: faHome,
    name: "Home",
  },
  {
    path: "/admins",
    element: <Admins />,
    icon: faUserShield,
    name: "Admin Approval",
  },
  {
    path: "/events",
    element: <Events />,
    icon: faPersonWalking,
    name: "Events",
  },
  {
    path: "/challenges",
    element: <Challenges />,
    icon: faLocationDot,
    name: "Challenges",
  },
  {
    path: "/rewards",
    element: <Rewards />,
    icon: faTrophy,
    name: "Rewards",
  },
  {
    path: "/restrictions",
    element: <Restrictions />,
    icon: faLock,
    name: "Restrictions",
  },
];

const SidebarIcon = styled.span`
  display: inline-block;
  width: 32px;
  font-size: 20px;
  text-align: center;
  margin-right: 12px;
`;

const SidebarText = styled.div`
  width: 100%;
  text-align: center;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow-x: clip;
  font-weight: bold;
  font-size: 16px;
  align-self: center;
  padding-top: 16px;
`;

const RedText = styled.div`
  color: red;
`;

export default function App() {
  const curRoute = useLocation();
  const navigate = useNavigate();
  const connection = useContext(ServerConnectionContext);
  const data = useContext(ServerDataContext);

  return (
    <AppLayout>
      <AppBar>CornellGO! Manager</AppBar>
      <Sidebar>
        {routes.map((route) => (
          <SidebarButton
            active={curRoute.pathname === route.path}
            onClick={() => navigate(route.path)}
            key={route.path}
          >
            <SidebarIcon>
              <FontAwesomeIcon icon={route.icon} />
            </SidebarIcon>
            {route.name}
          </SidebarButton>
        ))}
        <SidebarButton onClick={() => connection.disconnect()} active={false}>
          <RedText>
            <SidebarIcon>
              <FontAwesomeIcon icon={faUnlink} />
            </SidebarIcon>
            Disconnect
          </RedText>
        </SidebarButton>
        <SidebarText>
          {data.events.get(data.selectedEvent)?.name ?? "No Event Selected"}
        </SidebarText>
      </Sidebar>
      <Container>
        <Routes>
          {routes.map((route) => (
            <Route path={route.path} element={route.element} key={route.path} />
          ))}
        </Routes>
      </Container>
      <ErrorAlert />
    </AppLayout>
  );
}
