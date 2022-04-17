import { useContext, useState } from "react";
import { EventDto } from "../dto/update-events.dto";
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

function EventCard(props: {
  event: EventDto;
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const requiredText =
    props.event.requiredMembers < 0
      ? "Any Amount"
      : props.event.requiredMembers;

  const rewardingMethod =
    props.event.rewardType === "limited_time_event"
      ? "Limited Time"
      : "Perpetual";

  const affirmOfBool = (val: boolean) => (val ? "Yes" : "No");

  return (
    <>
      <ListCardBox>
        <ListCardTitle>{props.event.name}</ListCardTitle>
        <ListCardDescription>{props.event.description}</ListCardDescription>
        <ListCardBody>
          Id: <b>{props.event.id}</b>
          <br />
          Available Until: <b>{new Date(props.event.time).toString()}</b> <br />
          Required Players: <b>{requiredText}</b> <br />
          Rewarding Method: <b>{rewardingMethod}</b> <br />
          Minimum Rewarding Score: <b>{props.event.minimumScore}</b> <br />
          Challenge Count: <b>{props.event.challengeIds.length}</b> <br />
          Reward Count: <b>{props.event.rewardIds.length}</b> <br />
          Skipping Enabled: <b>
            {affirmOfBool(props.event.skippingEnabled)}
          </b>{" "}
          <br />
          Default: <b>{affirmOfBool(props.event.isDefault)}</b> <br />
          Visible: <b>{affirmOfBool(props.event.indexable)}</b>
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
    { name: "Description", characterLimit: 2048, value: "" },
    { name: "Required Members", value: -1, min: -1, max: 99 },
    { name: "Skipping", options: ["Disabled", "Enabled"], value: 0 },
    { name: "Default", options: ["No", "Yes"], value: 0 },
    {
      name: "Rewarding Method",
      options: ["Perpetual", "Limited Time"],
      value: 0,
    },
    { name: "Minimum Rewarding Score", value: 1, min: 1, max: 999999 },
    { name: "Visible", options: ["No", "Yes"], value: 0 },
    { name: "Available Until", date: new Date() },
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], id: string): EventDto {
  return {
    id,
    requiredMembers: (form[2] as NumberEntryForm).value,
    skippingEnabled: (form[3] as OptionEntryForm).value === 1,
    isDefault: (form[4] as OptionEntryForm).value === 1,
    rewardType:
      (form[5] as OptionEntryForm).value === 0
        ? "perpetual"
        : "limited_time_event",
    name: (form[0] as FreeEntryForm).value,
    description: (form[1] as FreeEntryForm).value,
    indexable: (form[7] as OptionEntryForm).value === 1,
    time: (form[8] as DateEntryForm).date.toUTCString(),
    rewardIds: [],
    challengeIds: [],
    minimumScore: (form[6] as NumberEntryForm).value,
  };
}

function toForm(event: EventDto) {
  return [
    { name: "Name", characterLimit: 256, value: event.name },
    { name: "Description", characterLimit: 2048, value: event.description },
    {
      name: "Required Members",
      value: event.requiredMembers,
      min: -1,
      max: 99,
    },
    {
      name: "Skipping",
      options: ["Disabled", "Enabled"],
      value: event.skippingEnabled ? 1 : 0,
    },
    { name: "Default", options: ["No", "Yes"], value: event.isDefault ? 1 : 0 },
    {
      name: "Rewarding Method",
      options: ["Perpetual", "Limited Time"],
      value: event.rewardType === "perpetual" ? 0 : 1,
    },
    {
      name: "Minimum Rewarding Score",
      value: event.minimumScore,
      min: 1,
      max: 999999,
    },
    { name: "Visible", options: ["No", "Yes"], value: event.indexable ? 1 : 0 },
    { name: "Available Until", date: new Date(event.time) },
  ] as EntryForm[];
}

export function Events() {
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
        title="Create Event"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateEvent(fromForm(form, ""));
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
          const { challengeIds, rewardIds } = serverData.events.get(currentId)!;
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
        objectName={serverData.events.get(currentId)?.name ?? ""}
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
          <EventCard
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
