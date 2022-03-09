import { createContext, useState, useRef, useEffect, ReactNode } from "react";

export type ServerPlace = {
  id: string;
  imageUrl: string;
  name: string;
  description: string;
  points: number;
  lat: number;
  long: number;
  radius: number;
  citationUrl: string;
  linkUrl: string;
  longDescription: string;
};

export type ServerDataType = {
  places: ServerPlace[];
  unapprovedAdmins: string[];
  loggedIn: boolean;
  addPlace: (place: ServerPlace) => void;
  deletePlace: (id: string) => void;
  modifyPlace: (id: string, place: ServerPlace) => void;
  updateAdmin: (name: string, approve: boolean) => void;
  login: (name: string, password: string) => Promise<ServerLoginResult>;
  requestAdmin: (name: string, password: string) => Promise<boolean>;
};

export enum ServerLoginResult {
  NoAdminApproval = 0,
  AdminRejected = 1,
  NoAccount = 2,
  WrongPassword = 3,
  Success = 4,
}

export enum PlaceDataModifiedState {
  Created = 0,
  Destroyed = 1,
  Modified = 2,
}

export const ServerDataContext = createContext({
  places: [],
  unapprovedAdmins: [],
  loggedIn: false,
  addPlace: (p) => {},
  deletePlace: (id) => {},
  modifyPlace: (i, p) => {},
  updateAdmin: (name, approve) => {},
  login: async (name, password) => ServerLoginResult.AdminRejected,
  requestAdmin: async (name, password) => false,
} as ServerDataType);

export function ServerData(props: { children: ReactNode }) {
  const [places, setPlaces] = useState([] as ServerPlace[]);
  const [unapprovedAdmins, setUnapprovedAdmins] = useState([] as string[]);
  const [loggedIn, setLoggedIn] = useState(false);

  const methodRef = useRef({
    modified: (state: PlaceDataModifiedState, data: ServerPlace) => {},
    approval: (email: string, approval: boolean) => {},
    logout: () => {},
  });

  const placesRef = useRef([] as ServerPlace[]);

  useEffect(() => {
    methodRef.current.modified = (
      state: PlaceDataModifiedState,
      data: ServerPlace
    ) => {
      switch (state) {
        case PlaceDataModifiedState.Created:
          setPlaces([data, ...places]);
          break;
        case PlaceDataModifiedState.Destroyed:
          setPlaces(places.filter((place) => place.id !== data.id));
          break;
        case PlaceDataModifiedState.Modified:
          {
            const idx = places.findIndex((place) => place.id === data.id);
            console.log(idx, places);
            if (idx >= 0) {
              places[idx] = data;
              setPlaces([...places]);
            }
          }
          break;
      }
    };

    methodRef.current.approval = (email: string, approved: boolean) => {
      if (approved)
        setUnapprovedAdmins(
          unapprovedAdmins.filter((admin) => admin !== email)
        );
      else setUnapprovedAdmins([...unapprovedAdmins, email]);
    };
    methodRef.current.logout = () => {
      setLoggedIn(false);
    };
  });

  const data: ServerDataType = {
    places,
    unapprovedAdmins,
    loggedIn,
    addPlace: (p) => {},
    deletePlace: (id) => {},
    modifyPlace: (id, p) => {},
    updateAdmin: (name, approve) => {},
    login: async (name, password) => {
      return null as unknown as ServerLoginResult;
    },
    requestAdmin: async (name, password) => {
      return false;
    },
  };
  return (
    <ServerDataContext.Provider value={data}>
      {props.children}
    </ServerDataContext.Provider>
  );
}
