import {
  DialogTitle,
  Dialog,
  DialogContent,
  Grid,
  DialogActions,
  TextField,
  Button,
  Snackbar,
} from "@material-ui/core";

import { ReactNode, useContext, useState } from "react";

import { ServerDataContext, ServerLoginResult } from "./ServerData";

export default function Login(props: { children: ReactNode }) {
  const dataContext = useContext(ServerDataContext);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [badText, setBadText] = useState("");
  const [passBadText, setPassBadText] = useState("");
  const [requested, setRequested] = useState(false);

  const login = async () => {
    const result = await dataContext.login(email, password);
    setBadText(
      result === ServerLoginResult.NoAdminApproval
        ? "Email is awaiting response"
        : result === ServerLoginResult.AdminRejected
        ? "Email has been rejected"
        : result === ServerLoginResult.NoAccount
        ? "Email has not been registered"
        : ""
    );
    if (result === ServerLoginResult.WrongPassword)
      setPassBadText("Incorrect password");
  };

  const requestAccess = async () => {
    setBadText("Invaild email format!");
    const result = await dataContext.requestAdmin(email, password);

    if (result) {
      setBadText("");
      setRequested(true);
    } else {
      setBadText("Email is awaiting response or rejected");
    }
  };

  return (
    <>
      <Dialog
        open={!dataContext.loggedIn}
        scroll="body"
        fullWidth
        maxWidth="sm"
      >
        <DialogTitle>CornellGO! Manager</DialogTitle>
        <DialogContent>
          <Grid container>
            <Grid container>
              <TextField
                label="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{ marginBottom: 4 }}
                error={badText.length > 0}
                helperText={badText}
                fullWidth
              />
              <TextField
                label="Password"
                value={password}
                type="password"
                onChange={(e) => setPassword(e.target.value)}
                style={{ marginBottom: 4 }}
                error={passBadText.length > 0}
                helperText={passBadText}
                fullWidth
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={login} color="primary">
            Login
          </Button>
          <Button onClick={requestAccess} color="primary">
            Request Access
          </Button>
        </DialogActions>
      </Dialog>
      <Snackbar
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
        open={requested}
        autoHideDuration={6000}
        onClose={() => setRequested(false)}
        message="Requested admin access"
      />
      {dataContext.loggedIn && props.children}
    </>
  );
}
