import { Modal } from './Modal';

export function AlertModal(props: {
  isOpen: boolean;
  description: string;
  onClose: () => void;
}) {
  return (
    <Modal
      title="Alert"
      buttons={['OK']}
      onButtonClick={idx => {
        props.onClose();
      }}
      isOpen={props.isOpen}
    >
      {props.description}
    </Modal>
  );
}
