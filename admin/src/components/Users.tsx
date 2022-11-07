import { useContext, useState } from "react";
import { UserDto } from "../dto/update-users.dto";
import { DeleteModal } from "./DeleteModal";
import {
  EntryModal,
  EntryForm,
  OptionEntryForm,
  FreeEntryForm,
} from "./EntryModal";
import { HButton } from "./HButton";
import {
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";
import { ServerDataContext } from "./ServerData";

import { compareTwoStrings } from "string-similarity";
import { isPropertySignature } from "typescript";
import { AlertModal } from "./AlertModal";
import GridTable from "@nadavshaar/react-grid-table";

function UserCard(props: {
  user: UserDto;
  onEdit: () => void;
  onDelete: () => void;
}) {
  return (
    <>
      <ListCardBox>
        <ListCardTitle>{props.user.username}</ListCardTitle>
        <ListCardBody>
          Id: <b>{props.user.id}</b> <br />
          Group Id: <b>{props.user.groupId}</b> <br />
          Email: <b>{props.user.email}</b> <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onDelete} float="right">
            DELETE
          </HButton>
          <HButton onClick={props.onEdit} float="right">
            EDIT
          </HButton>
        </ListCardButtons>
      </ListCardBox>
    </>
  );
}

function makeForm() {
  return [
    { name: "Username", characterLimit: 256, value: "" },
    { name: "Email", characterLimit: 256, value: "" },
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], id: string, groupId: string): UserDto {
  return {
    id,
    username: (form[0] as FreeEntryForm).value,
    email: (form[1] as FreeEntryForm).value,
    groupId,
  };
}

function toForm(user: UserDto) {
  return [
    { name: "Username", characterLimit: 256, value: user.username },
    { name: "Email", characterLimit: 256, value: user.email },
  ] as EntryForm[];
}

const cols = [
  {
    id: "checkbox",
    visible: true,
    pinned: true,
    width: "54px",
  },
  {
    id: 1,
    field: "username",
    label: "Username",
  },
  {
    id: 2,
    field: "id",
    label: "Id",
    editable: false,
  },
  {
    id: 3,
    field: "groupId",
    label: "GroupId",
    editable: false,
  },
  {
    id: 4,
    field: "email",
    label: "Email",
  },
];

const rows = [
  {
    username: "NAME",
    id: "randomID",
    groupId: "randomGroupID",
    email: "gmail.com",
  },
];

const Table = <GridTable columns={cols} rows={rows} />;
export function Users() {
  return Table;
}
