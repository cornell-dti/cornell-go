import { Modal } from "./Modal";

type OptionEntryForm = {
  name: string;
  index: number;
  options: string[];
};

type FreeEntryForm = {
  name: string;
  value: string;
  characterLimit: number;
};

type NumberEntryForm = {
  name: string;
  value: number;
  min: number;
  max: number;
};

type MapEntryForm = {
  name: string;
  latitude: number;
  longitude: number;
};

type EntryForm =
  | OptionEntryForm
  | FreeEntryForm
  | NumberEntryForm
  | MapEntryForm;

function EntryModal(props: {
  title: string;
  form: EntryForm[];
  isOpen: boolean;
  onEntry: () => {};
  onCancel: () => {};
}) {
  return (
    <Modal
      title={props.title}
      buttons={["CANCEL", "CONFIRM"]}
      isOpen={props.isOpen}
      onButtonClick={(idx) => {
        if (idx === 0) props.onCancel();
        else props.onEntry();
      }}
    >
      {props.form.map((form) => {
        if ("index" in form) {
        } else if ("characterLimit" in form) {
        } else if ("min" in form) {
        } else {
        }
      })}
    </Modal>
  );
}
