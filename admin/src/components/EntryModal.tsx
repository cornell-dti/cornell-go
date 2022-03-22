import { useEffect, useRef, useState } from "react";
import { Modal } from "./Modal";
import styled from "styled-components";

export type OptionEntryForm = {
  name: string;
  index: number;
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
`;

const EntryTextBox = styled.input`
  font-size: 18px;
  margin-left: 12px;
  border-width: 1px;
  height: 28px;
  border-radius: 2px;
  width: calc(100% - 192px);
`;

const EntrySelect = styled.select`
  margin-left: 12px;
  border-width: 1px;
  height: 24px;
  border-radius: 2px;
`;

function OptionEntryFormBox(props: { form: OptionEntryForm }) {
  return (
    <EntryBox>
      <label htmlFor={props.form.name}>{props.form.name + ":"}</label>
      <EntrySelect name={props.form.name}>
        {props.form.options.map((val) => (
          <option key={val}>{val}</option>
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

  useEffect(() => setVal(props.form.date.toISOString()), [props.form]);

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

function MapEntryFormBox(props: { form: MapEntryForm }) {
  return <EntryBox></EntryBox>;
}

export function EntryModal(props: {
  title: string;
  form: EntryForm[];
  isOpen: boolean;
  onEntry: (form: EntryForm[]) => void;
  onCancel: () => void;
}) {
  const formRef = useRef(props.form);

  useEffect(() => {
    if (props.isOpen) {
      formRef.current = props.form;
    }
  }, [props.isOpen]);

  return (
    <Modal
      title={props.title}
      buttons={["CONFIRM", "CANCEL"]}
      isOpen={props.isOpen}
      onButtonClick={(idx) => {
        if (idx === 1) props.onCancel();
        else props.onEntry(formRef.current);
      }}
    >
      {formRef.current.map((form) => {
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
