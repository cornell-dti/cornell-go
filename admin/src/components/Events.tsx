import { useState } from "react";
import styled from "styled-components";
import { EventDto } from "../dto/update-events.dto";
import { EntryModal, EntryForm } from "./EntryModal";
import { HButton } from "./HButton";
import {
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";

function EventCard(props: { event: EventDto }) {
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
          Available Until: <b>{props.event.time}</b> <br />
          Required Players: <b>{requiredText}</b> <br />
          Rewarding Method: <b>{rewardingMethod}</b> <br />
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
          <HButton>SELECT</HButton>
          <HButton float="right">DELETE</HButton>
          <HButton float="right">EDIT</HButton>
        </ListCardButtons>
      </ListCardBox>
    </>
  );
}

export function Events() {
  const myEvent: EventDto = {
    id: "a",
    requiredMembers: 1,
    skippingEnabled: true,
    isDefault: true,
    rewardType: "perpetual",
    name: "My event",
    description: "My event desc",
    indexable: true,
    time: new Date().toLocaleString(),
    rewardIds: [],
    challengeIds: [],
  };

  const [isCreateModalOpen, setCreateModalOpen] = useState(false);

  return (
    <>
      <EntryModal
        title="Create Event"
        isOpen={isCreateModalOpen}
        onEntry={() => {}}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={
          [
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
            { name: "Visible", options: ["No", "Yes"], value: 0 },
            { name: "Available Until", date: new Date() },
          ] as EntryForm[]
        }
      />
      <SearchBar onCreate={() => setCreateModalOpen(true)} />
      <EventCard event={myEvent} />
    </>
  );
}
