import { useContext, useState } from "react";
import { RewardDto } from "../dto/update-rewards.dto";
import { moveDown, moveUp } from "../ordering";
import { DeleteModal } from "./DeleteModal";
import { EntryForm, EntryModal, FreeEntryForm } from "./EntryModal";
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
        Id: <b>{props.reward.id}</b><br />
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
  ] as EntryForm[];
}

function fromForm(form: EntryForm[], eventId: string, id: string) {
  return {
    id,
    description: (form[0] as FreeEntryForm).value,
    redeemInfo: (form[1] as FreeEntryForm).value,
    containingEventId: eventId,
  };
}

function toForm(reward: RewardDto) {
  return [
    { name: "Description", characterLimit: 2048, value: reward.description },
    { name: "Redeem Info", characterLimit: 2048, value: reward.redeemInfo },
  ] as EntryForm[];
}

export function Rewards() {
  const serverData = useContext(ServerDataContext);

  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [currentId, setCurrentId] = useState("");
  const [form, setForm] = useState(() => makeForm());
  const selectedEvent = serverData.events.get(serverData.selectedEvent);

  return (
    <>
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
        }}
      />
      {selectedEvent?.rewardIds.map(
        (rwId) =>
          serverData.rewards.get(rwId) && (
            <RewardCard
              key={rwId}
              reward={serverData.rewards.get(rwId)!}
              onUp={() => {
                selectedEvent.rewardIds = moveUp(
                  selectedEvent.rewardIds,
                  selectedEvent.rewardIds.findIndex((id) => id === rwId)
                );
                serverData.updateEvent(selectedEvent);
              }}
              onDown={() => {
                selectedEvent.rewardIds = moveDown(
                  selectedEvent.rewardIds,
                  selectedEvent.rewardIds.findIndex((id) => id === rwId)
                );
                serverData.updateEvent(selectedEvent);
              }}
              onEdit={() => {
                setCurrentId(rwId);
                setForm(toForm(serverData.rewards.get(rwId)!));
                setEditModalOpen(true);
              }}
              onDelete={() => {
                setCurrentId(rwId);
                setDeleteModalOpen(true);
              }}
              onCopy={() => {
                setForm(toForm(serverData.rewards.get(rwId)!));
                setCreateModalOpen(true);
              }}
            />
          )
      )}
    </>
  );
}
