import { useContext, useEffect, useMemo, useState } from 'react';
import styled from 'styled-components';
import { ServerConnectionContext } from './ServerConnection';
import { ServerApi } from './ServerApi';
import { FeedbackDto } from '../all.dto';
import {
  ListCardBox,
  ListCardTitle,
  ListCardBody,
  CenterText,
} from './ListCard';

const SearchBarBox = styled.div`
  display: flex;
  flex-direction: row;
  position: sticky;
  justify-content: space-between;
  top: 0;
  border-radius: 6px;
  width: 100%;
  height: 48px;
  box-shadow: 0 0 2px black;
  padding: 6px;
  margin-bottom: 12px;
  line-height: 30px;
  font-size: 18px;
  background-color: white;
  opacity: 0.9;
  z-index: 10;
`;

const SearchTextBox = styled.input`
  flex-shrink: 1;
  margin-left: 12px;
  width: calc(100% - 12px);
  font-size: 18px;
  justify-self: flex-end;
`;

const CategoryBadge = styled.span<{ category: string }>`
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: bold;
  color: white;
  background-color: ${props => {
    switch (props.category) {
      case 'BUG_REPORT':
        return '#e74c3c';
      case 'SUGGESTION':
        return '#3498db';
      default:
        return '#95a5a6';
    }
  }};
`;

const FeedbackMeta = styled.div`
  color: gray;
  font-size: 14px;
  margin-bottom: 8px;
`;

const RatingIcon = styled.span`
  margin-left: 8px;
`;

export function Feedback() {
  const connection = useContext(ServerConnectionContext);
  const [feedbacks, setFeedbacks] = useState<FeedbackDto[]>([]);
  const [query, setQuery] = useState('');

  const sock = useMemo(
    () => (connection.connection ? new ServerApi(connection.connection) : null),
    [connection],
  );

  useEffect(() => {
    if (!sock) return;

    sock.onUpdateFeedbackData(data => {
      setFeedbacks(data.feedbacks);
    });

    sock.requestFeedbackData({});
  }, [sock]);

  const filtered = feedbacks.filter(
    f =>
      f.text.toLowerCase().includes(query.toLowerCase()) ||
      (f.username ?? '').toLowerCase().includes(query.toLowerCase()) ||
      f.category.toLowerCase().includes(query.toLowerCase()),
  );

  const categoryLabel = (cat: string) => {
    switch (cat) {
      case 'BUG_REPORT':
        return 'Bug Report';
      case 'SUGGESTION':
        return 'Suggestion';
      default:
        return 'General';
    }
  };

  return (
    <>
      <SearchBarBox>
        <SearchTextBox
          placeholder="Search feedback..."
          onChange={e => setQuery(e.target.value)}
        />
      </SearchBarBox>
      {filtered.length === 0 ? (
        <CenterText>No feedback found</CenterText>
      ) : (
        filtered.map(f => (
          <ListCardBox key={f.id}>
            <ListCardTitle>
              <CategoryBadge category={f.category}>
                {categoryLabel(f.category)}
              </CategoryBadge>
              {f.rating != null && (
                <RatingIcon>{f.rating > 0 ? '👍' : '👎'}</RatingIcon>
              )}
            </ListCardTitle>
            <ListCardBody>{f.text}</ListCardBody>
            <FeedbackMeta>
              {f.username ?? f.userId} &middot;{' '}
              {new Date(f.createdAt).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
              })}
              {f.challengeName && <> &middot; {f.challengeName}</>}
            </FeedbackMeta>
          </ListCardBox>
        ))
      )}
    </>
  );
}
