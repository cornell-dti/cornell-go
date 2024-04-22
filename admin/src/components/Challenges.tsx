import { useContext, useState } from "react";
import { compareTwoStrings } from "string-similarity";
import styled, { css } from "styled-components";
import { ChallengeDto, ChallengeLocationDto } from "../all.dto";
import { moveDown, moveUp } from "../ordering";
import { AlertModal } from "./AlertModal";
import { DeleteModal } from "./DeleteModal";
import {
  EntryForm,
  EntryModal,
  FreeEntryForm,
  OptionEntryForm,
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

const locationOptions: ChallengeLocationDto[] = [
  ChallengeLocationDto.ENG_QUAD,
  ChallengeLocationDto.ARTS_QUAD,
  ChallengeLocationDto.AG_QUAD,
  ChallengeLocationDto.NORTH_CAMPUS,
  ChallengeLocationDto.WEST_CAMPUS,
  ChallengeLocationDto.COLLEGETOWN,
  ChallengeLocationDto.ITHACA_COMMONS,
  ChallengeLocationDto.ANY,
];

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
      <ChallengeImage url={props.challenge.imageUrl ?? ""} />
      <ListCardBody>
        Id: <b>{props.challenge.id}</b> <br />
        Location: <b>{props.challenge.location}</b> <br />
        Score: <b>{props.challenge.points}</b> <br />
        Latitude: <b>{props.challenge.latF}</b>, Longitude:{" "}
        <b>{props.challenge.longF}</b> <br />
        Awarding Distance: <b>{props.challenge.awardingRadiusF} meters</b>{" "}
        <br />
        Close Distance: <b>{props.challenge.closeRadiusF} meters</b>
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
    {
      name: "Location Description",
      options: locationOptions as string[],
      value: 0,
    },
    { name: "Name", characterLimit: 256, value: "" },
    { name: "Description", characterLimit: 2048, value: "" },
    { name: "Points", min: 1, max: 1000, value: 50 },
    { name: "Image URL", characterLimit: 2048, value: "" },
    { name: "Awarding Distance (meters)", min: 1, max: 1000, value: 1 },
    { name: "Close Distance (meters)", min: 1, max: 1000, value: 1 },
  ];
}

function toForm(challenge: ChallengeDto) {
  return [
    {
      name: "Location",
      latitude: challenge.latF ?? 0,
      longitude: challenge.longF ?? 0,
    },
    {
      name: "Location Description",
      options: locationOptions,
      value:
        challenge.location !== undefined
          ? locationOptions.indexOf(challenge.location)
          : 0,
    },
    { name: "Name", characterLimit: 256, value: challenge.name ?? "" },
    {
      name: "Description",
      characterLimit: 2048,
      value: challenge.description ?? "",
    },
    {
      name: "Points",
      min: 1,
      max: 1000,
      value: challenge.points ?? 0,
    },
    {
      name: "Image URL",
      characterLimit: 2048,
      value: challenge.imageUrl ?? "",
    },
    {
      name: "Awarding Distance (meters)",
      min: 1,
      max: 1000,
      value: challenge.awardingRadiusF ?? 0,
    },
    {
      name: "Close Distance (meters)",
      min: 1,
      max: 1000,
      value: challenge.closeRadiusF ?? 0,
    },
  ];
}

function fromForm(
  form: EntryForm[],
  eventId: string,
  id: string,
): ChallengeDto {
  return {
    id,
    name: (form[2] as FreeEntryForm).value,
    location: locationOptions[(form[1] as OptionEntryForm).value],
    description: (form[3] as FreeEntryForm).value,
    points: (form[4] as NumberEntryForm).value,
    imageUrl: (form[5] as FreeEntryForm).value,
    latF: (form[0] as MapEntryForm).latitude,
    longF: (form[0] as MapEntryForm).longitude,
    awardingRadiusF: (form[6] as NumberEntryForm).value,
    closeRadiusF: (form[7] as NumberEntryForm).value,
    linkedEventId: eventId,
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
            fromForm(form, serverData.selectedEvent, ""),
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
            fromForm(form, serverData.selectedEvent, currentId),
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
        serverData.events.get(serverData.selectedEvent)?.challenges?.length ===
          0 && <CenterText>No challenges in event</CenterText>
      ) : (
        <CenterText>Error getting challenges</CenterText>
      )}
      {selectedEvent?.challenges
        ?.filter((chalId: string) => serverData.challenges.get(chalId))
        .map((chalId: string) => serverData.challenges.get(chalId)!)
        .sort((a: ChallengeDto, b: ChallengeDto) =>
          query === ""
            ? 0
            : compareTwoStrings(b.name ?? "", query) -
              compareTwoStrings(a.name ?? "", query) +
              compareTwoStrings(b.description ?? "", query) -
              compareTwoStrings(a.description ?? "", query),
        )
        .map((chal: ChallengeDto) => (
          <ChallengeCard
            key={chal.id}
            challenge={chal}
            onUp={() => {
              if (query !== "" || !selectedEvent.challenges) return;
              selectedEvent.challenges = moveUp(
                selectedEvent.challenges,
                selectedEvent.challenges.findIndex(
                  (id: string) => id === chal.id,
                ) ?? 0,
              );
              serverData.updateEvent(selectedEvent);
            }}
            onDown={() => {
              if (query !== "" || !selectedEvent.challenges) return;
              selectedEvent.challenges = moveDown(
                selectedEvent.challenges,
                selectedEvent.challenges.findIndex(
                  (id: string) => id === chal.id,
                ),
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
