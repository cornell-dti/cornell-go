import { useContext, useState, useEffect } from 'react';
import { compareTwoStrings } from 'string-similarity';
import styled, { css } from 'styled-components';
import {
  ChallengeDto,
  EventDto,
  EventDifficultyDto,
  EventTimeLimitationDto,
  EventCategoryDto,
  QuizQuestionDto,
} from '../all.dto';
import { AlertModal } from './AlertModal';
import { DeleteModal } from './DeleteModal';
import {
  EntryForm,
  EntryModal,
  FreeEntryForm,
  NumberEntryForm,
  OptionEntryForm,
  MapEntryForm,
  DateEntryForm,
  CheckboxNumberEntryForm,
} from './EntryModal';
import { HButton } from './HButton';
import {
  CenterText,
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from './ListCard';
import { SearchBar } from './SearchBar';
import { ServerDataContext } from './ServerData';
import {
  ChallengeImage,
  locationOptions,
  QuizQuestionSection,
  makeQuizForm,
  fromQuizForm,
  toQuizForm,
} from './ChallengeCardComponents';

const eventCategoryOptions = [
  'FOOD',
  'NATURE',
  'HISTORICAL',
  'CAFE',
  'DININGHALL',
  'DORM',
];

// Combined form indices:
// 0: Location (map), 1: Name, 2: Description, 3: Location Description,
// 4: Category, 5: Difficulty, 6: Points, 7: Image URL,
// 8: Awarding Distance, 9: Close Distance, 10: Enable Timer,
// 11: Time Limitation, 12: Publicly Visible, 13: Featured, 14: Available Until
function makeCombinedForm(): EntryForm[] {
  const awardingRadius = 1;
  const closeRadius = 1;
  return [
    {
      name: 'Location',
      latitude: 42.447546,
      longitude: -76.484593,
      awardingRadiusF: awardingRadius,
      closeRadiusF: closeRadius,
    },
    { name: 'Name', characterLimit: 256, value: '' },
    { name: 'Description', characterLimit: 2048, value: '', multiline: true },
    {
      name: 'Location Description',
      options: locationOptions as string[],
      value: 0,
    },
    {
      name: 'Category',
      options: eventCategoryOptions,
      value: 1,
    },
    {
      name: 'Difficulty',
      options: ['Easy', 'Normal', 'Hard'],
      value: 0,
    },
    { name: 'Points', min: 1, max: 1000, value: 50 },
    { name: 'Image URL', characterLimit: 2048, value: '' },
    {
      name: 'Awarding Distance (meters)',
      min: 1,
      max: 1000,
      value: awardingRadius,
    },
    {
      name: 'Close Distance (meters)',
      min: 1,
      max: 1000,
      value: closeRadius,
    },
    {
      name: 'Enable Timer',
      checked: false,
      value: 300,
      min: 60,
      max: 3600,
      numberLabel: 'Timer Length (seconds)',
    },
    {
      name: 'Time Limitation',
      options: ['Unlimited', 'Limited'],
      value: 0,
    },
    { name: 'Publicly Visible', options: ['No', 'Yes'], value: 0 },
    { name: 'Featured', options: ['No', 'Yes'], value: 0 },
    { name: 'Available Until', date: new Date('2050') },
  ];
}

function combinedToForm(event: EventDto, challenge: ChallengeDto): EntryForm[] {
  const awardingRadius = challenge.awardingRadiusF ?? 0;
  const closeRadius = challenge.closeRadiusF ?? 0;
  return [
    {
      name: 'Location',
      latitude: challenge.latF ?? 0,
      longitude: challenge.longF ?? 0,
      awardingRadiusF: awardingRadius,
      closeRadiusF: closeRadius,
    },
    { name: 'Name', characterLimit: 256, value: event.name ?? '' },
    {
      name: 'Description',
      characterLimit: 2048,
      value: event.description ?? '',
      multiline: true,
    },
    {
      name: 'Location Description',
      options: locationOptions as string[],
      value:
        challenge.location !== undefined
          ? locationOptions.indexOf(challenge.location)
          : 0,
    },
    {
      name: 'Category',
      options: eventCategoryOptions,
      value:
        event.category !== undefined
          ? eventCategoryOptions.indexOf(event.category)
          : 0,
    },
    {
      name: 'Difficulty',
      options: ['Easy', 'Normal', 'Hard'],
      value:
        event.difficulty === 'Easy' ? 0 : event.difficulty === 'Normal' ? 1 : 2,
    },
    {
      name: 'Points',
      min: 1,
      max: 1000,
      value: challenge.points ?? 0,
    },
    {
      name: 'Image URL',
      characterLimit: 2048,
      value:
        challenge.imageUrl ??
        'https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png',
    },
    {
      name: 'Awarding Distance (meters)',
      min: 1,
      max: 1000,
      value: awardingRadius,
    },
    {
      name: 'Close Distance (meters)',
      min: 1,
      max: 1000,
      value: closeRadius,
    },
    {
      name: 'Enable Timer',
      checked: (challenge.timerLength ?? 0) > 0,
      value: challenge.timerLength ?? 300,
      min: 60,
      max: 3600,
      numberLabel: 'Timer Length (seconds)',
    },
    {
      name: 'Time Limitation',
      options: ['Unlimited', 'Limited'],
      value: event.timeLimitation === 'PERPETUAL' ? 0 : 1,
    },
    {
      name: 'Publicly Visible',
      options: ['No', 'Yes'],
      value: event.indexable ? 1 : 0,
    },
    {
      name: 'Featured',
      options: ['No', 'Yes'],
      value: event.featured ? 1 : 0,
    },
    {
      name: 'Available Until',
      date: event.endTime ? new Date(event.endTime) : new Date('2050'),
    },
  ];
}

function eventFromCombinedForm(form: EntryForm[], id: string): EventDto {
  return {
    id,
    requiredMembers: -1,
    name: (form[1] as FreeEntryForm).value,
    description: (form[2] as FreeEntryForm).value,
    category: eventCategoryOptions[
      (form[4] as OptionEntryForm).value
    ] as EventCategoryDto,
    difficulty:
      (form[5] as OptionEntryForm).value === 0
        ? EventDifficultyDto.Easy
        : (form[5] as OptionEntryForm).value === 1
          ? EventDifficultyDto.Normal
          : EventDifficultyDto.Hard,
    timeLimitation:
      (form[11] as OptionEntryForm).value === 0
        ? EventTimeLimitationDto.PERPETUAL
        : EventTimeLimitationDto.LIMITED_TIME,
    indexable: (form[12] as OptionEntryForm).value === 1,
    featured: (form[13] as OptionEntryForm).value === 1,
    endTime: (form[14] as DateEntryForm).date.toUTCString(),
    challenges: [],
    latitudeF: 0,
    longitudeF: 0,
    isJourney: false,
  };
}

function challengeFromCombinedForm(
  form: EntryForm[],
  eventId: string,
  id: string,
): ChallengeDto {
  const timerForm = form[10] as CheckboxNumberEntryForm;
  return {
    id,
    name: (form[1] as FreeEntryForm).value,
    description: (form[2] as FreeEntryForm).value,
    location: locationOptions[(form[3] as OptionEntryForm).value],
    points: (form[6] as NumberEntryForm).value,
    imageUrl: (form[7] as FreeEntryForm).value,
    latF: (form[0] as MapEntryForm).latitude,
    longF: (form[0] as MapEntryForm).longitude,
    awardingRadiusF: (form[8] as NumberEntryForm).value,
    closeRadiusF: (form[9] as NumberEntryForm).value,
    linkedEventId: eventId,
    timerLength: timerForm.checked ? timerForm.value : undefined,
  };
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

function StandaloneChallengeCard(props: {
  event: EventDto;
  challenge: ChallengeDto;
  onEdit: () => void;
  onDelete: () => void;
  onCopy: () => void;
  onCreateQuiz: () => void;
  onEditQuiz: (question: QuizQuestionDto) => void;
  onDeleteQuiz: (questionId: string) => void;
}) {
  const difficultyMode =
    props.event.difficulty === 'Easy'
      ? 'Easy'
      : props.event.difficulty === 'Normal'
        ? 'Normal'
        : 'Hard';

  let categoryInput = props.event.category as string;
  const categoryType =
    categoryInput[0] + categoryInput.substring(1).toLowerCase();

  return (
    <ListCardBox>
      <ListCardTitle>{props.event.name}</ListCardTitle>
      <ListCardDescription>{props.event.description}</ListCardDescription>
      <ChallengeImage url={props.challenge.imageUrl ?? ''} />
      <ListCardBody>
        Category: <b>{categoryType}</b> <br />
        Difficulty: <b>{difficultyMode}</b> <br />
        Location: <b>{props.challenge.location}</b> <br />
        Points: <b>{props.challenge.points}</b> <br />
        Latitude: <b>{props.challenge.latF}</b>, Longitude:{' '}
        <b>{props.challenge.longF}</b> <br />
        Awarding Distance: <b>{props.challenge.awardingRadiusF} meters</b>{' '}
        <br />
        Close Distance: <b>{props.challenge.closeRadiusF} meters</b> <br />
        Timer:{' '}
        <b>
          {props.challenge.timerLength
            ? `${Math.floor(props.challenge.timerLength / 60)}m ${props.challenge.timerLength % 60}s`
            : 'None'}
        </b>{' '}
        <br />
        Publicly Visible: <b>{props.event.indexable ? 'Yes' : 'No'}</b> <br />
        Featured: <b>{props.event.featured ? 'Yes' : 'No'}</b> <br />
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
      <QuizQuestionSection
        challengeId={props.challenge.id}
        onCreateQuiz={props.onCreateQuiz}
        onEditQuiz={props.onEditQuiz}
        onDeleteQuiz={props.onDeleteQuiz}
      />
    </ListCardBox>
  );
}

export function Challenges() {
  const serverData = useContext(ServerDataContext);
  const selectedOrg = serverData.organizations.get(serverData.selectedOrg);

  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);
  const [isCopyModalOpen, setCopyModalOpen] = useState(false);
  const [copyForm, setCopyForm] = useState(() => ({
    form: makeCopyForm([], 0),
    orgIds: [] as string[],
  }));

  const [form, setForm] = useState(() => makeCombinedForm());
  const [currentEventId, setCurrentEventId] = useState('');
  const [currentChalId, setCurrentChalId] = useState('');
  const [query, setQuery] = useState('');

  // Quiz state
  const [createQuizModalOpen, setCreateQuizModalOpen] = useState(false);
  const [editQuizModalOpen, setEditQuizModalOpen] = useState(false);
  const [deleteQuizModalOpen, setDeleteQuizModalOpen] = useState(false);
  const [quizForm, setQuizForm] = useState<EntryForm[]>(() => makeQuizForm());
  const [currentQuizId, setCurrentQuizId] = useState('');
  const [currentQuizChalId, setCurrentQuizChalId] = useState('');

  const handleRadiusChange = (awardingRadius: number, closeRadius: number) => {
    setForm(prev => {
      const next = [...prev];
      const mapForm = next[0] as MapEntryForm;
      next[0] = {
        ...mapForm,
        awardingRadiusF: awardingRadius,
        closeRadiusF: closeRadius,
      };
      next[8] = { ...(next[8] as NumberEntryForm), value: awardingRadius };
      next[9] = { ...(next[9] as NumberEntryForm), value: closeRadius };
      return next;
    });
  };

  // Filter events to standalone challenges (isJourney !== true)
  const standaloneEvents = Array.from<EventDto>(
    serverData.organizations
      .get(serverData.selectedOrg)
      ?.events?.map((evId: string) => serverData.events.get(evId)!)
      .filter((ev?: EventDto) => !!ev && !ev.isJourney) ?? [],
  );

  // Build pairs of (event, challenge) for display
  const challengePairs = standaloneEvents
    .map(ev => {
      const chalId = ev.challenges?.[0];
      const chal = chalId ? serverData.challenges.get(chalId) : undefined;
      return { event: ev, challenge: chal };
    })
    .filter(pair => pair.challenge)
    .filter(pair => {
      if (query === '') return true;
      const q = query.toLowerCase();
      return (
        (pair.event.name ?? '').toLowerCase().includes(q) ||
        (pair.event.description ?? '').toLowerCase().includes(q)
      );
    })
    .sort(
      (a, b) =>
        compareTwoStrings(b.event.name ?? '', query) -
        compareTwoStrings(a.event.name ?? '', query) +
        compareTwoStrings(b.event.description ?? '', query) -
        compareTwoStrings(a.event.description ?? '', query),
    );

  // Fetch quiz questions for all visible standalone challenges
  useEffect(() => {
    for (const pair of challengePairs) {
      if (pair.challenge) {
        serverData.requestQuizQuestions(pair.challenge.id);
      }
    }
  }, [serverData.selectedOrg, standaloneEvents.length]);

  return (
    <>
      <AlertModal
        description="To create a challenge, select an organization."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <EntryModal
        title="Create Challenge"
        isOpen={createModalOpen}
        entryButtonText="CREATE"
        onEntry={async () => {
          const evId = await serverData.updateEvent({
            ...eventFromCombinedForm(form, ''),
            initialOrganizationId: serverData.selectedOrg,
          });
          if (evId) {
            serverData.updateChallenge(
              challengeFromCombinedForm(form, evId, ''),
            );
          }
          setCreateModalOpen(false);
        }}
        onCancel={() => setCreateModalOpen(false)}
        form={form}
        onRadiusChange={handleRadiusChange}
      />
      <EntryModal
        title="Edit Challenge"
        isOpen={editModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          const ev = serverData.events.get(currentEventId)!;
          serverData.updateEvent({
            ...eventFromCombinedForm(form, currentEventId),
            challenges: ev.challenges,
            isJourney: false,
          });
          serverData.updateChallenge(
            challengeFromCombinedForm(form, currentEventId, currentChalId),
          );
          setEditModalOpen(false);
        }}
        onCancel={() => setEditModalOpen(false)}
        form={form}
        onRadiusChange={handleRadiusChange}
      />
      <DeleteModal
        objectName={serverData.events.get(currentEventId)?.name ?? ''}
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteEvent(currentEventId);
          setDeleteModalOpen(false);
        }}
      />
      <EntryModal
        title="Copy Challenge"
        isOpen={isCopyModalOpen}
        entryButtonText="COPY"
        onEntry={async () => {
          const ev = serverData.events.get(currentEventId)!;
          const evId = await serverData.updateEvent({
            ...ev,
            challenges: [],
            initialOrganizationId:
              copyForm.orgIds[(copyForm.form[0] as OptionEntryForm).value],
            id: '',
          });
          if (!evId) {
            setCopyModalOpen(false);
            return;
          }
          const chalId = ev.challenges?.[0];
          if (chalId) {
            const chal = serverData.challenges.get(chalId)!;
            serverData.updateChallenge({
              ...chal,
              linkedEventId: evId,
              id: '',
            });
          }
          setCopyModalOpen(false);
        }}
        onCancel={() => setCopyModalOpen(false)}
        form={copyForm.form}
      />

      {/* Quiz Modals */}
      <EntryModal
        title="Create Quiz Question"
        isOpen={createQuizModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateQuizQuestion(
            fromQuizForm(quizForm, currentQuizChalId, ''),
          );
          setCreateQuizModalOpen(false);
        }}
        onCancel={() => setCreateQuizModalOpen(false)}
        form={quizForm}
      />
      <EntryModal
        title="Edit Quiz Question"
        isOpen={editQuizModalOpen}
        entryButtonText="SAVE"
        onEntry={() => {
          serverData.updateQuizQuestion(
            fromQuizForm(quizForm, currentQuizChalId, currentQuizId),
          );
          setEditQuizModalOpen(false);
        }}
        onCancel={() => setEditQuizModalOpen(false)}
        form={quizForm}
      />
      <DeleteModal
        objectName="this quiz question"
        isOpen={deleteQuizModalOpen}
        onClose={() => setDeleteQuizModalOpen(false)}
        onDelete={() => {
          serverData.deleteQuizQuestion(currentQuizId);
          setDeleteQuizModalOpen(false);
        }}
      />

      <SearchBar
        onCreate={() => {
          if (!selectedOrg) {
            setSelectModalOpen(true);
            return;
          }
          setForm(makeCombinedForm());
          setCreateModalOpen(true);
        }}
        onSearch={query => setQuery(query)}
      />

      {serverData.selectedOrg === '' ? (
        <CenterText>Select an organization to view challenges</CenterText>
      ) : serverData.organizations.get(serverData.selectedOrg) ? (
        challengePairs.length === 0 && (
          <CenterText>No standalone challenges in organization</CenterText>
        )
      ) : (
        <CenterText>Error getting challenges</CenterText>
      )}

      {challengePairs.map(({ event: ev, challenge: chal }) => (
        <StandaloneChallengeCard
          key={ev.id}
          event={ev}
          challenge={chal!}
          onEdit={() => {
            const freshEvent = serverData.events.get(ev.id);
            const freshChal = chal
              ? serverData.challenges.get(chal.id)
              : undefined;
            if (freshEvent && freshChal) {
              setCurrentEventId(ev.id);
              setCurrentChalId(freshChal.id);
              setForm(combinedToForm(freshEvent, freshChal));
              setEditModalOpen(true);
            }
          }}
          onDelete={() => {
            setCurrentEventId(ev.id);
            setDeleteModalOpen(true);
          }}
          onCopy={() => {
            const orgs = Array.from(serverData.organizations.values());
            const myOrgIndex = orgs.findIndex(v => v.id === selectedOrg?.id);
            setCurrentEventId(ev.id);
            setCopyForm({
              form: makeCopyForm(
                orgs.map(org => org.name ?? ''),
                myOrgIndex,
              ),
              orgIds: orgs.map(org => org.id),
            });
            setCopyModalOpen(true);
          }}
          onCreateQuiz={() => {
            setCurrentQuizChalId(chal!.id);
            setQuizForm(makeQuizForm());
            setCreateQuizModalOpen(true);
          }}
          onEditQuiz={question => {
            const freshQuestion = serverData.quizQuestions.get(question.id);
            if (freshQuestion) {
              setCurrentQuizChalId(chal!.id);
              setCurrentQuizId(question.id);
              setQuizForm(toQuizForm(freshQuestion));
              setEditQuizModalOpen(true);
            }
          }}
          onDeleteQuiz={questionId => {
            setCurrentQuizId(questionId);
            setDeleteQuizModalOpen(true);
          }}
        />
      ))}
    </>
  );
}
