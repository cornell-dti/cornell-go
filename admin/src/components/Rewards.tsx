import { useContext, useState } from "react";
import { compareTwoStrings } from "string-similarity";
import { RewardDto } from "../dto/reward.dto";
import { moveDown, moveUp } from "../ordering";
import { AlertModal } from "./AlertModal";
import { DeleteModal } from "./DeleteModal";
import {
  EntryForm,
  EntryModal,
  FreeEntryForm,
  NumberEntryForm,
  OptionEntryForm,
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

function RewardCard(props: {
  reward: RewardDto;
  onEdit: () => void;
  onDelete: () => void;
  onUp: () => void;
  onDown: () => void;
  onCopy: () => void;
}) {
  return (
    <ListCardBox>
      <ListCardTitle>
        {props.reward.description}
        <ButtonSizer>
          <HButton onClick={props.onCopy} float="right">
            COPY
          </HButton>
        </ButtonSizer>
      </ListCardTitle>
      <ListCardDescription>{props.reward.redeemInfo}</ListCardDescription>
      <ListCardBody>
        Id: <b>{props.reward.id}</b>
        <br />
        Claiming User Id: <b>{props.reward.userId}</b>
        <br />
        Is Achievement: <b>{props.reward.isAchievement ? "Yes" : "No"}</b>
        <br />
        Points: <b>{props.reward.points}</b>
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

function makeForm() {
  return [
    { name: "Description", characterLimit: 2048, value: "" },
    { name: "Redeem Info", characterLimit: 2048, value: "" },
    { name: "Is Achievment?", options: ["No", "Yes"], value: 0 },
    { name: "Points", min: -1, max: 999999, value: 0 },
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], eventId: string, id: string): RewardDto {
  return {
    id,
    description: (form[0] as FreeEntryForm).value,
    redeemInfo: (form[1] as FreeEntryForm).value,
    eventId,
    userId: "",
    isAchievement: (form[2] as OptionEntryForm).value === 1,
    points: (form[3] as NumberEntryForm).value,
  };
}

function toForm(reward: RewardDto) {
  return [
    { name: "Description", characterLimit: 2048, value: reward.description },
    { name: "Redeem Info", characterLimit: 2048, value: reward.redeemInfo },
    {
      name: "Is Achievment?",
      options: ["No", "Yes"],
      value: reward.isAchievement ? 1 : 0,
    },
    { name: "Points", min: -1, max: 999999, value: reward.points },
  ] as EntryForm[];
}

export function Rewards() {
  const serverData = useContext(ServerDataContext);

  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);

  const [currentId, setCurrentId] = useState("");
  const [form, setForm] = useState(() => makeForm());
  const [query, setQuery] = useState("");

  const selectedEvent = serverData.events.get(serverData.selectedEvent);

  return (
    <>
      <AlertModal
        description="To create a reward, select an event."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <EntryModal
        title="Create Reward"
        isOpen={createModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateReward(fromForm(form, serverData.selectedEvent, ""));
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit Reward"
        isOpen={editModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          serverData.updateReward(
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
        objectName={serverData.rewards.get(currentId)?.description ?? ""}
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteReward(currentId);
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
        <CenterText>Select an event to view rewards</CenterText>
      ) : serverData.events.get(serverData.selectedEvent) ? (
        serverData.events.get(serverData.selectedEvent)?.rewardIds.length ===
          0 && <CenterText>No rewards in event</CenterText>
      ) : (
        <CenterText>Error getting rewards</CenterText>
      )}
      {selectedEvent?.rewardIds
        .filter((rwId) => serverData.rewards.get(rwId))
        .map((rwId) => serverData.rewards.get(rwId)!)
        .sort((a, b) =>
          query === ""
            ? 0
            : compareTwoStrings(b.description, query) -
              compareTwoStrings(a.description, query) +
              compareTwoStrings(b.redeemInfo!, query) -
              compareTwoStrings(a.redeemInfo!, query)
        )
        .map((rw) => (
          <RewardCard
            key={rw.id}
            reward={rw}
            onUp={() => {
              if (query !== "") return;
              selectedEvent.rewardIds = moveUp(
                selectedEvent.rewardIds,
                selectedEvent.rewardIds.findIndex((id) => id === rw.id)
              );
              serverData.updateEvent(selectedEvent);
            }}
            onDown={() => {
              if (query !== "") return;
              selectedEvent.rewardIds = moveDown(
                selectedEvent.rewardIds,
                selectedEvent.rewardIds.findIndex((id) => id === rw.id)
              );
              serverData.updateEvent(selectedEvent);
            }}
            onEdit={() => {
              setCurrentId(rw.id);
              setForm(toForm(rw));
              setEditModalOpen(true);
            }}
            onDelete={() => {
              setCurrentId(rw.id);
              setDeleteModalOpen(true);
            }}
            onCopy={() => {
              setForm(toForm(rw));
              setCreateModalOpen(true);
            }}
          />
        ))}
    </>
  );
}
