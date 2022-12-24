import { useContext, useState } from "react";
import { AlertModal } from "./AlertModal";
import { ServerDataContext } from "./ServerData";
import { Modal } from "./Modal";

function ErrorModal(props: { description: string; onClose: () => void }) {
  const [open, setOpen] = useState(true);
  const handleClose = () => setOpen(false);

  return (
    <Modal
      title="Alert"
      buttons={["OK"]}
      onButtonClick={(idx) => {
        handleClose();
        props.onClose();
      }}
      isOpen={open}
    >
      {props.description}
    </Modal>
  );
}

export function ErrorAlert() {
  const serverData = useContext(ServerDataContext);

  return (
    <>
      {Array.from(serverData.errors.values()).map((er) => (
        <ErrorModal
          description={er.message}
          onClose={() => {
            console.log(er);
            serverData.deleteError("Error");
          }}
        ></ErrorModal>
      ))}
    </>
  );
}
