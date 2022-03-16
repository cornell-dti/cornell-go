import {
  AppBar,
  Box,
  CssBaseline,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
} from "@mui/material";

import {
  EmojiEvents,
  Event,
  HomeSharp,
  Place,
  VerifiedUser,
} from "@mui/icons-material";

import { Home } from "./components/Home";

import { Route, Routes, useLocation, useNavigate } from "react-router-dom";
import { Rewards } from "./components/Rewards";
import { Admins } from "./components/Admins";
import { Challenges } from "./components/Challenges";
import { Events } from "./components/Events";
import { ReactNode } from "react";

const routes = [
  { path: "/", element: <Home />, icon: <HomeSharp />, name: "Home" },
  {
    path: "/admins",
    element: <Admins />,
    icon: <VerifiedUser />,
    name: "Admin Approval",
  },
  { path: "/events", element: <Events />, icon: <Event />, name: "Events" },
  {
    path: "/challenges",
    element: <Challenges />,
    icon: <Place />,
    name: "Challenges",
  },
  {
    path: "/rewards",
    element: <Rewards />,
    icon: <EmojiEvents />,
    name: "Rewards",
  },
];

function NavButton(props: { path: string; text: string; icon: ReactNode }) {
  const navigate = useNavigate();
  const location = useLocation();
  return (
    <ListItemButton
      onClick={() => navigate(props.path)}
      selected={location.pathname === props.path}
    >
      <ListItemIcon>{props.icon}</ListItemIcon>
      <ListItemText primary={props.text} />
    </ListItemButton>
  );
}

function NavDrawer(props: { children: ReactNode }) {
  const drawerWidth = 250;
  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        [`& .MuiDrawer-paper`]: {
          width: drawerWidth,
          boxSizing: "border-box",
        },
      }}
    >
      <Toolbar />
      <Box sx={{ overflow: "auto" }}>
        <List>{props.children}</List>
      </Box>
    </Drawer>
  );
}

export default function App() {
  return (
    <Box sx={{ display: "flex" }}>
      <CssBaseline />
      <AppBar
        position="fixed"
        sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}
      >
        <Toolbar>
          <Typography variant="h6" noWrap component="div">
            CornellGO! Manager
          </Typography>
        </Toolbar>
      </AppBar>
      <NavDrawer>
        {routes.map((route) => (
          <NavButton
            path={route.path}
            text={route.name}
            icon={route.icon}
            key={route.path}
          />
        ))}
      </NavDrawer>
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar />
        <Routes>
          {routes.map((route) => (
            <Route path={route.path} element={route.element} key={route.path} />
          ))}
        </Routes>
      </Box>
    </Box>
  );
}
