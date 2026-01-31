import { useContext, useMemo, useState } from 'react';
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
import {
  AchievementDto,
  AchievementTypeDto,
  ChallengeLocationDto,
} from '../all.dto';
import { AlertModal } from './AlertModal';

const locationOptions = [
  ChallengeLocationDto.ENG_QUAD,
  ChallengeLocationDto.ARTS_QUAD,
  ChallengeLocationDto.AG_QUAD,
  ChallengeLocationDto.NORTH_CAMPUS,
  ChallengeLocationDto.WEST_CAMPUS,
  ChallengeLocationDto.COLLEGETOWN,
  ChallengeLocationDto.ITHACA_COMMONS,
  ChallengeLocationDto.ANY,
];

const achievementOptions = [
  AchievementTypeDto.TOTAL_CHALLENGES,
  AchievementTypeDto.TOTAL_CHALLENGES_OR_JOURNEYS,
  AchievementTypeDto.TOTAL_JOURNEYS,
  AchievementTypeDto.TOTAL_POINTS,
];

function AchiemementCard(props: {
  achievement: AchievementDto;
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onCopy: () => void;
}) {
  return (
    <>
      <ListCardBox>
        <ListCardTitle>
          {props.achievement.name}
          <ButtonSizer>
            <HButton onClick={props.onSelect} float="right">
              {props.achievement.eventId ? 'UNLINK EVENT' : 'LINK EVENT'}
            </HButton>
          </ButtonSizer>
        </ListCardTitle>
        <ListCardDescription>
          {props.achievement.description}
        </ListCardDescription>
        <ListCardBody>
          Id: <b>{props.achievement.id}</b> <br />
          Required Points/Event Completions:{' '}
          <b>{props.achievement.requiredPoints}</b> <br />
          Linked Event ID: <b>{props.achievement.eventId ?? 'NONE'}</b> <br />
          Location Type: <b>{props.achievement.locationType}</b> <br />
          Achievement Type: <b>{props.achievement.achievementType}</b> <br />
        </ListCardBody>
        <ListCardButtons>
          <HButton onClick={props.onDelete}>DELETE</HButton>
          <HButton onClick={props.onEdit} float="right">
            EDIT
          </HButton>
          <HButton onClick={props.onCopy} float="right">
            COPY
          </HButton>
        </ListCardButtons>
      </ListCardBox>
    </>
  );
}

// Default Form Creation
function makeForm() {
  return [
    { name: 'Name', characterLimit: 256, value: '' },
    { name: 'Description', characterLimit: 2048, value: '' },
    {
      name: 'Location Type',
      options: locationOptions as string[],
      value: 0,
    },
    {
      name: 'Achievement Type',
      options: achievementOptions as string[],
      value: 0,
    },
    { name: 'Required Points', value: 1, min: 1, max: 999 },
  ] as EntryForm[];
}

// Form to DTO Conversion
function fromForm(form: EntryForm[], id: string): AchievementDto {
  return {
    id,
    imageUrl: '',
    name: (form[0] as FreeEntryForm).value,
    description: (form[1] as FreeEntryForm).value,
    locationType: locationOptions[(form[2] as OptionEntryForm).value],
    achievementType: achievementOptions[(form[3] as OptionEntryForm).value],
    requiredPoints: (form[4] as NumberEntryForm).value,
  };
}

// DTO to Form Conversion
function toForm(achievement: AchievementDto) {
  return [
    { name: 'Name', characterLimit: 256, value: achievement.name! },
    {
      name: 'Description',
      characterLimit: 2048,
      value: achievement.description!,
    },
    {
      name: 'Location Type',
      options: locationOptions as string[],
      value: locationOptions.indexOf(achievement.locationType!),
    },
    {
      name: 'Achievement Type',
      options: achievementOptions as string[],
      value: achievementOptions.indexOf(achievement.achievementType!),
    },
    {
      name: 'Required Points',
      value: achievement.requiredPoints!,
      min: 1,
      max: 999,
    },
  ] as EntryForm[];
}

function makeCopyForm(orgOptions: string[], initialIndex: number) {
  return [
    {
      name: 'Target Organization',
      options: orgOptions,
      value: initialIndex,
    },
  ] as EntryForm[];
}

