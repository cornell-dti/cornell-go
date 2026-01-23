import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Modal } from './Modal';
import styled from 'styled-components';
import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet';

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

export type AnswersEntryForm = {
  name: string;
  answers: Array<{ text: string; isCorrect: boolean }>;
  minAnswers: number;
  maxAnswers: number;
};

export type OptionWithCustomEntryForm = {
  name: string;
  value: number;
  options: string[];
  customValue: string;
  customOptionLabel: string;
};

export type EntryForm =
  | OptionEntryForm
  | FreeEntryForm
  | NumberEntryForm
  | MapEntryForm
  | DateEntryForm
  | AnswersEntryForm
  | OptionWithCustomEntryForm;

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
      <label htmlFor={props.form.name}>{props.form.name + ':'}</label>
      <EntrySelect
        name={props.form.name}
        value={val}
        onChange={e =>
          setVal(
            props.form.options[(props.form.value = e.target.selectedIndex)],
          )
        }
      >
        {props.form.options.map(val => (
          <option key={val} onSelect={() => console.log(val)}>
            {val}
          </option>
        ))}
      </EntrySelect>
    </EntryBox>
  );
}

function FreeEntryFormBox(props: { form: FreeEntryForm }) {
  const [val, setVal] = useState('');

  useEffect(() => setVal(props.form.value), [props.form]);

  return (
    <EntryBox>
      <span>{props.form.name + ':'}</span>
      <EntryTextBox
        value={val}
        maxLength={props.form.characterLimit}
        onChange={e => setVal((props.form.value = e.target.value))}
      />
    </EntryBox>
  );
}

function DateEntryFormBox(props: { form: DateEntryForm }) {
  const [val, setVal] = useState('');

  useEffect(
    () => setVal(props.form.date.toISOString().slice(0, -1)),
    [props.form],
  );

  return (
    <EntryBox>
      <span>{props.form.name + ':'}</span>
      <EntryTextBox
        type="datetime-local"
        value={val}
        onChange={e => {
          setVal(e.target.value);
          props.form.date = new Date(e.target.value);
        }}
      />
    </EntryBox>
  );
}

