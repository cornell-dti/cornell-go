import { Home } from "./components/Home";
import { Rewards } from "./components/Rewards";
import { Admins } from "./components/Admins";
import { Challenges } from "./components/Challenges";
import { Events } from "./components/Events";

import { Route, Routes, useLocation, useNavigate } from "react-router-dom";
import { ReactNode } from "react";
import { styled } from "@mui/material";

const routes = [
  { path: "/", element: <Home />, icon: <></>, name: "Home" },
  {
    path: "/admins",
    element: <Admins />,
    icon: <></>,
    name: "Admin Approval",
  },
  { path: "/events", element: <Events />, icon: <></>, name: "Events" },
  {
    path: "/challenges",
    element: <Challenges />,
    icon: <></>,
    name: "Challenges",
  },
  {
    path: "/rewards",
    element: <Rewards />,
    icon: <></>,
    name: "Rewards",
  },
];

export default function App() {
  return (
    <Routes>
      {routes.map((route) => (
        <Route path={route.path} element={route.element} key={route.path} />
      ))}
    </Routes>
  );
}