export function Achievements() {
  const serverData = useContext(ServerDataContext);
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);
  const [isLinkedModalOpen, setLinkedModalOpen] = useState(false);

  const [isCopyModalOpen, setCopyModalOpen] = useState(false);
  const [copyForm, setCopyForm] = useState(() => ({
    form: makeCopyForm([], 0),
    orgIds: [] as string[],
  }));

  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState('');
  const [query, setQuery] = useState('');
  const selectedOrg = serverData.organizations.get(serverData.selectedOrg);

  return (
    <>
      <AlertModal
        description="To create an achievement, select an organization."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <AlertModal
        description="To link an achievement to an event, select an event."
        isOpen={isLinkedModalOpen}
        onClose={() => setLinkedModalOpen(false)}
      />
      <EntryModal
        title="Create Achievement"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateAchievement({
            ...fromForm(form, ''),
            initialOrganizationId: serverData.selectedOrg,
          });
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit Event"
        isOpen={isEditModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          const oldAchievement = serverData.achievements.get(currentId)!;
          serverData.updateAchievement({
            ...oldAchievement,
            ...fromForm(form, currentId),
          });
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Copy Achievement"
        isOpen={isCopyModalOpen}
        entryButtonText="COPY"
        onEntry={async () => {
          const ach = serverData.achievements.get(currentId)!;
          serverData.updateAchievement({
            ...ach,
            eventId: '',
            initialOrganizationId:
              copyForm.orgIds[(copyForm.form[0] as OptionEntryForm).value],
            id: '',
          });
          setCopyModalOpen(false);
        }}
        onCancel={() => {
          setCopyModalOpen(false);
        }}
        form={copyForm.form}
      />
      <DeleteModal
        objectName={serverData.achievements.get(currentId)?.name ?? ''}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteAchievement(currentId);
          setDeleteModalOpen(false);
        }}
      />
      <SearchBar
        onCreate={() => {
          if (!selectedOrg) {
            setSelectModalOpen(true);
            return;
          }
          setForm(makeForm());
          setCreateModalOpen(true);
        }}
        onSearch={query => setQuery(query)}
      />
      {serverData.selectedOrg === '' ? (
        <CenterText>Select an organization to view achievements</CenterText>
      ) : serverData.organizations.get(serverData.selectedOrg) ? (
        serverData.organizations?.get(serverData.selectedOrg)?.achivements
          ?.length === 0 && (
          <CenterText>No achievements in organization</CenterText>
        )
      ) : (
        <CenterText>Error getting achievements</CenterText>
      )}
      {Array.from<AchievementDto>(
        serverData.organizations
          .get(serverData.selectedOrg)
          ?.achivements?.map(
            (achId: string) => serverData.achievements.get(achId)!,
          )
          .filter((ach?: AchievementDto) => !!ach) ?? [],
      )
        .sort(
          (a: AchievementDto, b: AchievementDto) =>
            compareTwoStrings(b.name ?? '', query) -
            compareTwoStrings(a.name ?? '', query) +
            compareTwoStrings(b.description ?? '', query) -
            compareTwoStrings(a.description ?? '', query),
        )
        .map(ach => (
          <AchiemementCard
            key={ach.id}
            achievement={ach}
            onSelect={() => {
              if (ach.eventId) {
                serverData.updateAchievement({
                  ...ach,
                  eventId: '',
                });

                return;
              }

              if (serverData.selectedEvent === '') {
                setLinkedModalOpen(true);
              } else {
                serverData.updateAchievement({
                  ...ach,
                  eventId: serverData.selectedEvent,
                });
              }
            }}
            onDelete={() => {
              setCurrentId(ach.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              const freshAchievement = serverData.achievements.get(ach.id);
              if (freshAchievement) {
                setCurrentId(ach.id);
                setForm(toForm(freshAchievement));
                setEditModalOpen(true);
              }
            }}
            onCopy={() => {
              const orgs = Array.from(serverData.organizations.values());
              const myOrgIndex = orgs.findIndex(v => v.id === selectedOrg?.id);
              setCurrentId(ach.id);
              setCopyForm({
                form: makeCopyForm(
                  orgs.map(org => org.name ?? ''),
                  myOrgIndex,
                ),
                orgIds: orgs.map(org => org.id),
              });
              setCopyModalOpen(true);
            }}
          />
        ))}
    </>
  );
}
