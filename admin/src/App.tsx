import React from 'react';
import Typography from '@mui/material/Typography';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';

export function App() {
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography
          component="h1"
          variant="h4"
          color="inherit">
          CornellGO!Manager
        </Typography>
      </Toolbar>
    </AppBar>
  );
}
