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
    groupId
  };
}

function toForm(user: UserDto) {
  return [
    { name: "Username", characterLimit: 256, value: user.username },
    { name: "Email", characterLimit: 256, value: user.email },
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
      <AlertModal
        description="Can not create a user."
        isOpen={isCreateModalOpen}
        onClose={() => setCreateModalOpen(false)}
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

