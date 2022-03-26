import { useContext, useState } from "react";
import styled from "styled-components";
import { HButton } from "./HButton";
import { Modal } from "./Modal";
import { ServerDataContext } from "./ServerData";

const AdminApprovalEntryBox = styled.div`
  border-radius: 6px;
  width: 100%;
  box-shadow: 0 0 2px 0.1px black;
  padding: 10px 10px 10px 12px;
  margin-bottom: 12px;
  line-height: 30px;
  font-size: 18px;
`;

function AdminApprovalEntry(props: {
  email: string;
  onApprove: () => void;
  onDeny: () => void;
}) {
  return (
    <AdminApprovalEntryBox>
      <b>{props.email}</b> is requesting admin access
      <HButton float="right" onClick={props.onDeny}>
        Deny
      </HButton>
      <HButton float="right" onClick={props.onApprove}>
        Approve
      </HButton>
    </AdminApprovalEntryBox>
  );
}

export function Admins() {
  const serverData = useContext(ServerDataContext);
  const [actionAdmin, setActionAdmin] = useState({ id: "", email: "" });
  const [approveModal, setApproveModal] = useState(false);
  const [denyModal, setDenyModal] = useState(false);

  return (
    <>
      <Modal
        title="Approval Confirmation"
        buttons={["CANCEL", "APPROVE"]}
        isOpen={approveModal}
        onButtonClick={(idx) => {
          if (idx === 1) {
            serverData.setAdminStatus(actionAdmin.id, true);
          }
          setApproveModal(false);
        }}
      >
        Are you sure you want to approve <b>{actionAdmin.email}</b>?
      </Modal>
      <Modal
        title="Denial Confirmation"
        buttons={["CANCEL", "DENY"]}
        isOpen={denyModal}
        onButtonClick={(idx) => {
          if (idx === 1) {
            serverData.setAdminStatus(actionAdmin.id, false);
          }
          setDenyModal(false);
        }}
      >
        Are you sure you want to deny <b>{actionAdmin.email}</b>?
      </Modal>
      {serverData.admins.size === 0
        ? "No Admins to Approve"
        : Array.from(serverData.admins.values()).map((admin) => (
            <AdminApprovalEntry
              email={admin.email}
              key={admin.id}
              onApprove={() => {
                setActionAdmin(admin);
                setApproveModal(true);
              }}
              onDeny={() => {
                setActionAdmin(admin);
                setDenyModal(true);
              }}
            />
          ))}
    </>
  );
}
