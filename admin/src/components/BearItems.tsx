import { useContext, useState } from 'react';
import { DeleteModal } from './DeleteModal';
import {
  EntryModal,
  EntryForm,
  NumberEntryForm,
  OptionEntryForm,
  FreeEntryForm,
} from './EntryModal';
import { HButton } from './HButton';
import {
  CenterText,
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardTitle,
} from './ListCard';
import { SearchBar } from './SearchBar';
import { ServerDataContext } from './ServerData';

import { compareTwoStrings } from 'string-similarity';
import { AdminBearItemDto, BearSlotDto } from '../all.dto';

const slotOptions = [
  BearSlotDto.EYES,
  BearSlotDto.MOUTH,
  BearSlotDto.COLOR,
  BearSlotDto.ACCESSORY,
];

const defaultOptions = ['No', 'Yes'];

function BearItemCard(props: {
  item: AdminBearItemDto;
  onEdit: () => void;
  onDelete: () => void;
}) {
  return (
    <ListCardBox>
      <ListCardTitle>{props.item.name}</ListCardTitle>
      <ListCardBody>
        Id: <b>{props.item.id}</b> <br />
        Slot: <b>{props.item.slot}</b> <br />
        Cost: <b>{props.item.cost}</b> <br />
        Asset Key: <b>{props.item.assetKey}</b> <br />
        MIME Type: <b>{props.item.mimeType || 'N/A'}</b> <br />
        Z-Index: <b>{props.item.zIndex ?? 'N/A'}</b> <br />
        Default: <b>{props.item.isDefault ? 'Yes' : 'No'}</b> <br />
      </ListCardBody>
      <ListCardButtons>
        <HButton onClick={props.onDelete}>DELETE</HButton>
        <HButton onClick={props.onEdit} float="right">
          EDIT
        </HButton>
      </ListCardButtons>
    </ListCardBox>
  );
}

function makeForm(): EntryForm[] {
  return [
    { name: 'Name', characterLimit: 256, value: '' },
    {
      name: 'Slot',
      options: slotOptions as string[],
      value: 0,
    },
    { name: 'Cost', value: 0, min: 0, max: 99999 },
    { name: 'Asset Key', characterLimit: 512, value: '' },
    { name: 'MIME Type', characterLimit: 128, value: '' },
    { name: 'Z-Index', value: 0, min: -100, max: 100 },
    {
      name: 'Is Default',
      options: defaultOptions,
      value: 0,
    },
  ];
}

function fromForm(form: EntryForm[], id: string): AdminBearItemDto {
  return {
    id,
    name: (form[0] as FreeEntryForm).value,
    slot: slotOptions[(form[1] as OptionEntryForm).value],
    cost: (form[2] as NumberEntryForm).value,
    assetKey: (form[3] as FreeEntryForm).value,
    mimeType: (form[4] as FreeEntryForm).value,
    zIndex: (form[5] as NumberEntryForm).value,
    isDefault: (form[6] as OptionEntryForm).value === 1,
  };
}

function toForm(item: AdminBearItemDto): EntryForm[] {
  return [
    { name: 'Name', characterLimit: 256, value: item.name ?? '' },
    {
      name: 'Slot',
      options: slotOptions as string[],
      value: slotOptions.indexOf(item.slot ?? BearSlotDto.ACCESSORY),
    },
    { name: 'Cost', value: item.cost ?? 0, min: 0, max: 99999 },
    { name: 'Asset Key', characterLimit: 512, value: item.assetKey ?? '' },
    { name: 'MIME Type', characterLimit: 128, value: item.mimeType ?? '' },
    { name: 'Z-Index', value: item.zIndex ?? 0, min: -100, max: 100 },
    {
      name: 'Is Default',
      options: defaultOptions,
      value: item.isDefault ? 1 : 0,
    },
  ];
}

export function BearItems() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);

  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState('');
  const [query, setQuery] = useState('');

  const allItems = Array.from(serverData.bearItems.values());

  return (
    <>
      <EntryModal
        title="Create Bear Item"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateBearItem(fromForm(form, ''));
          setCreateModalOpen(false);
        }}
        onCancel={() => setCreateModalOpen(false)}
        form={form}
      />
      <EntryModal
        title="Edit Bear Item"
        isOpen={isEditModalOpen}
        entryButtonText="SAVE"
        onEntry={() => {
          serverData.updateBearItem(fromForm(form, currentId));
          setEditModalOpen(false);
        }}
        onCancel={() => setEditModalOpen(false)}
        form={form}
      />
      <DeleteModal
        objectName={serverData.bearItems.get(currentId)?.name ?? ''}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteBearItem(currentId);
          setDeleteModalOpen(false);
        }}
      />
      <SearchBar
        onCreate={() => {
          setForm(makeForm());
          setCreateModalOpen(true);
        }}
        onSearch={q => setQuery(q)}
      />
      {allItems.length === 0 && (
        <CenterText>No bear items found</CenterText>
      )}
      {allItems
        .filter(item => {
          if (query === '') return true;
          const q = query.toLowerCase();
          return (
            (item.name ?? '').toLowerCase().includes(q) ||
            (item.slot ?? '').toLowerCase().includes(q) ||
            (item.assetKey ?? '').toLowerCase().includes(q)
          );
        })
        .sort((a, b) => {
          if (query === '') {
            const slotCmp =
              (a.slot ?? '').localeCompare(b.slot ?? '');
            if (slotCmp !== 0) return slotCmp;
            return (a.name ?? '').localeCompare(b.name ?? '');
          }
          return (
            compareTwoStrings(b.name ?? '', query) -
            compareTwoStrings(a.name ?? '', query)
          );
        })
        .map(item => (
          <BearItemCard
            key={item.id}
            item={item}
            onDelete={() => {
              setCurrentId(item.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              const fresh = serverData.bearItems.get(item.id);
              if (fresh) {
                setCurrentId(item.id);
                setForm(toForm(fresh));
                setEditModalOpen(true);
              }
            }}
          />
        ))}
    </>
  );
}
