import { useContext, useEffect, useState } from 'react';
import styled from 'styled-components';
import { ServerConnectionContext } from './ServerConnection';

const PageContainer = styled.div`
  max-width: 800px;
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
  margin-bottom: 16px;
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
  min-height: 80px;
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

const Button = styled.button<{ disabled?: boolean; variant?: string }>`
  background-color: ${props =>
    props.disabled
      ? '#ccc'
      : props.variant === 'danger'
        ? '#d32f2f'
        : props.variant === 'secondary'
          ? '#666'
          : '#b31b1b'};
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 500;
  cursor: ${props => (props.disabled ? 'not-allowed' : 'pointer')};
  margin-right: 8px;
  transition: background-color 0.2s;

  &:hover {
    opacity: ${props => (props.disabled ? 1 : 0.85)};
  }
`;

const Table = styled.table`
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 24px;
`;

const Th = styled.th`
  text-align: left;
  padding: 10px 12px;
  border-bottom: 2px solid #ddd;
  color: #333;
  font-size: 14px;
`;

const Td = styled.td`
  padding: 10px 12px;
  border-bottom: 1px solid #eee;
  font-size: 14px;
`;

const StatusBadge = styled.span<{ active: boolean }>`
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  background-color: ${props => (props.active ? '#e8f5e9' : '#ffebee')};
  color: ${props => (props.active ? '#2e7d32' : '#c62828')};
`;

const Row = styled.div`
  display: flex;
  gap: 16px;
`;

const HalfWidth = styled.div`
  flex: 1;
`;

const InfoBox = styled.div`
  margin-top: 16px;
  padding: 12px 16px;
  border-radius: 4px;
  background-color: #e3f2fd;
  color: #1565c0;
  border: 1px solid #90caf9;
  font-size: 14px;
