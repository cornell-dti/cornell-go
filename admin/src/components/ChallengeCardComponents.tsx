import { useContext, useState, useEffect } from 'react';
import styled, { css } from 'styled-components';
import {
  ChallengeDto,
  ChallengeLocationDto,
  QuizQuestionDto,
} from '../all.dto';
import {
  EntryForm,
  FreeEntryForm,
  NumberEntryForm,
  OptionEntryForm,
  MapEntryForm,
  CheckboxNumberEntryForm,
  CheckboxDateEntryForm,
  AnswersEntryForm,
  OptionWithCustomEntryForm,
} from './EntryModal';
import { HButton } from './HButton';
import {
  ListCardBody,
  ListCardBox,
  ListCardButtons,
  ListCardDescription,
  ListCardTitle,
} from './ListCard';
import { ServerDataContext } from './ServerData';

export const ChallengeImage = styled.div<{ url: string }>`
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

export const locationOptions: ChallengeLocationDto[] = [
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

export const quizCategoryOptions = [
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
export function makeQuizForm(): EntryForm[] {
  return [
    { name: 'Question', characterLimit: 2048, value: '' },
    { name: 'Explanation (optional)', characterLimit: 2048, value: '' },
    {
      name: 'Category',
      options: quizCategoryOptions,
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

export function toQuizForm(question: QuizQuestionDto): EntryForm[] {
  const categoryIndex = quizCategoryOptions.indexOf(
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
      options: quizCategoryOptions,
      value: isCustomCategory ? quizCategoryOptions.length : categoryIndex,
      customValue: isCustomCategory ? (question.category ?? '') : '',
      customOptionLabel: 'Custom...',
    },
    { name: 'Difficulty', min: 1, max: 5, value: question.difficulty ?? 1 },
    {
      name: 'Point Value',
      min: 1,
      max: 100,
      value: question.pointValue ?? 10,
    },
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

export function fromQuizForm(
  form: EntryForm[],
  challengeId: string,
  id: string,
): QuizQuestionDto {
  const categoryForm = form[2] as OptionWithCustomEntryForm;
  const isCustom = categoryForm.value === quizCategoryOptions.length;

  return {
    id,
    challengeId,
    questionText: (form[0] as FreeEntryForm).value,
    explanation: (form[1] as FreeEntryForm).value || undefined,
    category: isCustom
      ? categoryForm.customValue.trim() || 'GENERAL'
      : quizCategoryOptions[categoryForm.value],
    difficulty: (form[3] as NumberEntryForm).value,
    pointValue: (form[4] as NumberEntryForm).value,
    answers: (form[5] as AnswersEntryForm).answers.map(a => ({
      answerText: a.text,
      isCorrect: a.isCorrect,
    })),
  };
}

// Challenge form helpers
export function makeChallengeForm(): EntryForm[] {
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
    { name: 'Description', characterLimit: 2048, value: '', multiline: true },
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
      name: 'Scheduled Start Time',
      checked: false,
      date: new Date(),
    },
    {
      name: 'Scheduled End Time',
      checked: false,
      date: new Date(),
    },
  ];
}

export function challengeToForm(challenge: ChallengeDto) {
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
      multiline: true,
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
      name: 'Scheduled Start Time',
      checked: !!challenge.scheduledStartTime,
      date: challenge.scheduledStartTime
        ? new Date(challenge.scheduledStartTime)
        : new Date(),
    },
    {
      name: 'Scheduled End Time',
      checked: !!challenge.scheduledEndTime,
      date: challenge.scheduledEndTime
        ? new Date(challenge.scheduledEndTime)
        : new Date(),
    },
  ];
}

export function challengeFromForm(
  form: EntryForm[],
  eventId: string,
  id: string,
): ChallengeDto {
  const timerForm = form[8] as CheckboxNumberEntryForm;
  const startForm = form[9] as CheckboxDateEntryForm;
  const endForm = form[10] as CheckboxDateEntryForm;
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
    scheduledStartTime: startForm.checked
      ? startForm.date.toISOString()
      : undefined,
    scheduledEndTime: endForm.checked ? endForm.date.toISOString() : undefined,
  };
}

export function makeChallengeCopyForm(
  evOptions: string[],
  initialIndex: number,
) {
  return [
    {
      name: 'Target Event',
      options: evOptions,
      value: initialIndex,
    },
  ] as EntryForm[];
}

// QuizQuestionSection component
export function QuizQuestionSection(props: {
  challengeId: string;
  onCreateQuiz: () => void;
  onEditQuiz: (question: QuizQuestionDto) => void;
  onDeleteQuiz: (questionId: string) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const serverData = useContext(ServerDataContext);

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

// ChallengeCard component
export function ChallengeCard(props: {
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
        <br />
        Scheduled:{' '}
        <b>
          {props.challenge.scheduledStartTime ||
          props.challenge.scheduledEndTime
            ? `${props.challenge.scheduledStartTime ? new Date(props.challenge.scheduledStartTime).toLocaleString() : '—'} to ${props.challenge.scheduledEndTime ? new Date(props.challenge.scheduledEndTime).toLocaleString() : '—'}`
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
