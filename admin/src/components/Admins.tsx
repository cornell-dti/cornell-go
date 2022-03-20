import styled from "styled-components";
import { HButton } from "./HButton";

const AdminApprovalEntryBox = styled.div`
  border-radius: 4px;
  width: 100%;
  height: 48px;
  box-shadow: 0 0 2px black;
  padding-left: 12px;
  margin-bottom: 12px;
  line-height: 30px;
  font-size: 18px;
  padding-top: 10px;
  padding-right: 10px;
`;

function AdminApprovalEntry(props: { email: string }) {
  return (
    <AdminApprovalEntryBox>
      <b>{props.email}</b> is requesting admin access
      <HButton float="right">Deny</HButton>
      <HButton float="right">Approve</HButton>
    </AdminApprovalEntryBox>
  );
}

export function Admins() {
  return (
    <>
      <AdminApprovalEntry email="nk495@cornell.edu" />
      <AdminApprovalEntry email="nk495@cornell.edu" />
    </>
  );
}
