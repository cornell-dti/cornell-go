import styled from "styled-components";
import { RewardDto } from "../dto/update-rewards.dto";
import { HButton } from "./HButton";
import {
  ButtonSizer,
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from "./ListCard";
import { SearchBar } from "./SearchBar";

function RewardCard(props: { reward: RewardDto }) {
  return (
    <ListCardBox>
      <ListCardTitle>
        {props.reward.description}
        <ButtonSizer>
          <HButton float="right">COPY</HButton>
        </ButtonSizer>
      </ListCardTitle>
      <ListCardDescription>{props.reward.redeemInfo}</ListCardDescription>
      <ListCardButtons>
        <HButton>UP</HButton>
        <HButton>DOWN</HButton>
        <HButton float="right">DELETE</HButton>
        <HButton float="right">EDIT</HButton>
      </ListCardButtons>
    </ListCardBox>
  );
}

export function Rewards() {
  const reward: RewardDto = {
    id: "a",
    description: "$3 Cornell Store",
    redeemInfo: "Go to this <redeem link https://google.com> to redeem",
  };

  return (
    <>
      <SearchBar />
      <RewardCard reward={reward} />
    </>
  );
}
