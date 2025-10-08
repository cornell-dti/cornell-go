import { useContext, useState } from 'react';
import { DeleteModal } from './DeleteModal';
import {
  EntryModal,
  EntryForm,
  NumberEntryForm,
  OptionEntryForm,
  FreeEntryForm,
  DateEntryForm,
} from './EntryModal';
import { HButton } from './HButton';
import {
  ButtonSizer,
  CenterText,
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from './ListCard';
import { SearchBar } from './SearchBar';
import { ServerDataContext } from './ServerData';

import { compareTwoStrings } from 'string-similarity';
import { OrganizationDto } from '../all.dto';

function OrganizationCard(props: {
  organization: OrganizationDto;
  onAdd: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onClear: () => void;
  onSelect: () => void;
  onAddManager: () => void;
}) {
  const affirmOfBool = (val: boolean) => (val ? 'Yes' : 'No');
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
          Access Code: <b>{props.organization.accessCode?.toUpperCase()}</b>
          <br />
          User Count: <b>{props.organization.members?.length}</b>
          <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onAddManager}>ADD MANAGER</HButton>
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
  return [{ name: 'Name', characterLimit: 256, value: '' }] as EntryForm[];
}

function fromForm(
  form: EntryForm[],
  id: string,
  oldDto: OrganizationDto,
): OrganizationDto {
  return {
    ...oldDto,
    id,
    name: (form[0] as FreeEntryForm).value,
  };
}

function toForm(group: OrganizationDto) {
  return [
    { name: 'Name', characterLimit: 256, value: group.name },
  ] as EntryForm[];
}

const emptyDto: OrganizationDto = {
  id: '',
  members: [],
  name: '',
  accessCode: '',
  events: [],
  managers: [],
};

export function Organizations() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isAddManagerModalOpen, setAddManagerModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState('');
  const [query, setQuery] = useState('');
  const [oldDto, setOldDto] = useState(emptyDto);

  return (
    <>
      <EntryModal
        title="Create Organization"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateOrganization(fromForm(form, '', emptyDto));
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
      <EntryModal
        title="Add Manager"
        isOpen={isAddManagerModalOpen}
        entryButtonText="ADD MANAGER"
        onEntry={() => {
          serverData.addManager((form[0] as FreeEntryForm).value, currentId);
          setAddManagerModalOpen(false);
        }}
        onCancel={() => {
          setAddManagerModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.organizations.get(currentId)?.name ?? ''}
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
        onSearch={query => setQuery(query)}
      />
      {serverData.organizations.size === 0 && (
        <CenterText>No organizations available</CenterText>
      )}
      {Array.from(serverData.organizations.values())
        .sort(
          (a, b) =>
            compareTwoStrings(b.name ?? '', query) -
            compareTwoStrings(a.name ?? '', query),
        )
        .map(org => (
          <OrganizationCard
            key={org.id}
            organization={org}
            onAdd={() => {
              setCurrentId(org.id);
              org.events?.push(serverData.selectedEvent);
              serverData.updateOrganization(org);
            }}
            onDelete={() => {
              setCurrentId(org.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              setCurrentId(org.id);
              setForm(toForm(org));
              setOldDto(org);
              setEditModalOpen(true);
            }}
            onAddManager={() => {
              setCurrentId(org.id);
              setForm(
                () =>
                  [
                    {
                      name: "New Manager's Email",
                      characterLimit: 256,
                      value: '',
                    },
                  ] as EntryForm[],
              );
              setOldDto(org);
              setAddManagerModalOpen(true);
            }}
            onClear={() => {
              setCurrentId(org.id);
              org.events = [];
              serverData.updateOrganization(org);
            }}
            onSelect={() => {
              serverData.selectOrg(org.id);
            }}
          />
        ))}
    </>
  );
}
