import { Home } from "./components/Home";
import { Rewards } from "./components/Rewards";
import { Admins } from "./components/Admins";
import { Challenges } from "./components/Challenges";
import { Events } from "./components/Events";

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
  faUserShield,
} from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import { Route, Routes, useLocation, useNavigate } from "react-router-dom";
import styled from "styled-components";

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
];

const SidebarIcon = styled.span`
  display: inline-block;
  width: 32px;
  font-size: 20px;
  text-align: center;
  margin-right: 12px;
`;

export default function App() {
  const curRoute = useLocation();
  const navigate = useNavigate();

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
      </Sidebar>
      <Container>
        <Routes>
          {routes.map((route) => (
            <Route path={route.path} element={route.element} key={route.path} />
          ))}
        </Routes>
      </Container>
    </AppLayout>
  );
}
