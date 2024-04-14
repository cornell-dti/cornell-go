import { useContext, useMemo, useState } from "react";
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
  ButtonSizer,
  CenterText,
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";
import { ServerDataContext } from "./ServerData";

import { compareTwoStrings } from "string-similarity";
import { EventDto } from "../all.dto";
import { AlertModal } from "./AlertModal";

function EventCard(props: {
  event: EventDto;
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const requiredText =
    props.event.requiredMembers && props.event.requiredMembers < 0
      ? "Any Amount"
      : props.event.requiredMembers;

  const timeLimitation =
    props.event.timeLimitation === "LIMITED_TIME" ? "Limited" : "Unlimited";

  const difficultyMode =
    props.event.difficulty === "Easy"
      ? "Easy"
      : props.event.difficulty === "Normal"
      ? "Normal"
      : "Hard";

  const affirmOfBool = (val: boolean) => (val ? "Yes" : "No");

  return (
    <>
      <ListCardBox>
        <ListCardTitle>
          {props.event.name}
          <ButtonSizer>
            <HButton onClick={props.onSelect} float="right">
              SELECT
            </HButton>
          </ButtonSizer>
        </ListCardTitle>
        <ListCardDescription>{props.event.description}</ListCardDescription>
        <ListCardBody>
          Id: <b>{props.event.id}</b>
          <br />
          Available Until:{" "}
          <b>
            {props.event.endTime && new Date(props.event.endTime).toString()}
          </b>{" "}
          <br />
          Required Players: <b>{requiredText}</b> <br />
          Time Limitation: <b>{timeLimitation}</b> <br />
          Challenge Count: <b>{props.event.challenges?.length}</b> <br />
          Difficulty: <b>{difficultyMode}</b> <br />
          Publicly Visible: <b>{affirmOfBool(!!props.event.indexable)}</b>{" "}
          <br />
          Latitude: <b>{props.event.latitudeF}</b>, Longitude:{" "}
          <b>{props.event.longitudeF}</b> <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onDelete}>DELETE</HButton>
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
    {
      name: "Time Limitation",
      options: ["Unlimited", "Limited"],
      value: 0,
    },
    {
      name: "Difficulty",
      options: ["Easy", "Normal", "Hard"],
      value: 1,
    },
    { name: "Publicly Visible", options: ["No", "Yes"], value: 0 },
    { name: "Available Until", date: new Date("2050") },
    // {name: "Category",
    // options: ["FOOD", "NATURE", "HISTORICAL", "CAFE", "DININGHALL", "DORM"],

    // }
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], id: string): EventDto {
  return {
    id,
    requiredMembers: (form[2] as NumberEntryForm).value,
    timeLimitation:
      (form[3] as OptionEntryForm).value === 0 ? "PERPETUAL" : "LIMITED_TIME",
    name: (form[0] as FreeEntryForm).value,
    description: (form[1] as FreeEntryForm).value,
    indexable: (form[5] as OptionEntryForm).value === 1,
    endTime: (form[6] as DateEntryForm).date.toUTCString(),
    challenges: [],
    difficulty:
      (form[4] as OptionEntryForm).value === 0
        ? "Easy"
        : (form[4] as OptionEntryForm).value === 1
        ? "Normal"
        : "Hard",
    latitudeF: 0,
    longitudeF: 0,
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
      name: "Time Limitation",
      options: ["Unlimited", "Limited"],
      value: event.timeLimitation === "PERPETUAL" ? 0 : 1,
    },
    {
      name: "Difficulty",
      options: ["Easy", "Normal", "Hard"],
      value:
        event.difficulty === "Easy"
          ? 0
          : event.difficulty === "Normal"
          ? "Normal"
          : "Hard",
    },
    {
      name: "Publicly Visible",
      options: ["No", "Yes"],
      value: event.indexable ? 1 : 0,
    },
    { name: "Available Until", date: event.endTime && new Date(event.endTime) },
  ] as EntryForm[];
}

export function Events() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);
  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState("");
  const [query, setQuery] = useState("");
  const selectedOrg = serverData.organizations.get(serverData.selectedOrg);

  return (
    <>
      <AlertModal
        description="To create an event, select an organization."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <EntryModal
        title="Create Event"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateEvent({
            ...fromForm(form, ""),
            initialOrganizationId: serverData.selectedOrg,
          });
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
          const { challenges } = serverData.events.get(currentId)!;
          serverData.updateEvent({
            ...fromForm(form, currentId),
            challenges,
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
          if (!selectedOrg) {
            setSelectModalOpen(true);
            return;
          }
          setForm(makeForm());
          setCreateModalOpen(true);
        }}
        onSearch={(query) => setQuery(query)}
      />
      {serverData.selectedOrg === "" ? (
        <CenterText>Select an organization to view events</CenterText>
      ) : serverData.organizations.get(serverData.selectedOrg) ? (
        serverData.organizations?.get(serverData.selectedOrg)?.events
          ?.length === 0 && <CenterText>No events in organization</CenterText>
      ) : (
        <CenterText>Error getting events</CenterText>
      )}
      {Array.from<EventDto>(
        serverData.organizations
          .get(serverData.selectedOrg)
          ?.events?.map((evId: string) => serverData.events.get(evId)!)
          .filter((ev?: EventDto) => !!ev) ?? []
      )
        .sort(
          (a: EventDto, b: EventDto) =>
            compareTwoStrings(b.name ?? "", query) -
            compareTwoStrings(a.name ?? "", query) +
            compareTwoStrings(b.description ?? "", query) -
            compareTwoStrings(a.description ?? "", query)
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
