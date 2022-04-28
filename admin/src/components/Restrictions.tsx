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
          Events: <b>{props.restriction.allowedEvents.join(", ")}</b> <br />
          User Count: <b>{props.restriction.restrictedUsers.length}</b> <br />
          Generated Users:{" "}
          <b>{props.restriction.generatedUserAuthIds.join(", ")}</b> <br />
          Username Editing Enabled:{" "}
          <b>{affirmOfBool(props.restriction.canEditUsername)}</b> <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onAdd}>ADD EVENT</HButton>
          <HButton onClick={props.onClear}>CLEAR EVENTS</HButton>
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
    { name: "Name", characterLimit: 256, value: "" },
    { name: "Can Edit Username", options: ["No", "Yes"], value: 0 },
    {
      name: "Users to Generate",
      min: 0,
      max: 99,
      value: 0,
    },
  ] as EntryForm[];
}

function fromForm(
  form: EntryForm[],
  id: string,
  oldDto: RestrictionDto
): RestrictionDto {
  return {
    ...oldDto,
    id,
    displayName: (form[0] as FreeEntryForm).value,
    canEditUsername: (form[1] as OptionEntryForm).value === 1,
    generatedUserCount: (form[2] as NumberEntryForm).value,
  };
}

function toForm(group: RestrictionDto) {
  return [
    { name: "Display Name", characterLimit: 256, value: group.displayName },
    {
      name: "Can Edit Username",
      options: ["No", "Yes"],
      value: group.canEditUsername ? 1 : 0,
    },
    {
      name: "Users to Generate",
      min: 0,
      max: 99,
      value: group.generatedUserCount,
    },
  ] as EntryForm[];
}

const emptyDto: RestrictionDto = {
  id: "",
  displayName: "",
  canEditUsername: false,
  restrictedUsers: [],
  allowedEvents: [],
  generatedUserAuthIds: [],
  generatedUserCount: 0,
};

export function Restrictions() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState("");
  const [query, setQuery] = useState("");
  const [oldDto, setOldDto] = useState(emptyDto);

  return (
    <>
      <EntryModal
        title="Create Group"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateRestriction(fromForm(form, "", emptyDto));
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
          serverData.updateRestriction(fromForm(form, currentId, oldDto));
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
              setOldDto(r);
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