`;

interface SpotlightData {
  id: string;
  title: string;
  body: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  cooldownDays: number;
  startDate: string;
  endDate: string;
  startHour: number;
  endHour: number;
  isActive: boolean;
  linkedEventId?: string;
  linkedCampusEventId?: string;
}

const emptySpotlight: Omit<SpotlightData, 'id'> = {
  title: '',
  body: '',
  latitude: 42.4534,
  longitude: -76.4735,
  radiusMeters: 200,
  cooldownDays: 7,
  startDate: new Date().toISOString().split('T')[0],
  endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    .toISOString()
    .split('T')[0],
  startHour: 9,
  endHour: 21,
  isActive: true,
};

export function Spotlights() {
  const connection = useContext(ServerConnectionContext);
  const [spotlights, setSpotlights] = useState<SpotlightData[]>([]);
  const [editing, setEditing] = useState<SpotlightData | null>(null);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState<Omit<SpotlightData, 'id'>>(emptySpotlight);
  const [saving, setSaving] = useState(false);

  const loadSpotlights = async () => {
    try {
      const result = await connection.connection
        ?.timeout(10000)
        .emitWithAck('getAllSpotlights');
      if (result) {
        setSpotlights(result as SpotlightData[]);
      }
    } catch (err) {
      console.error('Failed to load spotlights:', err);
    }
  };

  useEffect(() => {
    loadSpotlights();
  }, [connection.connection]);

  const handleSave = async () => {
    if (!form.title.trim() || !form.body.trim()) return;
    setSaving(true);

    try {
      const payload = {
        ...form,
        startDate: new Date(form.startDate).toISOString(),
        endDate: new Date(form.endDate).toISOString(),
      };

      if (editing) {
        await connection.connection
          ?.timeout(10000)
          .emitWithAck('updateSpotlight', { ...payload, id: editing.id });
      } else {
        await connection.connection
          ?.timeout(10000)
          .emitWithAck('createSpotlight', payload);
      }

      setEditing(null);
      setCreating(false);
      setForm(emptySpotlight);
      await loadSpotlights();
    } catch (err) {
      console.error('Failed to save spotlight:', err);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this spotlight?')) return;
    try {
      await connection.connection
        ?.timeout(10000)
        .emitWithAck('deleteSpotlight', { id });
      await loadSpotlights();
    } catch (err) {
      console.error('Failed to delete spotlight:', err);
    }
  };

  const startEdit = (s: SpotlightData) => {
    setEditing(s);
    setCreating(false);
    setForm({
      title: s.title,
      body: s.body,
      latitude: s.latitude,
      longitude: s.longitude,
      radiusMeters: s.radiusMeters,
      cooldownDays: s.cooldownDays,
      startDate: s.startDate.split('T')[0],
      endDate: s.endDate.split('T')[0],
      startHour: s.startHour,
      endHour: s.endHour,
      isActive: s.isActive,
      linkedEventId: s.linkedEventId,
      linkedCampusEventId: s.linkedCampusEventId,
    });
  };

  const startCreate = () => {
    setEditing(null);
    setCreating(true);
    setForm(emptySpotlight);
  };

  const cancel = () => {
    setEditing(null);
    setCreating(false);
    setForm(emptySpotlight);
  };

  const isFormOpen = editing || creating;

  const getStatus = (s: SpotlightData) => {
    if (!s.isActive) return false;
    const now = new Date();
    return new Date(s.startDate) <= now && new Date(s.endDate) >= now;
  };

  const hourOptions = Array.from({ length: 24 }, (_, i) => ({
    value: i,
    label: `${i === 0 ? '12' : i > 12 ? i - 12 : i}:00 ${i < 12 ? 'AM' : 'PM'}`,
  }));

  return (
    <PageContainer>
      <Title>Location Spotlights</Title>
      <Subtitle>
        Configure location-based notification zones. Users near these locations
        will receive a push notification (with smart anti-spam controls).
      </Subtitle>

      {!isFormOpen && (
        <>
          <Button onClick={startCreate}>Create Spotlight</Button>

          <Table>
            <thead>
              <tr>
                <Th>Title</Th>
                <Th>Status</Th>
                <Th>Radius</Th>
                <Th>Cooldown</Th>
                <Th>Date Range</Th>
                <Th>Actions</Th>
              </tr>
            </thead>
            <tbody>
              {spotlights.map(s => (
                <tr key={s.id}>
                  <Td>{s.title}</Td>
                  <Td>
                    <StatusBadge active={getStatus(s)}>
                      {getStatus(s) ? 'Active' : 'Inactive'}
                    </StatusBadge>
                  </Td>
                  <Td>{s.radiusMeters}m</Td>
                  <Td>{s.cooldownDays} days</Td>
                  <Td>
                    {new Date(s.startDate).toLocaleDateString()} –{' '}
                    {new Date(s.endDate).toLocaleDateString()}
                  </Td>
                  <Td>
                    <Button variant="secondary" onClick={() => startEdit(s)}>
                      Edit
                    </Button>
                    <Button variant="danger" onClick={() => handleDelete(s.id)}>
                      Delete
                    </Button>
                  </Td>
                </tr>
              ))}
              {spotlights.length === 0 && (
                <tr>
                  <Td
                    colSpan={6}
                    style={{ textAlign: 'center', color: '#999' }}
                  >
                    No spotlights configured yet.
                  </Td>
                </tr>
              )}
            </tbody>
          </Table>
        </>
      )}

      {isFormOpen && (
        <>
          <h3>{editing ? 'Edit Spotlight' : 'Create Spotlight'}</h3>

          <FormGroup>
            <Label>Title (shown in notification)</Label>
            <Input
              type="text"
              value={form.title}
              onChange={e => setForm({ ...form, title: e.target.value })}
              placeholder="e.g., Challenge nearby!"
              maxLength={100}
            />
          </FormGroup>

          <FormGroup>
            <Label>Message (notification body)</Label>
            <TextArea
              value={form.body}
              onChange={e => setForm({ ...form, body: e.target.value })}
              placeholder="e.g., You're near the Arts Quad challenge — come complete it!"
              maxLength={500}
            />
          </FormGroup>

          <Row>
            <HalfWidth>
              <FormGroup>
                <Label>Latitude</Label>
                <Input
                  type="number"
                  step="0.0001"
                  value={form.latitude}
                  onChange={e =>
                    setForm({
                      ...form,
                      latitude: parseFloat(e.target.value) || 0,
                    })
                  }
                />
              </FormGroup>
            </HalfWidth>
            <HalfWidth>
              <FormGroup>
                <Label>Longitude</Label>
                <Input
                  type="number"
                  step="0.0001"
                  value={form.longitude}
                  onChange={e =>
                    setForm({
                      ...form,
                      longitude: parseFloat(e.target.value) || 0,
                    })
                  }
                />
              </FormGroup>
            </HalfWidth>
          </Row>

          <Row>
            <HalfWidth>
              <FormGroup>
                <Label>Trigger Radius (meters)</Label>
                <Input
                  type="number"
                  value={form.radiusMeters}
                  onChange={e =>
                    setForm({
                      ...form,
                      radiusMeters: parseInt(e.target.value) || 0,
                    })
                  }
                />
              </FormGroup>
            </HalfWidth>
            <HalfWidth>
              <FormGroup>
                <Label>Cooldown (days per user)</Label>
                <Input
                  type="number"
                  value={form.cooldownDays}
                  onChange={e =>
                    setForm({
                      ...form,
                      cooldownDays: parseInt(e.target.value) || 1,
                    })
                  }
                />
              </FormGroup>
            </HalfWidth>
          </Row>

          <Row>
            <HalfWidth>
              <FormGroup>
                <Label>Start Date</Label>
                <Input
                  type="date"
                  value={form.startDate}
                  onChange={e =>
                    setForm({ ...form, startDate: e.target.value })
                  }
                />
              </FormGroup>
            </HalfWidth>
            <HalfWidth>
              <FormGroup>
                <Label>End Date</Label>
                <Input
                  type="date"
                  value={form.endDate}
                  onChange={e => setForm({ ...form, endDate: e.target.value })}
                />
              </FormGroup>
            </HalfWidth>
          </Row>

          <Row>
            <HalfWidth>
              <FormGroup>
                <Label>Notification Start Hour</Label>
                <Select
                  value={form.startHour}
                  onChange={e =>
                    setForm({
                      ...form,
                      startHour: parseInt(e.target.value),
                    })
                  }
                >
                  {hourOptions.map(h => (
                    <option key={h.value} value={h.value}>
                      {h.label}
                    </option>
                  ))}
                </Select>
              </FormGroup>
            </HalfWidth>
            <HalfWidth>
              <FormGroup>
                <Label>Notification End Hour</Label>
                <Select
                  value={form.endHour}
                  onChange={e =>
                    setForm({
                      ...form,
                      endHour: parseInt(e.target.value),
                    })
                  }
                >
                  {hourOptions.map(h => (
                    <option key={h.value} value={h.value}>
                      {h.label}
                    </option>
                  ))}
                </Select>
              </FormGroup>
            </HalfWidth>
          </Row>

          <FormGroup>
            <Label>
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={e => setForm({ ...form, isActive: e.target.checked })}
                style={{ marginRight: 8 }}
              />
              Active
            </Label>
          </FormGroup>

          <div>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : editing ? 'Update' : 'Create'}
            </Button>
            <Button variant="secondary" onClick={cancel}>
              Cancel
            </Button>
          </div>

          <InfoBox>
            <strong>Anti-spam rules:</strong> Users receive max 1 location
            notification per day. Each spotlight has its own per-user cooldown
            (default 7 days). Notifications only sent during the configured
            hours (Eastern Time). Users who already completed a linked
            challenge/event won't be notified.
          </InfoBox>
        </>
      )}
    </PageContainer>
  );
}
