import { useContext, useState } from 'react';
import styled from 'styled-components';
import { ServerConnectionContext } from './ServerConnection';
import { ServerDataContext } from './ServerData';

const PageContainer = styled.div`
  max-width: 600px;
`;

const Title = styled.h2`
  margin-bottom: 8px;
  color: #333;
`;

const Subtitle = styled.p`
  color: #666;
  margin-bottom: 24px;
`;

const FormGroup = styled.div`
  margin-bottom: 20px;
`;

const Label = styled.label`
  display: block;
  font-weight: 500;
  margin-bottom: 6px;
  color: #333;
`;

const Input = styled.input`
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  box-sizing: border-box;

  &:focus {
    outline: none;
    border-color: #b31b1b;
  }
`;

const TextArea = styled.textarea`
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  min-height: 100px;
  resize: vertical;
  box-sizing: border-box;
  font-family: inherit;

  &:focus {
    outline: none;
    border-color: #b31b1b;
  }
`;

const Select = styled.select`
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  background: white;
  box-sizing: border-box;

  &:focus {
    outline: none;
    border-color: #b31b1b;
  }
`;

const Button = styled.button<{ disabled?: boolean }>`
  background-color: ${props => (props.disabled ? '#ccc' : '#b31b1b')};
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 500;
  cursor: ${props => (props.disabled ? 'not-allowed' : 'pointer')};
  transition: background-color 0.2s;

  &:hover {
    background-color: ${props => (props.disabled ? '#ccc' : '#8b1515')};
  }
`;

const ResultBox = styled.div<{ success: boolean }>`
  margin-top: 20px;
  padding: 12px 16px;
  border-radius: 4px;
  background-color: ${props => (props.success ? '#e8f5e9' : '#ffebee')};
  color: ${props => (props.success ? '#2e7d32' : '#c62828')};
  border: 1px solid ${props => (props.success ? '#a5d6a7' : '#ef9a9a')};
`;

const InfoBox = styled.div`
  margin-top: 20px;
  padding: 12px 16px;
  border-radius: 4px;
  background-color: #e3f2fd;
  color: #1565c0;
  border: 1px solid #90caf9;
  font-size: 14px;
`;

interface NotificationResult {
  successCount: number;
  failureCount: number;
  errors?: string[];
}

export function Notifications() {
  const connection = useContext(ServerConnectionContext);
  const serverData = useContext(ServerDataContext);

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [target, setTarget] = useState('all');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<NotificationResult | null>(null);

  const organizations = Array.from(serverData.organizations.values());

  const handleSend = async () => {
    if (!title.trim() || !body.trim()) {
      return;
    }

    setSending(true);
    setResult(null);

    try {
      const payload: {
        title: string;
        body: string;
        organizationId?: string;
      } = {
        title: title.trim(),
        body: body.trim(),
      };

      // If targeting a specific organization
      if (target !== 'all') {
        payload.organizationId = target;
      }

      const response = await connection.connection
        ?.timeout(10000)
        .emitWithAck('sendNotification', payload);

      if (response) {
        setResult(response as NotificationResult);
        if (response.successCount > 0) {
          // Clear form on success
          setTitle('');
          setBody('');
        }
      } else {
        setResult({
          successCount: 0,
          failureCount: 0,
          errors: ['No response from server'],
        });
      }
    } catch (error) {
      setResult({
        successCount: 0,
        failureCount: 0,
        errors: [error instanceof Error ? error.message : 'Unknown error'],
      });
    } finally {
      setSending(false);
    }
  };

  const canSend = title.trim() && body.trim() && !sending;

  return (
    <PageContainer>
      <Title>Send Push Notification</Title>
      <Subtitle>
        Send a notification to users' devices. This will appear in their
        notification panel.
      </Subtitle>

      <FormGroup>
        <Label>Target Audience</Label>
        <Select value={target} onChange={e => setTarget(e.target.value)}>
          <option value="all">All Users</option>
          {organizations.map(org => (
            <option key={org.id} value={org.id}>
              {org.name}
            </option>
          ))}
        </Select>
      </FormGroup>

      <FormGroup>
        <Label>Notification Title</Label>
        <Input
          type="text"
          value={title}
          onChange={e => setTitle(e.target.value)}
          placeholder="e.g., New Event Available!"
          maxLength={100}
        />
      </FormGroup>

      <FormGroup>
        <Label>Notification Message</Label>
        <TextArea
          value={body}
          onChange={e => setBody(e.target.value)}
          placeholder="e.g., Check out the new campus scavenger hunt starting this weekend!"
          maxLength={500}
        />
      </FormGroup>

      <Button onClick={handleSend} disabled={!canSend}>
        {sending ? 'Sending...' : 'Send Notification'}
      </Button>

      {result && (
        <ResultBox success={result.successCount > 0 && !result.errors?.length}>
          {result.successCount > 0 ? (
            <>
              Successfully sent to <strong>{result.successCount}</strong>{' '}
              {result.successCount === 1 ? 'user' : 'users'}
              {result.failureCount > 0 && <> ({result.failureCount} failed)</>}
            </>
          ) : (
            <>
              Failed to send notification
              {result.errors?.map((err, i) => (
                <div key={i}>{err}</div>
              ))}
            </>
          )}
        </ResultBox>
      )}

      <InfoBox>
        <strong>Note:</strong> Only users who have enabled notifications and
        have opened the app recently will receive this notification.
      </InfoBox>
    </PageContainer>
  );
}
