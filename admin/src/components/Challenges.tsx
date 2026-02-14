import { useContext, useState, useEffect } from 'react';
import { compareTwoStrings } from 'string-similarity';
import styled, { css } from 'styled-components';
import {
  ChallengeDto,
  ChallengeLocationDto,
  QuizQuestionDto,
} from '../all.dto';
import { moveDown, moveUp } from '../ordering';
import { AlertModal } from './AlertModal';
import { DeleteModal } from './DeleteModal';
import {
  EntryForm,
  EntryModal,
  FreeEntryForm,
  OptionEntryForm,
  MapEntryForm,
  NumberEntryForm,
  CheckboxNumberEntryForm,
  AnswersEntryForm,
  OptionWithCustomEntryForm,
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

const ChallengeImage = styled.div<{ url: string }>`
  width: calc(100% + 23px);
  height: 250px;
  margin-left: -12px;
  margin-bottom: 8px;
  background-size: cover;
  background-position: center;
  ${props => css`
    background-image: url(${'"' + props.url + '"'});
  `}
`;

const locationOptions: ChallengeLocationDto[] = [
  ChallengeLocationDto.ENG_QUAD,
  ChallengeLocationDto.ARTS_QUAD,
  ChallengeLocationDto.AG_QUAD,
  ChallengeLocationDto.CENTRAL_CAMPUS,
  ChallengeLocationDto.NORTH_CAMPUS,
  ChallengeLocationDto.WEST_CAMPUS,
  ChallengeLocationDto.CORNELL_ATHLETICS,
  ChallengeLocationDto.VET_SCHOOL,
  ChallengeLocationDto.COLLEGETOWN,
  ChallengeLocationDto.ITHACA_COMMONS,
  ChallengeLocationDto.ANY,
];

// Category options for quiz questions
const categoryOptions = [
  'HISTORICAL',
  'SCIENCE',
  'CULTURE',
  'PHYSICAL',
  'FOOD',
  'NATURE',
];

// Styled components for quiz section
const QuizSection = styled.div`
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #eee;
`;

const QuizHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  padding: 4px 0;
  &:hover {
    background: #f9f9f9;
  }
`;

const QuizQuestionItem = styled.div`
  background: #f5f5f5;
  border-radius: 4px;
  padding: 8px;
  margin: 8px 0;
`;

// Quiz form helpers
function makeQuizForm(): EntryForm[] {
  return [
    { name: 'Question', characterLimit: 2048, value: '' },
    { name: 'Explanation (optional)', characterLimit: 2048, value: '' },
    {
      name: 'Category',
      options: categoryOptions,
      value: 0,
      customValue: '',
      customOptionLabel: 'Custom...',
    },
    { name: 'Difficulty', min: 1, max: 5, value: 1 },
    { name: 'Point Value', min: 1, max: 100, value: 10 },
    {
      name: 'Answers (select correct answer)',
      answers: [
        { text: '', isCorrect: true },
        { text: '', isCorrect: false },
      ],
      minAnswers: 2,
      maxAnswers: 4,
    },
  ];
}

function toQuizForm(question: QuizQuestionDto): EntryForm[] {
  const categoryIndex = categoryOptions.indexOf(
    question.category ?? 'HISTORICAL',
  );
  const isCustomCategory = categoryIndex === -1;

  return [
    {
      name: 'Question',
      characterLimit: 2048,
      value: question.questionText ?? '',
    },
    {
      name: 'Explanation (optional)',
      characterLimit: 2048,
      value: question.explanation ?? '',
    },
    {
      name: 'Category',
      options: categoryOptions,
      value: isCustomCategory ? categoryOptions.length : categoryIndex,
      customValue: isCustomCategory ? (question.category ?? '') : '',
      customOptionLabel: 'Custom...',
    },
    { name: 'Difficulty', min: 1, max: 5, value: question.difficulty ?? 1 },
    { name: 'Point Value', min: 1, max: 100, value: question.pointValue ?? 10 },
    {
      name: 'Answers (select correct answer)',
      answers: question.answers?.map(a => ({
        text: a.answerText,
        isCorrect: a.isCorrect ?? false,
      })) ?? [
          { text: '', isCorrect: true },
          { text: '', isCorrect: false },
        ],
      minAnswers: 2,
      maxAnswers: 4,
    },
  ];
}

function fromQuizForm(
  form: EntryForm[],
  challengeId: string,
  id: string,
): QuizQuestionDto {
  const categoryForm = form[2] as OptionWithCustomEntryForm;
  const isCustom = categoryForm.value === categoryOptions.length;

  return {
    id,
    challengeId,
    questionText: (form[0] as FreeEntryForm).value,
    explanation: (form[1] as FreeEntryForm).value || undefined,
    category: isCustom
      ? categoryForm.customValue.trim() || 'GENERAL'
      : categoryOptions[categoryForm.value],
    difficulty: (form[3] as NumberEntryForm).value,
    pointValue: (form[4] as NumberEntryForm).value,
    answers: (form[5] as AnswersEntryForm).answers.map(a => ({
      answerText: a.text,
      isCorrect: a.isCorrect,
    })),
  };
}

// QuizQuestionSection component
function QuizQuestionSection(props: {
  challengeId: string;
  onCreateQuiz: () => void;
  onEditQuiz: (question: QuizQuestionDto) => void;
  onDeleteQuiz: (questionId: string) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const serverData = useContext(ServerDataContext);

  // Filter questions for this challenge
  const questions = Array.from(serverData.quizQuestions.values()).filter(
    q => q.challengeId === props.challengeId,
  );

  useEffect(() => {
    if (expanded) {
      serverData.requestQuizQuestions(props.challengeId);
    }
  }, [expanded, props.challengeId]);

  return (
    <QuizSection>
      <QuizHeader onClick={() => setExpanded(!expanded)}>
        <span>
          <b>Quiz Questions</b> ({questions.length})
        </span>
        <span>{expanded ? '▼' : '▶'}</span>
      </QuizHeader>

      {expanded && (
        <>
          {questions.map(q => (
            <QuizQuestionItem key={q.id}>
              <div>
                <b>Q:</b> {q.questionText}
              </div>
              <div>
                <small>
                  Category: {q.category} | Difficulty: {q.difficulty} | Points:{' '}
                  {q.pointValue}
                </small>
              </div>
              <div style={{ marginTop: 4 }}>
                <HButton onClick={() => props.onEditQuiz(q)}>EDIT</HButton>
                <HButton onClick={() => props.onDeleteQuiz(q.id)} float="right">
                  DELETE
                </HButton>
              </div>
            </QuizQuestionItem>
          ))}
          <HButton onClick={props.onCreateQuiz}>+ ADD QUESTION</HButton>
        </>
      )}
    </QuizSection>
  );
}

function ChallengeCard(props: {
  challenge: ChallengeDto;
  onUp: () => void;
  onDown: () => void;
  onDelete: () => void;
  onEdit: () => void;
  onCopy: () => void;
  onCreateQuiz: () => void;
  onEditQuiz: (question: QuizQuestionDto) => void;
  onDeleteQuiz: (questionId: string) => void;
}) {
  return (
    <ListCardBox>
      <ListCardTitle>{props.challenge.name}</ListCardTitle>
      <ListCardDescription>{props.challenge.description}</ListCardDescription>
      <ChallengeImage url={props.challenge.imageUrl ?? ''} />
      <ListCardBody>
        Id: <b>{props.challenge.id}</b> <br />
        Location: <b>{props.challenge.location}</b> <br />
        Score: <b>{props.challenge.points}</b> <br />
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
        </b>
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

function makeForm(): EntryForm[] {
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
    {
      name: 'Location Description',
      options: locationOptions as string[],
      value: 0,
    },
    { name: 'Name', characterLimit: 256, value: '' },
    { name: 'Description', characterLimit: 2048, value: '' },
    { name: 'Points', min: 1, max: 1000, value: 50 },
    { name: 'Image URL', characterLimit: 2048, value: '' },
    { name: 'Awarding Distance (meters)', min: 1, max: 1000, value: awardingRadius },
    { name: 'Close Distance (meters)', min: 1, max: 1000, value: closeRadius },
    {
      name: 'Enable Timer',
      checked: false,
      value: 300,
      min: 60,
      max: 3600,
      numberLabel: 'Timer Length (seconds)',
    },
  ];
}

function toForm(challenge: ChallengeDto) {
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
    {
      name: 'Location Description',
      options: locationOptions,
      value:
        challenge.location !== undefined
          ? locationOptions.indexOf(challenge.location)
          : 0,
    },
    { name: 'Name', characterLimit: 256, value: challenge.name ?? '' },
    {
      name: 'Description',
      characterLimit: 2048,
      value: challenge.description ?? '',
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
  ];
}

function fromForm(
  form: EntryForm[],
  eventId: string,
  id: string,
): ChallengeDto {
  const timerForm = form[8] as CheckboxNumberEntryForm;
  return {
    id,
    name: (form[2] as FreeEntryForm).value,
    location: locationOptions[(form[1] as OptionEntryForm).value],
    description: (form[3] as FreeEntryForm).value,
    points: (form[4] as NumberEntryForm).value,
    imageUrl: (form[5] as FreeEntryForm).value,
    latF: (form[0] as MapEntryForm).latitude,
    longF: (form[0] as MapEntryForm).longitude,
    awardingRadiusF: (form[6] as NumberEntryForm).value,
    closeRadiusF: (form[7] as NumberEntryForm).value,
    linkedEventId: eventId,
    timerLength: timerForm.checked ? timerForm.value : undefined,
  };
}

function makeCopyForm(evOptions: string[], initialIndex: number) {
  return [
    {
      name: 'Target Event',
      options: evOptions,
      value: initialIndex,
    },
  ] as EntryForm[];
}

export function Challenges() {
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [selectModalOpen, setSelectModalOpen] = useState(false);

  const [form, setForm] = useState(() => makeForm());
  const [currentId, setCurrentId] = useState('');
  const [query, setQuery] = useState('');

  const [isCopyModalOpen, setCopyModalOpen] = useState(false);
  const [copyForm, setCopyForm] = useState(() => ({
    form: makeCopyForm([], 0),
    evIds: [] as string[],
  }));

  // Quiz state
  const [createQuizModalOpen, setCreateQuizModalOpen] = useState(false);
  const [editQuizModalOpen, setEditQuizModalOpen] = useState(false);
  const [deleteQuizModalOpen, setDeleteQuizModalOpen] = useState(false);
  const [quizForm, setQuizForm] = useState<EntryForm[]>(() => makeQuizForm());
  const [currentQuizId, setCurrentQuizId] = useState('');
  const [currentChallengeId, setCurrentChallengeId] = useState('');

  const serverData = useContext(ServerDataContext);
  const selectedEvent = serverData.events.get(serverData.selectedEvent);

  // Fetch quiz questions for all challenges when event is selected
  useEffect(() => {
    if (selectedEvent?.challenges) {
      for (const challengeId of selectedEvent.challenges) {
        serverData.requestQuizQuestions(challengeId);
      }
    }
  }, [serverData.selectedEvent, selectedEvent?.challenges?.length]);

  return (
    <>
      <AlertModal
        description="To create a challenge, select an event."
        isOpen={selectModalOpen}
        onClose={() => setSelectModalOpen(false)}
      />
      <EntryModal
        title="Create Challenge"
        isOpen={createModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateChallenge(
            fromForm(form, serverData.selectedEvent, ''),
          );
          setCreateModalOpen(false);
        }}
        onCancel={() => {
          setCreateModalOpen(false);
        }}
        form={form}
      />
      <EntryModal
        title="Edit Challenge"
        isOpen={editModalOpen}
        entryButtonText="EDIT"
        onEntry={() => {
          serverData.updateChallenge(
            fromForm(form, serverData.selectedEvent, currentId),
          );
          setEditModalOpen(false);
        }}
        onCancel={() => {
          setEditModalOpen(false);
        }}
        form={form}
      />
      <DeleteModal
        objectName={serverData.challenges.get(currentId)?.name ?? ''}
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onDelete={() => {
          serverData.deleteChallenge(currentId);
          setDeleteModalOpen(false);
        }}
      />
      <EntryModal
        title="Copy Challenge"
        isOpen={isCopyModalOpen}
        entryButtonText="COPY"
        onEntry={async () => {
          const chal = serverData.challenges.get(currentId)!;
          serverData.updateChallenge({
            ...chal,
            linkedEventId:
              copyForm.evIds[(copyForm.form[0] as OptionEntryForm).value],
            id: '',
          });
          setCopyModalOpen(false);
        }}
        onCancel={() => {
          setCopyModalOpen(false);
        }}
        form={copyForm.form}
      />

      {/* Quiz Modals */}
      <EntryModal
        title="Create Quiz Question"
        isOpen={createQuizModalOpen}
        entryButtonText="CREATE"
        onEntry={() => {
          serverData.updateQuizQuestion(
            fromQuizForm(quizForm, currentChallengeId, ''),
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
            fromQuizForm(quizForm, currentChallengeId, currentQuizId),
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
          setForm(makeForm());
          setCreateModalOpen(!!selectedEvent);
          if (!selectedEvent) {
            setSelectModalOpen(true);
          }
        }}
        onSearch={query => setQuery(query)}
      />

      {serverData.selectedEvent === '' ? (
        <CenterText>Select an event to view challenges</CenterText>
      ) : serverData.events.get(serverData.selectedEvent) ? (
        serverData.events.get(serverData.selectedEvent)?.challenges?.length ===
        0 && <CenterText>No challenges in event</CenterText>
      ) : (
        <CenterText>Error getting challenges</CenterText>
      )}
      {selectedEvent?.challenges
        ?.filter((chalId: string) => serverData.challenges.get(chalId))
        .map((chalId: string) => serverData.challenges.get(chalId)!)
        .sort((a: ChallengeDto, b: ChallengeDto) =>
          query === ''
            ? 0
            : compareTwoStrings(b.name ?? '', query) -
            compareTwoStrings(a.name ?? '', query) +
            compareTwoStrings(b.description ?? '', query) -
            compareTwoStrings(a.description ?? '', query),
        )
        .map((chal: ChallengeDto) => (
          <ChallengeCard
            key={chal.id}
            challenge={chal}
            onUp={() => {
              if (query !== '' || !selectedEvent.challenges) return;
              selectedEvent.challenges = moveUp(
                selectedEvent.challenges,
                selectedEvent.challenges.findIndex(
                  (id: string) => id === chal.id,
                ) ?? 0,
              );
              serverData.updateEvent(selectedEvent);
            }}
            onDown={() => {
              if (query !== '' || !selectedEvent.challenges) return;
              selectedEvent.challenges = moveDown(
                selectedEvent.challenges,
                selectedEvent.challenges.findIndex(
                  (id: string) => id === chal.id,
                ),
              );
              serverData.updateEvent(selectedEvent);
            }}
            onEdit={() => {
              const freshChallenge = serverData.challenges.get(chal.id);
              if (freshChallenge) {
                setCurrentId(chal.id);
                setForm(toForm(freshChallenge));
                setEditModalOpen(true);
              }
            }}
            onDelete={() => {
              setCurrentId(chal.id);
              setDeleteModalOpen(true);
            }}
            onCopy={() => {
              const evs = Array.from(serverData.events.values());
              const myEvIndex = evs.findIndex(v => v.id === selectedEvent?.id);
              setCurrentId(chal.id);
              setCopyForm({
                form: makeCopyForm(
                  evs.map(ev => ev.name ?? ''),
                  myEvIndex,
                ),
                evIds: evs.map(ev => ev.id),
              });
              setCopyModalOpen(true);
            }}
            onCreateQuiz={() => {
              setCurrentChallengeId(chal.id);
              setQuizForm(makeQuizForm());
              setCreateQuizModalOpen(true);
            }}
            onEditQuiz={question => {
              const freshQuestion = serverData.quizQuestions.get(question.id);
              if (freshQuestion) {
                setCurrentChallengeId(chal.id);
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
