import { useContext, useState } from "react";
import { RestrictionDto } from "../dto/update-restrictions.dto";
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
  restrictedGroup: RestrictionDto;
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {

  const affirmOfBool = (val: boolean) => (val ? "Yes" : "No");

  return (
    <>
      <ListCardBox>
        <ListCardTitle>{props.restrictedGroup.name}</ListCardTitle>
        <ListCardBody>
          Id: <b>{props.restrictedGroup.id}</b>
          <br />
          
          Event Count: <b>{props.restrictedGroup.allowedEventsIds.length}</b> <br />
          User Count: <b>{props.restrictedGroup.restrictedUsersIds.length}</b> <br />
          Username Editting Enabled: <b>
            {affirmOfBool(props.restrictedGroup.canEditUsername)}
          </b>{" "}
          <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onSelect}>SELECT</HButton>
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
    { name: "Can edit username", options: ["No", "Yes"], value: 0}
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], id: string): RestrictedGroupDto {
  return {
    id,
    displayName : (form[0] as FreeEntryForm).value,
    name: "",
    canEditUsername: (form[1] as OptionEntryForm).value === 1,
    restrictedUsersIds: [],
    allowedEventsIds: [],
    generatedUsersIds: [],
  };
}

function toForm(group: RestrictedGroupDto) {
  return [
    { name: "Display Name", characterLimit: 256, value: group.displayName },    
    {
      name: "Can edit username",
      options: ["No", "Yes"],
      value: group.canEditUsername ? 1 : 0,
    }
  ] as EntryForm[];
}

export function RestrictedGroups() {
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
          serverData.updateRestrictedGroup(fromForm(form, ""));
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
          const { challengeIds, rewardIds } = serverData.restrictedGroups.get(currentId)!;
          serverData.updateEvent({
            ...fromForm(form, currentId),
            challengeIds,
            rewardIds,
          });
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.restrictedGroups.get(currentId)?.name ?? ""}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteEvent(currentId);
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
      {Array.from(serverData.events.values())
        .sort(
          (a, b) =>
            compareTwoStrings(b.name, query) -
            compareTwoStrings(a.name, query) +
            compareTwoStrings(b.description, query) -
            compareTwoStrings(a.description, query)
        )
        .map((ev) => (
          <GroupCard
            key={ev.id}
            event={ev}
            onSelect={() => serverData.selectEvent(ev.id)}
            onDelete={() => {
              setCurrentId(ev.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              setCurrentId(ev.id);
              setForm(toForm(ev));
              setEditModalOpen(true);
            }}
          />
        ))}
    </>
  );
}
