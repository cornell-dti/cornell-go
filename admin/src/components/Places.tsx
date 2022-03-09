import {
  Container,
  Paper,
  Grid,
  TextField,
  Button,
  Box,
  Divider,
  CardHeader,
  CardMedia,
  CardContent,
  CardActions,
  InputAdornment,
  Typography,
  IconButton,
  Card,
  makeStyles,
  Dialog,
  DialogContentText,
  DialogTitle,
  DialogContent,
  DialogActions,
} from "@material-ui/core";

import { Delete, Edit, Search } from "@material-ui/icons";

import { useState, useContext, useEffect, useRef } from "react";
import * as StringSimilarity from "string-similarity";

import { ServerPlace, ServerDataContext } from "./ServerData";

type PlaceCardProps = {
  id: string;
  name: string;
  imageUrl: string;
  description: string;
  points: number;
  remove: (id: string) => void;
  edit: (id: string) => void;
};

const useStyles = makeStyles((theme) => ({
  media: {
    paddingTop: "40%",
  },
}));

function PlaceCard({
  id,
  name,
  imageUrl,
  description,
  points,
  remove,
  edit,
}: PlaceCardProps) {
  const classes = useStyles();
  return (
    <Card>
      <CardHeader
        action={
          <IconButton onClick={() => edit(id)}>
            <Edit />
          </IconButton>
        }
        title={name}
        subheader={points + (points === 1 ? " point" : " points")}
      />
      <CardMedia image={imageUrl} className={classes.media} />
      <CardContent>
        <Typography variant="body2" color="textSecondary" component="p">
          {description}
        </Typography>
      </CardContent>
      <CardActions disableSpacing>
        <IconButton onClick={() => remove(id)}>
          <Delete />
        </IconButton>
      </CardActions>
    </Card>
  );
}

type PlaceDialogProps = {
  id: string;
  close: () => void;
  isOpen: boolean;
};

