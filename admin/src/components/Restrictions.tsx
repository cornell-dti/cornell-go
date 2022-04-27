import { useContext, useState } from "react";
import { RestrictionDto } from "../dto/request-restrictions.dto";
import { DeleteModal } from "./DeleteModal";
import {
  EntryModal,
  EntryForm,
  NumberEntryForm,
  OptionEntryForm,
  FreeEntryForm,
  DateEntryForm,
} from "./EntryModal";
import { HButton } from "./HButton";
import {
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";
import { ServerDataContext } from "./ServerData";

import { compareTwoStrings } from "string-similarity";

function GroupCard(props: {
  restriction: RestrictionDto;
  onAdd: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onClear: () => void;
}) {
  const affirmOfBool = (val: boolean) => (val ? "Yes" : "No");

  return (
    <>
      <ListCardBox>
        <ListCardTitle>{props.restriction.displayName}</ListCardTitle>
        <ListCardBody>
          Id: <b>{props.restriction.id}</b>
          <br />
          Event Count: <b>{props.restriction.allowedEvents.length}</b> <br />
          Events: <b>{props.restriction.allowedEvents.join(", ")}</b> <br />
          User Count: <b>{props.restriction.restrictedUsers.length}</b> <br />
          Users: <b>{props.restriction.restrictedUsers.join(", ")}</b> <br />
          Username Editting Enabled:{" "}
          <b>{affirmOfBool(props.restriction.canEditUsername)}</b> <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onAdd}>Add</HButton>
          <HButton onClick={props.onDelete} float="right">
            DELETE
          </HButton>
          <HButton onClick={props.onClear} float="right">
            CLEAR EVENTS
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
    { name: "Name", characterLimit: 256, value: "" },
    { name: "Can edit username", options: ["No", "Yes"], value: 0 },
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], id: string): RestrictionDto {
  return {
    id,
    displayName: (form[0] as FreeEntryForm).value,
    canEditUsername: (form[1] as OptionEntryForm).value === 1,
    restrictedUsers: [],
    allowedEvents: [],
    generatedUserCount: 0,
    generatedUserAuthIds: [],
  };
}

function toForm(group: RestrictionDto) {
  return [
    { name: "Display Name", characterLimit: 256, value: group.displayName },
    {
      name: "Can edit username",
      options: ["No", "Yes"],
      value: group.canEditUsername ? 1 : 0,
    },
  ] as EntryForm[];
}

export function Restrictions() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState("");
  const [query, setQuery] = useState("");

  return (
    <>
      <EntryModal
        title="Create Group"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateRestriction(fromForm(form, ""));
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit Event"
        isOpen={isEditModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          serverData.updateRestriction(fromForm(form, currentId));
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.restrictions.get(currentId)?.displayName ?? ""}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteRestriction(currentId);
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
      {Array.from(serverData.restrictions.values())
        .sort(
          (a, b) =>
            compareTwoStrings(b.displayName, query) -
            compareTwoStrings(a.displayName, query)
        )
        .map((r) => (
          <GroupCard
            key={r.id}
            restriction={r}
            onAdd={() => {
              setCurrentId(r.id);
              r.allowedEvents.push(serverData.selectedEvent);
              serverData.updateRestriction(r);
            }}
            onDelete={() => {
              setCurrentId(r.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              setCurrentId(r.id);
              setForm(toForm(r));
              setEditModalOpen(true);
            }}
            onClear={() => {
              setCurrentId(r.id);
              r.allowedEvents = [];
              serverData.updateRestriction(r);
            }}
          />
        ))}
    </>
  );
}
