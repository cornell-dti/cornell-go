import styled, { css } from "styled-components";
import { ChallengeDto } from "../dto/update-challenges.dto";
import { HButton } from "./HButton";
import {
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";

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

function ChallengeCard(props: { challenge: ChallengeDto }) {
  return (
    <ListCardBox>
      <ListCardTitle>{props.challenge.name}</ListCardTitle>
      <ListCardDescription>{props.challenge.description}</ListCardDescription>
      <ChallengeImage url={props.challenge.imageUrl} />
      <ListCardBody>
        Latitude: <b>{props.challenge.latitude}</b>, Longitude:{" "}
        <b>{props.challenge.longitude}</b> <br />
        Awarding Distance: <b>{props.challenge.awardingRadius} meters</b> <br />
        Close Distance: <b>{props.challenge.closeRadius} meters</b>
      </ListCardBody>
      <ListCardButtons>
        <HButton>UP</HButton>
        <HButton>DOWN</HButton>
        <HButton float="right">DELETE</HButton>
        <HButton float="right">EDIT</HButton>
      </ListCardButtons>
    </ListCardBox>
  );
}

export function Challenges() {
  const chal: ChallengeDto = {
    id: "a",
    name: "My challenge",
    description: "My description",
    imageUrl:
      "https://localist-images.azureedge.net/photos/16629/original/15dbe59a29aac251b8b04bcb8b4915c7c89dd65d.jpg",
    latitude: 66.666,
    longitude: 99.999,
    awardingRadius: 6,
    closeRadius: 12,
  };
  return (
    <>
      <SearchBar />
      <ChallengeCard challenge={chal} />
    </>
  );
}
