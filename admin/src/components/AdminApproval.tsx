import {
  Card,
  CardHeader,
  CardContent,
  Typography,
  CardActions,
  Button,
  Grid,
} from "@material-ui/core";
import { useContext } from "react";

import { ServerDataContext } from "./ServerData";

type AdminCardProps = {
  name: string;
};

function AdminCard({ name }: AdminCardProps) {
  const dataContext = useContext(ServerDataContext);

  return (
    <Card>
      <CardHeader title="Request for Admin Access" />
      <CardContent>
        <Typography variant="body1" component="span">
          Email Address:
        </Typography>
        <Typography variant="body2" component="span">
          {" " + name}
        </Typography>
      </CardContent>
      <CardActions>
        <Button
          size="small"
          onClick={() => dataContext.updateAdmin(name, true)}
        >
          Approve
        </Button>
        <Button
          size="small"
          onClick={() => dataContext.updateAdmin(name, false)}
          color="secondary"
        >
          Deny
        </Button>
      </CardActions>
    </Card>
  );
}

export default function AdminApproval() {
  const dataContext = useContext(ServerDataContext);

  return (
    <Grid container justify="center">
      {dataContext.unapprovedAdmins.length === 0 ? (
        <Typography>No admins need approval</Typography>
      ) : null}
      {dataContext.unapprovedAdmins.map((name) => (
        <Grid container style={{ marginBottom: 16 }} key={name}>
          <Grid xs={3} item />
          <Grid xs={6} item>
            <AdminCard name={name} />
          </Grid>
        </Grid>
      ))}
    </Grid>
  );
}