function NumberEntryFormBox(props: { form: NumberEntryForm }) {
  const [val, setVal] = useState('');

  useEffect(() => setVal('' + props.form.value), [props.form]);

  return (
    <EntryBox>
      {props.form.name + ': '}
      <EntryTextBox
        type="number"
        value={val}
        min={props.form.min}
        max={props.form.max}
        onChange={e => {
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
    [],
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
  const [lat, setLat] = useState(props.form.latitude);
  const [lng, setLng] = useState(props.form.longitude);

  useEffect(() => {
    setLat(props.form.latitude);
    setLng(props.form.longitude);
  }, [props.form.latitude, props.form.longitude]);

  const handleLatChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLat = parseFloat(e.target.value);
    if (!isNaN(newLat)) {
      setLat(newLat);
      props.form.latitude = newLat;
    }
  };

  const handleLngChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLng = parseFloat(e.target.value);
    if (!isNaN(newLng)) {
      setLng(newLng);
      props.form.longitude = newLng;
    }
  };

  return (
    <>
      <MapBox>
        <MapContainer
          center={[lat, lng]}
          zoom={20}
          style={{
            width: '100%',
            height: 300,
          }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <DraggableMarker
            center={[lat, lng]}
            onLocationChange={(newLat, newLng) => {
              setLat(newLat);
              setLng(newLng);
              props.form.latitude = newLat;
              props.form.longitude = newLng;
            }}
          />
        </MapContainer>
      </MapBox>
      <EntryBox>
        <span>Latitude:</span>
        <EntryTextBox type="number" value={lat} onChange={handleLatChange} />
      </EntryBox>
      <EntryBox>
        <span>Longitude:</span>
        <EntryTextBox type="number" value={lng} onChange={handleLngChange} />
      </EntryBox>
    </>
  );
}

// Styled components for AnswersEntryForm
const AnswerRow = styled.div`
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  gap: 8px;
`;

const AnswerInput = styled.input`
  flex: 1;
  font-size: 16px;
  padding: 4px 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
`;

const CorrectRadio = styled.input`
  width: 18px;
  height: 18px;
  cursor: pointer;
`;

const AnswerButton = styled.button`
  padding: 4px 12px;
  cursor: pointer;
  border: 1px solid #ccc;
  border-radius: 4px;
  background: #f5f5f5;
  &:hover {
    background: #e0e0e0;
  }
`;

const AnswersContainer = styled.div`
  margin-bottom: 16px;
`;

function AnswersEntryFormBox(props: { form: AnswersEntryForm }) {
  const [answers, setAnswers] = useState(props.form.answers);

  useEffect(() => {
    setAnswers([...props.form.answers]);
  }, [props.form]);

  const updateAnswerText = (index: number, text: string) => {
    const newAnswers = [...answers];
    newAnswers[index].text = text;
    setAnswers(newAnswers);
    props.form.answers = newAnswers;
  };

  const toggleCorrect = (index: number) => {
    const newAnswers = answers.map((a, i) => ({
      ...a,
      isCorrect: i === index,
    }));
    setAnswers(newAnswers);
    props.form.answers = newAnswers;
  };

  const addAnswer = () => {
    if (answers.length < props.form.maxAnswers) {
      const newAnswers = [...answers, { text: '', isCorrect: false }];
      setAnswers(newAnswers);
      props.form.answers = newAnswers;
    }
  };

  const removeAnswer = (index: number) => {
    if (answers.length > props.form.minAnswers) {
      const newAnswers = answers.filter((_, i) => i !== index);
      if (!newAnswers.some(a => a.isCorrect) && newAnswers.length > 0) {
        newAnswers[0].isCorrect = true;
      }
      setAnswers(newAnswers);
      props.form.answers = newAnswers;
    }
  };

  return (
    <AnswersContainer>
      <div style={{ marginBottom: 8 }}>{props.form.name}:</div>
      {answers.map((answer, index) => (
        <AnswerRow key={index}>
          <CorrectRadio
            type="radio"
            name="correctAnswer"
            checked={answer.isCorrect}
            onChange={() => toggleCorrect(index)}
            title="Mark as correct"
          />
          <AnswerInput
            value={answer.text}
            placeholder={`Answer ${index + 1}`}
            onChange={e => updateAnswerText(index, e.target.value)}
          />
          {answers.length > props.form.minAnswers && (
            <AnswerButton onClick={() => removeAnswer(index)}>-</AnswerButton>
          )}
        </AnswerRow>
      ))}
      {answers.length < props.form.maxAnswers && (
        <AnswerButton onClick={addAnswer}>+ Add Answer</AnswerButton>
      )}
    </AnswersContainer>
  );
}

function OptionWithCustomEntryFormBox(props: {
  form: OptionWithCustomEntryForm;
}) {
  const [selectedIndex, setSelectedIndex] = useState(props.form.value);
  const [customText, setCustomText] = useState(props.form.customValue);

  const isCustomSelected = selectedIndex === props.form.options.length;

  useEffect(() => {
    setSelectedIndex(props.form.value);
    setCustomText(props.form.customValue);
  }, [props.form]);

  return (
    <>
      <EntryBox>
        <label htmlFor={props.form.name}>{props.form.name + ':'}</label>
        <EntrySelect
          name={props.form.name}
          value={
            isCustomSelected
              ? props.form.customOptionLabel
              : props.form.options[selectedIndex]
          }
          onChange={e => {
            const idx = e.target.selectedIndex;
            setSelectedIndex(idx);
            props.form.value = idx;
          }}
        >
          {props.form.options.map(opt => (
            <option key={opt}>{opt}</option>
          ))}
          <option>{props.form.customOptionLabel}</option>
        </EntrySelect>
      </EntryBox>
      {isCustomSelected && (
        <EntryBox>
          <span>Custom value:</span>
          <EntryTextBox
            value={customText}
            placeholder="Enter custom category"
            onChange={e => {
              setCustomText(e.target.value);
              props.form.customValue = e.target.value;
            }}
          />
        </EntryBox>
      )}
    </>
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
      buttons={[props.entryButtonText, 'CANCEL']}
      isOpen={props.isOpen}
      onButtonClick={idx => {
        if (idx === 1) props.onCancel();
        else props.onEntry();
      }}
    >
      {props.form.map(form => {
        if ('answers' in form) {
          return <AnswersEntryFormBox form={form} key={form.name} />;
        } else if ('customOptionLabel' in form) {
          return <OptionWithCustomEntryFormBox form={form} key={form.name} />;
        } else if ('options' in form) {
          return <OptionEntryFormBox form={form} key={form.name} />;
        } else if ('characterLimit' in form) {
          return <FreeEntryFormBox form={form} key={form.name} />;
        } else if ('min' in form) {
          return <NumberEntryFormBox form={form} key={form.name} />;
        } else if ('date' in form) {
          return <DateEntryFormBox form={form} key={form.name} />;
        } else {
          return <MapEntryFormBox form={form} key={form.name} />;
        }
      })}
    </Modal>
  );
}
