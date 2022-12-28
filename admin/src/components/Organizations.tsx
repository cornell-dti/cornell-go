import { useContext, useState } from "react";
import { DeleteModal } from "./DeleteModal";
import {
  EntryModal,
  EntryForm,
  NumberEntryForm,
  OptionEntryForm,
  FreeEntryForm,
  DateEntryForm,
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

import { compareTwoStrings } from "string-similarity";
import { OrganizationDto } from "../dto/organization.dto";

function OrganizationCard(props: {
  organization: OrganizationDto;
  onAdd: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onClear: () => void;
  onSetDefault: () => void;
  onSelect: () => void;
}) {
  const affirmOfBool = (val: boolean) => (val ? "Yes" : "No");
  const serverData = useContext(ServerDataContext);

  return (
    <>
      <ListCardBox>
        <ListCardTitle>
          {props.organization.name}
          <ButtonSizer>
            <HButton onClick={() => props.onSelect()} float="right">
              SELECT
            </HButton>
          </ButtonSizer>
        </ListCardTitle>
        <ListCardBody>
          Id: <b>{props.organization.id}</b>
          <br />
          Default Event: <b>{props.organization.defaultEventId}</b> <br />
          Events: <b>{props.organization.events.join(", ")}</b> <br />
          User Count: <b>{props.organization.members.length}</b> <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onAdd}>ADD EVENT</HButton>
          <HButton onClick={props.onClear}>CLEAR</HButton>
          <HButton onClick={props.onAdd}>SET DEFAULT</HButton>
          <HButton onClick={props.onDelete} float="right">
            DELETE
          </HButton>
          <HButton onClick={props.onEdit} float="right">
            EDIT
          </HButton>
        </ListCardButtons>
      </ListCardBox>
    </>
  );
}

function makeForm() {
  return [{ name: "Name", characterLimit: 256, value: "" }] as EntryForm[];
}

function fromForm(
  form: EntryForm[],
  id: string,
  oldDto: OrganizationDto
): OrganizationDto {
  return {
    ...oldDto,
    id,
    name: (form[0] as FreeEntryForm).value,
  };
}

function toForm(group: OrganizationDto) {
  return [
    { name: "Name", characterLimit: 256, value: group.name },
  ] as EntryForm[];
}

const emptyDto: OrganizationDto = {
  id: "",
  members: [],
  name: "",
  accessCode: "",
  events: [],
  defaultEventId: "",
};

export function Organizations() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState("");
  const [query, setQuery] = useState("");
  const [oldDto, setOldDto] = useState(emptyDto);

  return (
    <>
      <EntryModal
        title="Create Organization"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateOrganization(fromForm(form, "", emptyDto));
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit Organization"
        isOpen={isEditModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          serverData.updateOrganization(fromForm(form, currentId, oldDto));
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.organizations.get(currentId)?.name ?? ""}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteOrganization(currentId);
          setDeleteModalOpen(false);
        }}
      />
      <SearchBar
        onCreate={() => {
          setForm(makeForm());
          setCreateModalOpen(true);
        }}
        onSearch={(query) => setQuery(query)}
      />
      {serverData.organizations.size === 0 && (
        <CenterText>No organizations available</CenterText>
      )}
      {Array.from(serverData.organizations.values())
        .sort(
          (a, b) =>
            compareTwoStrings(b.name, query) - compareTwoStrings(a.name, query)
        )
        .map((r) => (
          <OrganizationCard
            key={r.id}
            organization={r}
            onAdd={() => {
              setCurrentId(r.id);
              r.events.push(serverData.selectedEvent);
              serverData.updateOrganization(r);
            }}
            onDelete={() => {
              setCurrentId(r.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              setCurrentId(r.id);
              setForm(toForm(r));
              setOldDto(r);
              setEditModalOpen(true);
            }}
            onClear={() => {
              setCurrentId(r.id);
              r.events = [];
              serverData.updateOrganization(r);
            }}
            onSetDefault={() => {
              setCurrentId(r.id);
              if (serverData.selectedEvent !== "") {
                r.defaultEventId = serverData.selectedEvent;
                serverData.updateOrganization(r);
              }
            }}
            onSelect={() => {
              serverData.selectOrg(r.id);
            }}
          />
        ))}
    </>
  );
}