function DeleteDialog({ id, close, isOpen }: PlaceDialogProps) {
  const dataContext = useContext(ServerDataContext);

  const del = () => {
    dataContext.deletePlace(id);
    close();
  };

  return (
    <Dialog open={isOpen} onClose={close}>
      <DialogTitle>Delete this place?</DialogTitle>
      <DialogContent>
        <DialogContentText id="alert-dialog-description">
          Are you sure you want to delete "
          {dataContext.places.find((place) => place.id === id)?.name}
          "?
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={close} color="primary">
          Cancel
        </Button>
        <Button onClick={del} color="secondary" autoFocus>
          Delete
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function EditorDialog({ id, close, isOpen }: PlaceDialogProps) {
  const emptyPlace: ServerPlace = {
    name: "",
    id: "",
    imageUrl: "",
    description: "",
    lat: 0,
    long: 0,
    points: 0,
    radius: 0,
    citationUrl: "",
    linkUrl: "",
    longDescription: "",
  };

  const [data, setData] = useState(emptyPlace);
  const dataContext = useContext(ServerDataContext);

  useEffect(() => {
    if (isOpen) {
      if (id === "_new") setData(emptyPlace);
      else {
        const place = dataContext.places.find((place) => place.id === id);
        if (place) setData(place);
      }
    }
  }, [isOpen, id, dataContext]);

  const finish = () => {
    if (id === "_new") dataContext.addPlace(data);
    else dataContext.modifyPlace(id, data);
    close();
  };

  return (
    <Dialog open={isOpen} onClose={close} scroll="body" fullWidth maxWidth="sm">
      <DialogTitle>{id === "_new" ? "New Place" : "Edit Place"}</DialogTitle>
      <DialogContent>
        <Grid container>
          <Grid container>
            <TextField
              label="Name"
              value={data.name}
              onChange={(e) => setData({ ...data, name: e.target.value })}
              inputProps={{
                maxLength: 60,
              }}
              style={{ marginBottom: 4 }}
              fullWidth
            />
          </Grid>
          <Grid container>
            <TextField
              label="Points"
              value={data.points}
              onChange={(e) =>
                setData({ ...data, points: parseInt(e.target.value) })
              }
              type="number"
              style={{ marginBottom: 8 }}
              fullWidth
            />
          </Grid>
          <Grid container>
            <TextField
              label="Latitude"
              type="number"
              value={data.lat}
              onChange={(e) =>
                setData({ ...data, lat: parseFloat(e.target.value) })
              }
              style={{ marginBottom: 8 }}
              fullWidth
            />
          </Grid>
          <Grid container>
            <TextField
              label="Longitude"
              type="number"
              value={data.long}
              onChange={(e) =>
                setData({ ...data, long: parseFloat(e.target.value) })
              }
              style={{ marginBottom: 8 }}
              fullWidth
            />
          </Grid>
          <Grid container>
            <TextField
              label="Awarding distance in meters"
              type="number"
              value={data.radius}
              onChange={(e) =>
                setData({ ...data, radius: parseFloat(e.target.value) })
              }
              style={{ marginBottom: 8 }}
              fullWidth
            />
          </Grid>
          <Grid container>
            <TextField
              label="Image URL"
              value={data.imageUrl}
              onChange={(e) => setData({ ...data, imageUrl: e.target.value })}
              style={{ marginBottom: 8 }}
              fullWidth
            />
          </Grid>
          <Grid container>
            <TextField
              label="Guiding Description"
              value={data.description}
              onChange={(e) =>
                setData({ ...data, description: e.target.value })
              }
              inputProps={{
                maxLength: 100,
              }}
              style={{ marginBottom: 8 }}
              fullWidth
              multiline
            />
          </Grid>
          <Grid container>
            <TextField
              label="Learn More Description"
              value={data.longDescription}
              onChange={(e) =>
                setData({ ...data, longDescription: e.target.value })
              }
              style={{ marginBottom: 8 }}
              fullWidth
              multiline
            />
          </Grid>
          <Grid container>
            <TextField
              label="Learn More Citation URL"
              value={data.citationUrl}
              onChange={(e) =>
                setData({ ...data, citationUrl: e.target.value })
              }
              style={{ marginBottom: 8 }}
              fullWidth
              multiline
            />
          </Grid>
          <Grid container>
            <TextField
              label="Learn More URL"
              value={data.linkUrl}
              onChange={(e) => setData({ ...data, linkUrl: e.target.value })}
              style={{ marginBottom: 8 }}
              fullWidth
              multiline
            />
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={close} color="primary">
          Cancel
        </Button>
        <Button onClick={finish} color="primary">
          Save
        </Button>
      </DialogActions>
    </Dialog>
  );
}

type PlaceCardEntry = {
  id: string;
  name: string;
  points: number;
  url: string;
  description: string;
};

export default function Places({}) {
  const [editorOpen, setEditorOpen] = useState(false);
  const [dialogId, setDialogId] = useState("_new");
  const [deleteOpen, setDeleteOpen] = useState(false);

  const [searchQuery, setSearchQuery] = useState("");
  const searchRef = useRef(0);

  const dataContext = useContext(ServerDataContext);

  const newPlaceClicked = () => {
    setDialogId("_new");
    setEditorOpen(true);
  };

  const editClicked = (id: string) => {
    setDialogId(id);
    setEditorOpen(true);
  };

  const deleteClicked = (id: string) => {
    setDialogId(id);
    setDeleteOpen(true);
  };

  let [items, setItems] = useState([] as PlaceCardEntry[]);

  useEffect(() => {
    const mapper = (p: ServerPlace) =>
      ({
        id: p.id,
        name: p.name,
        points: p.points,
        url: p.imageUrl,
        description: p.description,
      } as PlaceCardEntry);

    const sorter = (a: PlaceCardEntry, b: PlaceCardEntry) =>
      StringSimilarity.compareTwoStrings(b.name, searchQuery) -
      StringSimilarity.compareTwoStrings(a.name, searchQuery);

    clearTimeout(searchRef.current);
    if (searchQuery === "") {
      setItems(dataContext.places.map(mapper));
    } else {
      searchRef.current = window.setTimeout(() => {
        setItems(dataContext.places.map(mapper).sort(sorter));
      }, 300);
    }
  }, [dataContext, searchQuery]);

  return (
    <>
      <DeleteDialog
        id={dialogId}
        isOpen={deleteOpen}
        close={() => setDeleteOpen(false)}
      />
      <EditorDialog
        id={dialogId}
        isOpen={editorOpen}
        close={() => setEditorOpen(false)}
      />
      <Grid container justify="center" alignContent="center">
        <Grid
          container
          style={{ position: "sticky", top: 90, opacity: 0.95, zIndex: 100 }}
        >
          <Grid item xs={1} />
          <Grid item xs={10}>
            <Paper elevation={1}>
              <Grid container spacing={2} alignItems="center">
                <Grid item xs={6}>
                  <Box ml={1}>
                    <Button onClick={newPlaceClicked}>New Place</Button>
                  </Box>
                </Grid>
                <Grid item xs>
                  <Box mr={1}>
                    <TextField
                      id="input-with-icon-grid"
                      variant="outlined"
                      size="small"
                      type="search"
                      onChange={(e) => setSearchQuery(e.target.value)}
                      fullWidth
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <Search />
                          </InputAdornment>
                        ),
                      }}
                    />
                  </Box>
                </Grid>
              </Grid>
            </Paper>
          </Grid>
        </Grid>
        <Grid container style={{ marginTop: 32 }}>
          {items.map((item) => (
            <Grid container style={{ marginBottom: 16 }} key={item.id}>
              <Grid xs={3} item />
              <Grid xs={6} item>
                <PlaceCard
                  id={item.id}
                  name={item.name}
                  imageUrl={item.url}
                  description={item.description}
                  points={item.points}
                  edit={editClicked}
                  remove={deleteClicked}
                />
              </Grid>
            </Grid>
          ))}
        </Grid>
      </Grid>
    </>
  );
}
