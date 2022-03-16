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

import {
  MemoryRouter,
  Route,
  Routes,
  useLocation,
  useNavigate,
} from "react-router-dom";
import { Rewards } from "./components/Rewards";
import { Admins } from "./components/Admins";
import { Challenges } from "./components/Challenges";
import { Events } from "./components/Events";

const drawerWidth = 250;

export default function App() {
  const navigate = useNavigate();
  const location = useLocation();

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
          <List>
            <ListItemButton
              onClick={() => navigate("/")}
              selected={location.pathname === "/"}
            >
              <ListItemIcon>
                <HomeSharp />
              </ListItemIcon>
              <ListItemText primary={"Home"} />
            </ListItemButton>
            <ListItemButton
              onClick={() => navigate("/admins")}
              selected={location.pathname === "/admins"}
            >
              <ListItemIcon>
                <VerifiedUser />
              </ListItemIcon>
              <ListItemText primary={"Admin Approval"} />
            </ListItemButton>
            <ListItemButton
              onClick={() => navigate("/events")}
              selected={location.pathname === "/events"}
            >
              <ListItemIcon>
                <Event />
              </ListItemIcon>
              <ListItemText primary={"Events"} />
            </ListItemButton>
            <ListItemButton
              onClick={() => navigate("/challenges")}
              selected={location.pathname === "/challenges"}
            >
              <ListItemIcon>
                <Place />
              </ListItemIcon>
              <ListItemText primary={"Challenges"} />
            </ListItemButton>
            <ListItemButton
              onClick={() => navigate("/rewards")}
              selected={location.pathname === "/rewards"}
            >
              <ListItemIcon>
                <EmojiEvents />
              </ListItemIcon>
              <ListItemText primary={"Rewards"} />
            </ListItemButton>
          </List>
        </Box>
      </Drawer>
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/admins" element={<Admins />} />
          <Route path="/events" element={<Events />} />
          <Route path="/challenges" element={<Challenges />} />
          <Route path="/rewards" element={<Rewards />} />
        </Routes>
      </Box>
    </Box>
  );
}
