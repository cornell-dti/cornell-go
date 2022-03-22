import styled from "styled-components";
import { EventDto } from "../dto/update-events.dto";
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
          Available Until/Since: <b>{props.event.time}</b> <br />
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

  return (
    <>
      <SearchBar />
      <EventCard event={myEvent} />
    </>
  );
}
