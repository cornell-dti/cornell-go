import { useState } from "react";
import styled from "styled-components";
import { HButton } from "./HButton";
import { Modal } from "./Modal";

const AdminApprovalEntryBox = styled.div`
  border-radius: 4px;
  width: 100%;
  box-shadow: 0 0 2px black;
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
  const admins = [
    { id: "1", email: "nk495@cornell.edu" },
    { id: "2", email: "nk495@cornell.edu" },
  ];

  const [actionAdmin, setActionAdmin] = useState({ id: "", email: "" });
  const [approveModal, setApproveModal] = useState(false);
  const [denyModal, setDenyModal] = useState(false);

  return (
    <>
      <Modal
        title="Approval Confirmation"
        buttons={["Approve", "Cancel"]}
        isOpen={approveModal}
        onButtonClick={(idx) => {
          setApproveModal(false);
        }}
      >
        Are you sure you want to approve <b>{actionAdmin.email}</b>?
      </Modal>
      <Modal
        title="Denial Confirmation"
        buttons={["Deny", "Cancel"]}
        isOpen={denyModal}
        onButtonClick={(idx) => {
          setDenyModal(false);
        }}
      >
        Are you sure you want to deny <b>{actionAdmin.email}</b>?
      </Modal>
      {admins.map((admin) => (
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
