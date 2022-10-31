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
          Authorization Type: <b>{props.user.authType}</b> <br />
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
    {
      name: "Authorization Type",
      options: ["Google", "Apple", "Device", "None"],
      value: 0,
    },
  ] as EntryForm[];
}

var authTypes = ["google", "apple", "device", "none"];

function fromForm(form: EntryForm[], id: string, groupId: string): UserDto {
  return {
    id,
    authType: (form[2] as OptionEntryForm).value === 0
    ? "google"
    : ((form[2] as OptionEntryForm).value === 1
    ? "apple" : (form[2] as OptionEntryForm).value === 2
    ? "device" : "none"),
    username: (form[0] as FreeEntryForm).value,
    email: (form[1] as FreeEntryForm).value,
    groupId
  };
}

function toForm(user: UserDto) {
  return [
    { name: "Username", characterLimit: 256, value: user.username },
    { name: "Email", characterLimit: 256, value: user.email },
    {
      name: "Authorization Type",
      options: ["Google", "Apple", "Device", "None"],
      value: user.authType,
    },
  ] as EntryForm[];
}

export function Users() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState("");
  const [groupId, setGroupId] = useState("");
  const [query, setQuery] = useState("");

  return (
    <>
      <EntryModal
        title="Create User"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateUser(fromForm(form, "", ""));
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit User"
        isOpen={isEditModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          serverData.updateUser(
            fromForm(form, currentId, groupId)
          );
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.users.get(currentId)?.username ?? ""}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteUser(currentId);
          setDeleteModalOpen(false);
        }}
      />
      <SearchBar
        onCreate={() => {
          setForm(makeForm());
          setCreateModalOpen(true);
        }}
        onSearch={(query) => setQuery(query)}
      />
      {Array.from(serverData.users.values())
        .sort(
          (a, b) =>
            compareTwoStrings(b.username, query) -
            compareTwoStrings(a.username, query)
        )
        .map((us) => (
          <UserCard
            key={us.id}
            user={us}
            onDelete={() => {
              setCurrentId(us.id);
              setGroupId(us.groupId);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              setCurrentId(us.id);
              setGroupId(us.groupId);
              setForm(toForm(us));
              setEditModalOpen(true);
            }}
          />
        ))}
    </>
  );
}

