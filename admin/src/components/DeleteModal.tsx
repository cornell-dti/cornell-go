import { Modal } from "./Modal";

export function DeleteModal(props: {
  isOpen: boolean;
  objectName: string;
  onDelete: () => void;
  onClose: () => void;
}) {
  return (
    <Modal
      title="Confirm Deletion"
      buttons={["YES", "NO"]}
      onButtonClick={(idx) => {
        if (idx === 0) props.onDelete();
        else props.onClose();
      }}
      isOpen={props.isOpen}
    >
      Are you sure you want to delete "{props.objectName}"?
    </Modal>
  );
}
