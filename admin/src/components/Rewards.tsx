import { useState } from "react";
import styled from "styled-components";
import { RewardDto } from "../dto/update-rewards.dto";
import { EntryForm, EntryModal } from "./EntryModal";
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

  const [createModalOpen, setCreateModalOpen] = useState(false);

  return (
    <>
      <EntryModal
        title="Create Reward"
        isOpen={createModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {}}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={
          [
            { name: "Description", characterLimit: 2048, value: "" },
            { name: "Redeem Info", characterLimit: 2048, value: "" },
          ] as EntryForm[]
        }
      />
      <SearchBar onCreate={() => setCreateModalOpen(true)} />
      <RewardCard reward={reward} />
    </>
  );
}
