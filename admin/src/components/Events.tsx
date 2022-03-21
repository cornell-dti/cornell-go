import styled from "styled-components";
import { EventDto } from "../dto/update-events.dto";
import { HButton } from "./HButton";
import { SearchBar } from "./SearchBar";

const EventCardBox = styled.div`
  position: relative;
  left: 50%;
  transform: translateX(-50%);
  border-radius: 4px;
  width: min(calc(100% - 40px), 600px);
  box-shadow: 0 0 2px black;
  padding: 10px 10px 10px 12px;
  margin-bottom: 16px;
`;

const EventCardTitle = styled.div`
  font-weight: 500;
  font-size: 22px;
  margin-bottom: 12px;
`;

const EventCardBody = styled.div`
  width: 100%;
  color: black;
  font-size: 16px;
`;

const EventCardDescription = styled.div`
  height: 128px;
  width: 100%;
  color: gray;
  font-size: 18px;
`;

const EventCardButtons = styled.div`
  padding-top: 32px;
`;

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
      <EventCardBox>
        <EventCardTitle>{props.event.name}</EventCardTitle>
        <EventCardDescription>{props.event.description}</EventCardDescription>
        <EventCardBody>
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
        </EventCardBody>
        <EventCardButtons>
          <HButton>SELECT</HButton>
          <HButton float="right">DELETE</HButton>
          <HButton float="right">EDIT</HButton>
        </EventCardButtons>
      </EventCardBox>
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
