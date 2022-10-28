import { useContext, useState } from "react";
import { AlertModal } from "./AlertModal";
import { ServerDataContext } from "./ServerData";

export function ErrorAlert() {
  const serverData = useContext(ServerDataContext);

  const [open, setOpen] = useState(true);

  return (
    <>
      {Array.from(serverData.errors.values()).map((er) => (
        <AlertModal
          isOpen={open}
          description={er.error}
          onClose={() => {
            serverData.errors.delete("error");
            setOpen(false);
          }}
        ></AlertModal>
      ))}
    </>
  );
}
