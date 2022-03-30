import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Modal } from "./Modal";
import styled from "styled-components";
import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";

export type OptionEntryForm = {
  name: string;
  value: number;
  options: string[];
};

export type FreeEntryForm = {
  name: string;
  value: string;
  characterLimit: number;
};

export type NumberEntryForm = {
  name: string;
  value: number;
  min: number;
  max: number;
};

export type MapEntryForm = {
  name: string;
  latitude: number;
  longitude: number;
};

export type DateEntryForm = {
  name: string;
  date: Date;
};

export type EntryForm =
  | OptionEntryForm
  | FreeEntryForm
  | NumberEntryForm
  | MapEntryForm
  | DateEntryForm;

const EntryBox = styled.div`
  margin-bottom: 12px;
  display: flex;
  flex-direction: row;
`;

const EntryTextBox = styled.input`
  font-size: 18px;
  margin-left: 12px;
  border-width: 1px;
  height: 28px;
  border-radius: 2px;
  flex-grow: 1;
`;

const EntrySelect = styled.select`
  margin-left: 12px;
  border-width: 1px;
  height: 24px;
  border-radius: 2px;
`;

function OptionEntryFormBox(props: { form: OptionEntryForm }) {
  const [val, setVal] = useState(props.form.options[props.form.value]);

  useEffect(() => setVal(props.form.options[props.form.value]), [props.form]);

  return (
    <EntryBox>
      <label htmlFor={props.form.name}>{props.form.name + ":"}</label>
      <EntrySelect
        name={props.form.name}
        value={val}
        onChange={(e) =>
          setVal(
            props.form.options[(props.form.value = e.target.selectedIndex)]
          )
        }
      >
        {props.form.options.map((val) => (
          <option key={val} onSelect={() => console.log(val)}>
            {val}
          </option>
        ))}
      </EntrySelect>
    </EntryBox>
  );
}

function FreeEntryFormBox(props: { form: FreeEntryForm }) {
  const [val, setVal] = useState("");

  useEffect(() => setVal(props.form.value), [props.form]);

  return (
    <EntryBox>
      <span>{props.form.name + ":"}</span>
      <EntryTextBox
        value={val}
        onChange={(e) => setVal((props.form.value = e.target.value))}
      />
    </EntryBox>
  );
}

function DateEntryFormBox(props: { form: DateEntryForm }) {
  const [val, setVal] = useState("");

  useEffect(
    () => setVal(props.form.date.toISOString().slice(0, -1)),
    [props.form]
  );

  return (
    <EntryBox>
      <span>{props.form.name + ":"}</span>
      <EntryTextBox
        type="datetime-local"
        value={val}
        onChange={(e) => {
          setVal(e.target.value);
          props.form.date = new Date(e.target.value);
        }}
      />
    </EntryBox>
  );
}

function NumberEntryFormBox(props: { form: NumberEntryForm }) {
  const [val, setVal] = useState("");

  useEffect(() => setVal("" + props.form.value), [props.form]);

  return (
    <EntryBox>
      {props.form.name + ": "}
      <EntryTextBox
        type="number"
        value={val}
        min={props.form.min}
        max={props.form.max}
        onChange={(e) => {
          setVal(e.target.value);
          props.form.value = +e.target.value;
        }}
      />
    </EntryBox>
  );
}

const MapBox = styled.div`
  width: 100%;
  height: 300px;
  margin-bottom: 32px;
  overflow: hidden;
`;

function DraggableMarker(props: {
  center: [number, number];
  onLocationChange: (lat: number, long: number) => void;
}) {
  const [position, setPosition] = useState(props.center);
  const markerRef = useRef<any>(null);
  const eventHandlers = useMemo(
    () => ({
      dragend() {
        const marker = markerRef.current;
        if (marker != null) {
          const { lat, lng } = marker.getLatLng();
          props.onLocationChange(lat, lng);
          setPosition(marker.getLatLng());
        }
      },
    }),
    []
  );

  return (
    <Marker
      draggable={true}
      eventHandlers={eventHandlers}
      position={position}
      ref={markerRef}
    >
      <Popup minWidth={90}>
        <span>Drag the pin to move the location</span>
      </Popup>
    </Marker>
  );
}

function MapEntryFormBox(props: { form: MapEntryForm }) {
  return (
    <MapBox>
      <MapContainer
        center={[props.form.latitude, props.form.longitude]}
        zoom={20}
        style={{
          width: "100%",
          height: 300,
        }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <DraggableMarker
          center={[props.form.latitude, props.form.longitude]}
          onLocationChange={(lat, long) => {
            props.form.latitude = lat;
            props.form.longitude = long;
          }}
        />
      </MapContainer>
    </MapBox>
  );
}

export function EntryModal(props: {
  title: string;
  form: EntryForm[];
  isOpen: boolean;
  entryButtonText: string;
  onEntry: () => void;
  onCancel: () => void;
}) {
  return (
    <Modal
      title={props.title}
      buttons={[props.entryButtonText, "CANCEL"]}
      isOpen={props.isOpen}
      onButtonClick={(idx) => {
        if (idx === 1) props.onCancel();
        else props.onEntry();
      }}
    >
      {props.form.map((form) => {
        if ("options" in form) {
          return <OptionEntryFormBox form={form} key={form.name} />;
        } else if ("characterLimit" in form) {
          return <FreeEntryFormBox form={form} key={form.name} />;
        } else if ("min" in form) {
          return <NumberEntryFormBox form={form} key={form.name} />;
        } else if ("date" in form) {
          return <DateEntryFormBox form={form} key={form.name} />;
        } else {
          return <MapEntryFormBox form={form} key={form.name} />;
        }
      })}
    </Modal>
  );
}
