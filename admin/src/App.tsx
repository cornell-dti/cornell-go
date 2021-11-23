import React from 'react';
import Typography from '@mui/material/Typography';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Sidebar from './Sidebar';

export function App() {
  return (
    <div style={{ minHeight: '100vh', display: "flex", flexDirection: "column" }}>
      <AppBar position="static">
        <Toolbar>
          <Typography component="h1" variant="h4" color="inherit">
            CornellGO!Manager
          </Typography>
        </Toolbar>
      </AppBar>
      <Sidebar />
    </div>
  );
}
