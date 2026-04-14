import { useContext, useState, useEffect } from 'react';
import { compareTwoStrings } from 'string-similarity';
import styled from 'styled-components';
import { DeleteModal } from './DeleteModal';
import {
  EntryModal,
  EntryForm,
  NumberEntryForm,
  OptionEntryForm,
  FreeEntryForm,
  DateEntryForm,
  MapEntryForm,
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
import { AlertModal } from './AlertModal';
import {
  EventDifficultyDto,
  EventDto,
  EventTimeLimitationDto,
  EventCategoryDto,
  ChallengeDto,
  QuizQuestionDto,
} from '../all.dto';
import { moveDown, moveUp } from '../ordering';
import {
  ChallengeCard,
  makeChallengeForm,
  challengeFromForm,
  challengeToForm,
  makeChallengeCopyForm,
  makeQuizForm,
  fromQuizForm,
  toQuizForm,
} from './ChallengeCardComponents';

const categoryOptions = [
  'FOOD',
  'NATURE',
  'HISTORICAL',
  'RESIDENTIAL',
  'LANDMARK',
  'ARTS',
  'ATHLETICS',
  'LIBRARY',
  'ACADEMIC',
  'RECREATION',
];

// Event form helpers
function makeEventForm() {
  return [
    { name: 'Name', characterLimit: 256, value: '' },
    { name: 'Description', characterLimit: 2048, value: '', multiline: true },
    {
      name: 'Category',
      options: categoryOptions,
      value: 1,
    },
    { name: 'Required Members', value: -1, min: -1, max: 99 },
    {
      name: 'Time Limitation',
      options: ['Unlimited', 'Limited'],
      value: 0,
    },
    {
      name: 'Difficulty',
      options: ['Easy', 'Normal', 'Hard'],
      value: 0,
    },
    { name: 'Publicly Visible', options: ['No', 'Yes'], value: 0 },
    { name: 'Featured', options: ['No', 'Yes'], value: 0 },
    { name: 'Available Until', date: new Date('2050') },
  ] as EntryForm[];
}

function eventFromForm(form: EntryForm[], id: string): EventDto {
  return {
    id,
    requiredMembers: (form[3] as NumberEntryForm).value,
    timeLimitation:
      (form[4] as OptionEntryForm).value === 0
        ? EventTimeLimitationDto.PERPETUAL
        : EventTimeLimitationDto.LIMITED_TIME,
    name: (form[0] as FreeEntryForm).value,
    description: (form[1] as FreeEntryForm).value,
    category: categoryOptions[
      (form[2] as OptionEntryForm).value
    ] as EventCategoryDto,
    indexable: (form[6] as OptionEntryForm).value === 1,
    featured: (form[7] as OptionEntryForm).value === 1,
    endTime: (form[8] as DateEntryForm).date.toUTCString(),
    challenges: [],
    difficulty:
      (form[5] as OptionEntryForm).value === 0
        ? EventDifficultyDto.Easy
        : (form[5] as OptionEntryForm).value === 1
          ? EventDifficultyDto.Normal
          : EventDifficultyDto.Hard,
    latitudeF: 0,
    longitudeF: 0,
    isJourney: true,
  };
}

function eventToForm(event: EventDto) {
  return [
    { name: 'Name', characterLimit: 256, value: event.name },
    {
      name: 'Description',
      characterLimit: 2048,
      value: event.description,
      multiline: true,
    },
    {
      name: 'Category',
      options: categoryOptions,
      value:
        event.category !== undefined
          ? categoryOptions.indexOf(event.category)
          : 0,
    },
    {
      name: 'Required Members',
      value: event.requiredMembers,
      min: -1,
      max: 99,
    },
    {
      name: 'Time Limitation',
      options: ['Unlimited', 'Limited'],
      value: event.timeLimitation === 'PERPETUAL' ? 0 : 1,
    },
    {
      name: 'Difficulty',
      options: ['Easy', 'Normal', 'Hard'],
      value:
        event.difficulty === 'Easy' ? 0 : event.difficulty === 'Normal' ? 1 : 2,
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
      date: event.endTime && new Date(event.endTime),
    },
  ] as EntryForm[];
}

function makeEventCopyForm(orgOptions: string[], initialIndex: number) {
  return [
    {
      name: 'Target Organization',
      options: orgOptions,
      value: initialIndex,
    },
  ] as EntryForm[];
}

// Styled components for expandable challenge section
const ChallengesSection = styled.div`
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #ddd;
`;

const ChallengesHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  padding: 4px 0;
  &:hover {
    background: #f9f9f9;
  }
`;

const ChallengesContent = styled.div`
  margin-top: 8px;
`;

function JourneyCard(props: {
  event: EventDto;
  isExpanded: boolean;
  onToggleExpand: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onCopy: () => void;
  children?: React.ReactNode;
}) {
  const requiredText =
    props.event.requiredMembers && props.event.requiredMembers < 0
      ? 'Any Amount'
      : props.event.requiredMembers;

  const timeLimitation =
    props.event.timeLimitation === 'LIMITED_TIME' ? 'Limited' : 'Unlimited';

  const difficultyMode =
    props.event.difficulty === 'Easy'
      ? 'Easy'
      : props.event.difficulty === 'Normal'
        ? 'Normal'
        : 'Hard';

  let categoryInput = props.event.category as string;
  const categoryType =
    categoryInput[0] + categoryInput.substring(1).toLowerCase();

  const affirmOfBool = (val: boolean) => (val ? 'Yes' : 'No');

  return (
    <ListCardBox>
      <ListCardTitle>{props.event.name}</ListCardTitle>
      <ListCardDescription>{props.event.description}</ListCardDescription>
      <ListCardBody>
        Id: <b>{props.event.id}</b>
        <br />
        Available Until:{' '}
        <b>
          {props.event.endTime && new Date(props.event.endTime).toString()}
        </b>{' '}
        <br />
        Required Players: <b>{requiredText}</b> <br />
        Time Limitation: <b>{timeLimitation}</b> <br />
        Challenge Count: <b>{props.event.challenges?.length}</b> <br />
        Difficulty: <b>{difficultyMode}</b> <br />
        Category: <b>{categoryType}</b> <br />
        Publicly Visible: <b>{affirmOfBool(!!props.event.indexable)}</b> <br />
        Featured: <b>{affirmOfBool(!!props.event.featured)}</b> <br />
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
      <ChallengesSection>
        <ChallengesHeader onClick={props.onToggleExpand}>
          <span>
            <b>Challenges</b> ({props.event.challenges?.length ?? 0})
          </span>
          <span>{props.isExpanded ? '▼' : '▶'}</span>
        </ChallengesHeader>
        {props.isExpanded && (
          <ChallengesContent>{props.children}</ChallengesContent>
        )}
      </ChallengesSection>
    </ListCardBox>
  );
}

export function Journeys() {
  const serverData = useContext(ServerDataContext);
  const selectedOrg = serverData.organizations.get(serverData.selectedOrg);

  // Journey (event) CRUD state
  const [isCreateModalOpen, setCreateModalOpen] = useState(false);
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);
  const [isCopyModalOpen, setCopyModalOpen] = useState(false);
  const [copyForm, setCopyForm] = useState(() => ({
    form: makeEventCopyForm([], 0),
    orgIds: [] as string[],
  }));
  const [form, setForm] = useState(() => makeEventForm());
  const [currentId, setCurrentId] = useState('');
  const [query, setQuery] = useState('');

  // Expanded journey state
  const [expandedJourneyId, setExpandedJourneyId] = useState<string | null>(
    null,
  );

  // Challenge CRUD state (within expanded journey)
  const [chalCreateModalOpen, setChalCreateModalOpen] = useState(false);
  const [chalEditModalOpen, setChalEditModalOpen] = useState(false);
  const [chalDeleteModalOpen, setChalDeleteModalOpen] = useState(false);
  const [chalForm, setChalForm] = useState(() => makeChallengeForm());
  const [currentChalId, setCurrentChalId] = useState('');
  const [isChalCopyModalOpen, setChalCopyModalOpen] = useState(false);
  const [chalCopyForm, setChalCopyForm] = useState(() => ({
    form: makeChallengeCopyForm([], 0),
    evIds: [] as string[],
  }));

  // Quiz state
  const [createQuizModalOpen, setCreateQuizModalOpen] = useState(false);
  const [editQuizModalOpen, setEditQuizModalOpen] = useState(false);
  const [deleteQuizModalOpen, setDeleteQuizModalOpen] = useState(false);
  const [quizForm, setQuizForm] = useState<EntryForm[]>(() => makeQuizForm());
  const [currentQuizId, setCurrentQuizId] = useState('');
  const [currentQuizChalId, setCurrentQuizChalId] = useState('');

  const handleChalRadiusChange = (
    awardingRadius: number,
    closeRadius: number,
  ) => {
    setChalForm(prev => {
      const next = [...prev];
      const mapForm = next[0] as MapEntryForm;
      next[0] = {
        ...mapForm,
        awardingRadiusF: awardingRadius,
        closeRadiusF: closeRadius,
      };
      next[6] = { ...(next[6] as NumberEntryForm), value: awardingRadius };
      next[7] = { ...(next[7] as NumberEntryForm), value: closeRadius };
      return next;
    });
  };

  // Fetch quiz questions for expanded journey's challenges
  useEffect(() => {
    if (expandedJourneyId) {
      const ev = serverData.events.get(expandedJourneyId);
      if (ev?.challenges) {
        for (const challengeId of ev.challenges) {
          serverData.requestQuizQuestions(challengeId);
        }
      }
    }
  }, [expandedJourneyId]);

  // Filter events to journeys only (isJourney === true)
  const journeys = Array.from<EventDto>(
    serverData.organizations
      .get(serverData.selectedOrg)
      ?.events?.map((evId: string) => serverData.events.get(evId)!)
      .filter((ev?: EventDto) => !!ev && ev.isJourney) ?? [],
  )
    .filter((ev: EventDto) => {
      if (query === '') return true;
      const q = query.toLowerCase();
      return (
        (ev.name ?? '').toLowerCase().includes(q) ||
        (ev.description ?? '').toLowerCase().includes(q)
      );
    })
    .sort(
      (a: EventDto, b: EventDto) =>
        compareTwoStrings(b.name ?? '', query) -
        compareTwoStrings(a.name ?? '', query) +
        compareTwoStrings(b.description ?? '', query) -
        compareTwoStrings(a.description ?? '', query),
    );

  return (
    <>
      {/* Journey modals */}
      <AlertModal
        description="To create a journey, select an organization."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <EntryModal
        title="Create Journey"
        isOpen={isCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateEvent({
            ...eventFromForm(form, ''),
            initialOrganizationId: serverData.selectedOrg,
          });
          setCreateModalOpen(false);
        }}
        onCancel={() => setCreateModalOpen(false)}
        form={form}
      />
      <EntryModal
        title="Edit Journey"
        isOpen={isEditModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          const ev = serverData.events.get(currentId)!;
          serverData.updateEvent({
            ...eventFromForm(form, currentId),
            challenges: ev.challenges,
            isJourney: true,
          });
          setEditModalOpen(false);
        }}
        onCancel={() => setEditModalOpen(false)}
        form={form}
      />
      <EntryModal
        title="Copy Journey"
        isOpen={isCopyModalOpen}
        entryButtonText="COPY"
        onEntry={async () => {
          const ev = serverData.events.get(currentId)!;
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
          for (const chalId of [...ev.challenges!].reverse()!) {
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
      <DeleteModal
        objectName={serverData.events.get(currentId)?.name ?? ''}
        isOpen={isDeleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteEvent(currentId);
          if (expandedJourneyId === currentId) setExpandedJourneyId(null);
          setDeleteModalOpen(false);
        }}
      />

      {/* Challenge modals (within expanded journey) */}
      <EntryModal
        title="Create Challenge"
        isOpen={chalCreateModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          if (expandedJourneyId) {
            serverData.updateChallenge(
              challengeFromForm(chalForm, expandedJourneyId, ''),
            );
          }
          setChalCreateModalOpen(false);
        }}
        onCancel={() => setChalCreateModalOpen(false)}
        form={chalForm}
        onRadiusChange={handleChalRadiusChange}
      />
      <EntryModal
        title="Edit Challenge"
        isOpen={chalEditModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          if (expandedJourneyId) {
            serverData.updateChallenge(
              challengeFromForm(chalForm, expandedJourneyId, currentChalId),
            );
          }
          setChalEditModalOpen(false);
        }}
        onCancel={() => setChalEditModalOpen(false)}
        form={chalForm}
        onRadiusChange={handleChalRadiusChange}
      />
      <DeleteModal
        objectName={serverData.challenges.get(currentChalId)?.name ?? ''}
        isOpen={chalDeleteModalOpen}
        onClose={() => setChalDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteChallenge(currentChalId);
          setChalDeleteModalOpen(false);
        }}
      />
      <EntryModal
        title="Copy Challenge"
        isOpen={isChalCopyModalOpen}
        entryButtonText="COPY"
        onEntry={async () => {
          const chal = serverData.challenges.get(currentChalId)!;
          serverData.updateChallenge({
            ...chal,
            linkedEventId:
              chalCopyForm.evIds[
                (chalCopyForm.form[0] as OptionEntryForm).value
              ],
            id: '',
          });
          setChalCopyModalOpen(false);
        }}
        onCancel={() => setChalCopyModalOpen(false)}
        form={chalCopyForm.form}
      />

      {/* Quiz modals */}
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
          setForm(makeEventForm());
          setCreateModalOpen(true);
        }}
        onSearch={query => setQuery(query)}
      />

      {serverData.selectedOrg === '' ? (
        <CenterText>Select an organization to view journeys</CenterText>
      ) : serverData.organizations.get(serverData.selectedOrg) ? (
        journeys.length === 0 && (
          <CenterText>No journeys in organization</CenterText>
        )
      ) : (
        <CenterText>Error getting journeys</CenterText>
      )}

      {journeys.map(ev => {
        const isExpanded = expandedJourneyId === ev.id;
        const expandedEvent = isExpanded
          ? serverData.events.get(ev.id)
          : undefined;

        return (
          <JourneyCard
            key={ev.id}
            event={ev}
            isExpanded={isExpanded}
            onToggleExpand={() =>
              setExpandedJourneyId(isExpanded ? null : ev.id)
            }
            onDelete={() => {
              setCurrentId(ev.id);
              setDeleteModalOpen(true);
            }}
            onEdit={() => {
              const freshEvent = serverData.events.get(ev.id);
              if (freshEvent) {
                setCurrentId(ev.id);
                setForm(eventToForm(freshEvent));
                setEditModalOpen(true);
              }
            }}
            onCopy={() => {
              const orgs = Array.from(serverData.organizations.values());
              const myOrgIndex = orgs.findIndex(v => v.id === selectedOrg?.id);
              setCurrentId(ev.id);
              setCopyForm({
                form: makeEventCopyForm(
                  orgs.map(org => org.name ?? ''),
                  myOrgIndex,
                ),
                orgIds: orgs.map(org => org.id),
              });
              setCopyModalOpen(true);
            }}
          >
            {/* Inline challenge list when expanded */}
            <HButton
              onClick={() => {
                setChalForm(makeChallengeForm());
                setChalCreateModalOpen(true);
              }}
            >
              + ADD CHALLENGE
            </HButton>
            {expandedEvent?.challenges?.length === 0 && (
              <CenterText>No challenges yet</CenterText>
            )}
            {expandedEvent?.challenges
              ?.filter((chalId: string) => serverData.challenges.get(chalId))
              .map((chalId: string) => serverData.challenges.get(chalId)!)
              .map((chal: ChallengeDto) => (
                <ChallengeCard
                  key={chal.id}
                  challenge={chal}
                  onUp={() => {
                    if (!expandedEvent.challenges) return;
                    expandedEvent.challenges = moveUp(
                      expandedEvent.challenges,
                      expandedEvent.challenges.findIndex(
                        (id: string) => id === chal.id,
                      ) ?? 0,
                    );
                    serverData.updateEvent(expandedEvent);
                  }}
                  onDown={() => {
                    if (!expandedEvent.challenges) return;
                    expandedEvent.challenges = moveDown(
                      expandedEvent.challenges,
                      expandedEvent.challenges.findIndex(
                        (id: string) => id === chal.id,
                      ),
                    );
                    serverData.updateEvent(expandedEvent);
                  }}
                  onEdit={() => {
                    const freshChallenge = serverData.challenges.get(chal.id);
                    if (freshChallenge) {
                      setCurrentChalId(chal.id);
                      setChalForm(challengeToForm(freshChallenge));
                      setChalEditModalOpen(true);
                    }
                  }}
                  onDelete={() => {
                    setCurrentChalId(chal.id);
                    setChalDeleteModalOpen(true);
                  }}
                  onCopy={() => {
                    const evs = Array.from(serverData.events.values());
                    const myEvIndex = evs.findIndex(
                      v => v.id === expandedEvent?.id,
                    );
                    setCurrentChalId(chal.id);
                    setChalCopyForm({
                      form: makeChallengeCopyForm(
                        evs.map(e => e.name ?? ''),
                        myEvIndex,
                      ),
                      evIds: evs.map(e => e.id),
                    });
                    setChalCopyModalOpen(true);
                  }}
                  onCreateQuiz={() => {
                    setCurrentQuizChalId(chal.id);
                    setQuizForm(makeQuizForm());
                    setCreateQuizModalOpen(true);
                  }}
                  onEditQuiz={question => {
                    const freshQuestion = serverData.quizQuestions.get(
                      question.id,
                    );
                    if (freshQuestion) {
                      setCurrentQuizChalId(chal.id);
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
          </JourneyCard>
        );
      })}
    </>
  );
}
