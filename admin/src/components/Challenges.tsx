import { useContext, useState } from "react";
import { compareTwoStrings } from "string-similarity";
import styled, { css } from "styled-components";
import { ChallengeDto } from "../dto/challenge.dto";
import { moveDown, moveUp } from "../ordering";
import { AlertModal } from "./AlertModal";
import { DeleteModal } from "./DeleteModal";
import {
  EntryForm,
  EntryModal,
  FreeEntryForm,
  MapEntryForm,
  NumberEntryForm,
} from "./EntryModal";
import { HButton } from "./HButton";
import {
  CenterText,
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";
import { ServerDataContext } from "./ServerData";

const ChallengeImage = styled.div<{ url: string }>`
  width: calc(100% + 23px);
  height: 250px;
  margin-left: -12px;
  margin-bottom: 8px;
  background-size: cover;
  background-position: center;
  ${(props) => css`
    background-image: url(${'"' + props.url + '"'});
  `}
`;

function ChallengeCard(props: {
  challenge: ChallengeDto;
  onUp: () => void;
  onDown: () => void;
  onDelete: () => void;
  onEdit: () => void;
}) {
  return (
    <ListCardBox>
      <ListCardTitle>{props.challenge.name}</ListCardTitle>
      <ListCardDescription>{props.challenge.description}</ListCardDescription>
      <ChallengeImage url={props.challenge.imageUrl} />
      <ListCardBody>
        Id: <b>{props.challenge.id}</b> <br />
        Latitude: <b>{props.challenge.lat}</b>, Longitude:{" "}
        <b>{props.challenge.long}</b> <br />
        Awarding Distance: <b>{props.challenge.awardingRadius} meters</b> <br />
        Close Distance: <b>{props.challenge.closeRadius} meters</b>
      </ListCardBody>
      <ListCardButtons>
        <HButton onClick={props.onUp}>UP</HButton>
        <HButton onClick={props.onDown}>DOWN</HButton>
        <HButton onClick={props.onDelete} float="right">
          DELETE
        </HButton>
        <HButton onClick={props.onEdit} float="right">
          EDIT
        </HButton>
      </ListCardButtons>
    </ListCardBox>
  );
}

function makeForm(): EntryForm[] {
  return [
    { name: "Location", latitude: 42.447546, longitude: -76.484593 },
    { name: "Name", characterLimit: 256, value: "" },
    { name: "Description", characterLimit: 2048, value: "" },
    { name: "Image URL", characterLimit: 2048, value: "" },
    { name: "Awarding Distance (meters)", min: 1, max: 1000, value: 1 },
    { name: "Close Distance (meters)", min: 1, max: 1000, value: 1 },
  ];
}

function toForm(challenge: ChallengeDto) {
  return [
    {
      name: "Location",
      latitude: challenge.lat,
      longitude: challenge.long,
    },
    { name: "Name", characterLimit: 256, value: challenge.name },
    { name: "Description", characterLimit: 2048, value: challenge.description },
    { name: "Image URL", characterLimit: 2048, value: challenge.imageUrl },
    {
      name: "Awarding Distance (meters)",
      min: 1,
      max: 1000,
      value: challenge.awardingRadius,
    },
    {
      name: "Close Distance (meters)",
      min: 1,
      max: 1000,
      value: challenge.closeRadius,
    },
  ];
}

function fromForm(
  form: EntryForm[],
  eventId: string,
  id: string
): ChallengeDto {
  return {
    id,
    name: (form[1] as FreeEntryForm).value,
    description: (form[2] as FreeEntryForm).value,
    imageUrl: (form[3] as FreeEntryForm).value,
    points: 0, // TODO: update @Temi
    lat: (form[0] as MapEntryForm).latitude,
    long: (form[0] as MapEntryForm).longitude,
    awardingRadius: (form[4] as NumberEntryForm).value,
    closeRadius: (form[5] as NumberEntryForm).value,
    containingEventId: eventId,
  };
}

export function Challenges() {
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);

  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState("");
  const [query, setQuery] = useState("");

  const serverData = useContext(ServerDataContext);
  const selectedEvent = serverData.events.get(serverData.selectedEvent);

  return (
    <>
      <AlertModal
        description="To create a challenge, select an event."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <EntryModal
        title="Create Challenge"
        isOpen={createModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateChallenge(
            fromForm(form, serverData.selectedEvent, "")
          );
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit Challenge"
        isOpen={editModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          serverData.updateChallenge(
            fromForm(form, serverData.selectedEvent, currentId)
          );
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.challenges.get(currentId)?.name ?? ""}
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteChallenge(currentId);
          setDeleteModalOpen(false);
        }}
      />
      <SearchBar
        onCreate={() => {
          setForm(makeForm());
          setCreateModalOpen(!!selectedEvent);
          if (!selectedEvent) {
            setSelectModalOpen(true);
          }
        }}
        onSearch={(query) => setQuery(query)}
      />

      {serverData.selectedEvent === "" ? (
        <CenterText>Select an event to view challenges</CenterText>
      ) : serverData.events.get(serverData.selectedEvent) ? (
        serverData.events.get(serverData.selectedEvent)?.challengeIds.length ===
          0 && <CenterText>No challenges in event</CenterText>
      ) : (
        <CenterText>Error getting challenges</CenterText>
      )}
      {selectedEvent?.challengeIds
        .filter((chalId) => serverData.challenges.get(chalId))
        .map((chalId) => serverData.challenges.get(chalId)!)
        .sort((a, b) =>
          query === ""
            ? 0
            : compareTwoStrings(b.name, query) -
              compareTwoStrings(a.name, query) +
              compareTwoStrings(b.description, query) -
              compareTwoStrings(a.description, query)
        )
        .map((chal) => (
          <ChallengeCard
            key={chal.id}
            challenge={chal}
            onUp={() => {
              if (query !== "") return;
              selectedEvent.challengeIds = moveUp(
                selectedEvent.challengeIds,
                selectedEvent.challengeIds.findIndex((id) => id === chal.id)
              );
              serverData.updateEvent(selectedEvent);
            }}
            onDown={() => {
              if (query !== "") return;
              selectedEvent.challengeIds = moveDown(
                selectedEvent.challengeIds,
                selectedEvent.challengeIds.findIndex((id) => id === chal.id)
              );
              serverData.updateEvent(selectedEvent);
            }}
            onEdit={() => {
              setCurrentId(chal.id);
              setForm(toForm(chal));
              setEditModalOpen(true);
            }}
            onDelete={() => {
              setCurrentId(chal.id);
              setDeleteModalOpen(true);
            }}
          />
        ))}
    </>
  );
}
