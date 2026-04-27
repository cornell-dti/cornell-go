
/**
 * Campus Events page on the admin dashboard
 *
 * Gets campus events from `ServerDataContext` using`requestCampusEvents` → `campusEventList`, 
 * plus `campusEvents` map and `updateCampusEventData` broadcasts).
 *
 * Allows admins to create/edit campus-event fields with location, title, description, 
 * approval status, and other fields. 
 * If an event is REJECTED, a rejection reason is required.
 */
import { useContext, useEffect, useMemo, useState } from 'react';
import { compareTwoStrings } from 'string-similarity';
import styled from 'styled-components';
import {
  CampusEventCheckInMethodDto,
  CampusEventDto,
  UpsertCampusEventCategoriesDto,
  UpsertCampusEventCheckInMethodDto,
  UpsertCampusEventDto,
  UpsertCampusEventSourceDto,
} from '../all.dto';
import { AlertModal } from './AlertModal';
import { DeleteModal } from './DeleteModal';
import {
  DateEntryForm,
  EntryForm,
  EntryModal,
  FreeEntryForm,
  MapEntryForm,
  NumberEntryForm,
  OptionEntryForm,
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

const ActionRow = styled.div`
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-bottom: 12px;
`;

const PageIndicator = styled.div`
  align-self: center;
  font-weight: bold;
`;

const categories = [
  'SOCIAL',
  'CULTURAL',
  'ATHLETIC',
  'WELLNESS',
  'ACADEMIC',
  'ARTS',
  'CAREER',
  'COMMUNITY',
  'OTHER',
] as const;

const approvalStatuses = ['APPROVED', 'REJECTED', 'ARCHIVED'] as const;

function parseCsv(value: string) {
  return value
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
}

function makeCampusEventForm(): EntryForm[] {
  const start = new Date(Date.now() + 60 * 60 * 1000);
  const end = new Date(Date.now() + 2 * 60 * 60 * 1000);
  return [
    { name: 'Title', characterLimit: 256, value: '' },
    {
      name: 'Description',
      characterLimit: 4096,
      value: '',
      multiline: true,
    },
    {
      name: 'Image URL',
      characterLimit: 2048,
      value: '',
      helpText: 'Optional. Leave blank for no image.',
    },
    { name: 'Start Time', date: start },
    { name: 'End Time', date: end },
    { name: 'All-day', options: ['No', 'Yes'], value: 0 },
    { name: 'Location Name', characterLimit: 256, value: '' },
    {
      name: 'Address',
      characterLimit: 512,
      value: '',
      helpText: 'Optional. Can be blank if location name is sufficient.',
    },
    {
      name: 'Map Location',
      latitude: 42.4534,
      longitude: -76.4735,
      awardingRadiusF: 100,
    },
    { name: 'Check-in Radius (meters)', min: 1, max: 5000, value: 100 },
    {
      name: 'Categories (comma-separated)',
      characterLimit: 512,
      value: 'OTHER',
      helpText: `Required. Options: ${categories.join(', ')}`,
    },
    {
      name: 'Tags (comma-separated)',
      characterLimit: 512,
      value: '',
      helpText: 'Optional.',
    },
    {
      name: 'Organizer Name',
      characterLimit: 256,
      value: '',
      helpText: 'Optional.',
    },
    {
      name: 'Organizer Email',
      characterLimit: 256,
      value: '',
      helpText: 'Optional.',
    },
    {
      name: 'Check-in Method',
      options: ['LOCATION', 'QR_CODE', 'EITHER'],
      value: 2,
    },
    { name: 'Points for Attendance', min: 0, max: 1000, value: 10 },
    { name: 'Featured', options: ['No', 'Yes'], value: 0 },
    {
      name: 'Registration URL',
      characterLimit: 2048,
      value: '',
      helpText: 'Optional.',
    },
    {
      name: 'Approval Status',
      options: [...approvalStatuses],
      value: 0,
    },
    {
      name: 'Rejection Reason',
      characterLimit: 1024,
      value: '',
      multiline: true,
      hidden: true,
      helpText: 'Required when Approval Status is REJECTED.',
    },
  ];
}

function validateCampusEventForm(form: EntryForm[]): string | null {
  const approvalForm = form[18] as OptionEntryForm;
  const status = approvalForm.options[approvalForm.value];
  if (status !== 'REJECTED') return null;
  const reason = ((form[19] as FreeEntryForm).value ?? '').trim();
  if (!reason) {
    return 'Enter a rejection reason when Approval Status is REJECTED.';
  }
  return null;
}

function eventToForm(ev: CampusEventDto): EntryForm[] {
  const base = makeCampusEventForm();
  const categoryValue = (ev.categories ?? []).join(',') || 'OTHER';
  const tagsValue = (ev.tags ?? []).join(',');
  const approvalIndex = approvalStatuses.indexOf(
    (ev.approvalStatus as (typeof approvalStatuses)[number]) ?? 'APPROVED',
  );

  (base[0] as FreeEntryForm).value = ev.title ?? '';
  (base[1] as FreeEntryForm).value = ev.description ?? '';
  (base[2] as FreeEntryForm).value = ev.imageUrl ?? '';
  (base[3] as DateEntryForm).date = new Date(ev.startTime);
  (base[4] as DateEntryForm).date = new Date(ev.endTime);
  (base[5] as OptionEntryForm).value = ev.allDay ? 1 : 0;
  (base[6] as FreeEntryForm).value = ev.locationName ?? '';
  (base[7] as FreeEntryForm).value = ev.address ?? '';
  (base[8] as MapEntryForm).latitude = ev.latitude ?? 0;
  (base[8] as MapEntryForm).longitude = ev.longitude ?? 0;
  (base[8] as MapEntryForm).awardingRadiusF = ev.checkInRadius ?? 100;
  (base[9] as NumberEntryForm).value = ev.checkInRadius ?? 100;
  (base[10] as FreeEntryForm).value = categoryValue;
  (base[11] as FreeEntryForm).value = tagsValue;
  (base[12] as FreeEntryForm).value = ev.organizerName ?? '';
  (base[13] as FreeEntryForm).value = ev.organizerEmail ?? '';
  (base[14] as OptionEntryForm).value =
    ev.checkInMethod === CampusEventCheckInMethodDto.LOCATION
      ? 0
      : ev.checkInMethod === CampusEventCheckInMethodDto.QR_CODE
        ? 1
        : 2;
  (base[15] as NumberEntryForm).value = ev.pointsForAttendance ?? 10;
  (base[16] as OptionEntryForm).value = ev.featured ? 1 : 0;
  (base[17] as FreeEntryForm).value = ev.registrationUrl ?? '';
  (base[18] as OptionEntryForm).value = Math.max(0, approvalIndex);
  (base[19] as FreeEntryForm).value = ev.rejectionReason ?? '';
  (base[19] as FreeEntryForm).hidden = ev.approvalStatus !== 'REJECTED';

  return base;
}

function formToUpsert(form: EntryForm[], id?: string): UpsertCampusEventDto {
  const title = (form[0] as FreeEntryForm).value.trim();
  const description = (form[1] as FreeEntryForm).value.trim();
  const imageUrl = (form[2] as FreeEntryForm).value.trim();
  const startTime = (form[3] as DateEntryForm).date.toISOString();
  const endTime = (form[4] as DateEntryForm).date.toISOString();
  const allDay = (form[5] as OptionEntryForm).value === 1;
  const locationName = (form[6] as FreeEntryForm).value.trim();
  const address = (form[7] as FreeEntryForm).value.trim();
  const map = form[8] as MapEntryForm;
  const checkInRadius = (form[9] as NumberEntryForm).value;
  const categoriesInput = (form[10] as FreeEntryForm).value;
  const tagsInput = (form[11] as FreeEntryForm).value;
  const organizerName = (form[12] as FreeEntryForm).value.trim();
  const organizerEmail = (form[13] as FreeEntryForm).value.trim();
  const checkInMethod = (form[14] as OptionEntryForm).options[
    (form[14] as OptionEntryForm).value
  ] as UpsertCampusEventCheckInMethodDto;
  const pointsForAttendance = (form[15] as NumberEntryForm).value;
  const featured = (form[16] as OptionEntryForm).value === 1;
  const registrationUrl = (form[17] as FreeEntryForm).value.trim();
  const approvalStatus = (form[18] as OptionEntryForm).options[
    (form[18] as OptionEntryForm).value
  ] as UpsertCampusEventDto['approvalStatus'];
  const rejectionReason = (form[19] as FreeEntryForm).value.trim();

  const parsedCategories = parseCsv(categoriesInput)
    .map(c => c.toUpperCase())
    .filter(c => (categories as readonly string[]).includes(c))
    .map(c => c as UpsertCampusEventCategoriesDto);

  return {
    id,
    title,
    description,
    imageUrl: imageUrl || undefined,
    startTime,
    endTime,
    allDay,
    locationName,
    address: address || undefined,
    latitude: map.latitude,
    longitude: map.longitude,
    checkInRadius,
    categories: (parsedCategories.length ? parsedCategories : ['OTHER']).map(
      v => v as UpsertCampusEventCategoriesDto,
    ),
    tags: parseCsv(tagsInput),
    source: UpsertCampusEventSourceDto.ADMIN_CREATED,
    externalUrl: undefined,
    organizerName: organizerName || undefined,
    organizerEmail: organizerEmail || undefined,
    checkInMethod,
    pointsForAttendance,
    featured,
    registrationUrl: registrationUrl || undefined,
    approvalStatus,
    rejectionReason:
      approvalStatus === 'REJECTED' ? rejectionReason : undefined,
  };
}

function CampusEventCard(props: {
  event: CampusEventDto;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const start = new Date(props.event.startTime).toLocaleString();
  const end = new Date(props.event.endTime).toLocaleString();

  return (
    <ListCardBox>
      <ListCardTitle>{props.event.title}</ListCardTitle>
      <ListCardDescription>{props.event.description}</ListCardDescription>
      <ListCardBody>
        Status: <b>{props.event.approvalStatus}</b>
        {props.event.approvalStatus === 'REJECTED' &&
          props.event.rejectionReason && (
            <>
              <br />
              Rejection Reason: <b>{props.event.rejectionReason}</b>
            </>
          )}
        <br />
        When: <b>{start}</b> → <b>{end}</b>
        <br />
        All-day: <b>{props.event.allDay ? 'Yes' : 'No'}</b>
        <br />
        Where: <b>{props.event.locationName}</b>
        {props.event.address ? (
          <>
            <br />
            Address: <b>{props.event.address}</b>
          </>
        ) : null}
        <br />
        Coordinates: <b>{props.event.latitude}</b>,{' '}
        <b>{props.event.longitude}</b>
        <br />
        Check-in Radius: <b>{props.event.checkInRadius}m</b>
        <br />
        Check-in Method: <b>{props.event.checkInMethod}</b>
        <br />
        Categories: <b>{(props.event.categories ?? []).join(', ')}</b>
        <br />
        Tags: <b>{(props.event.tags ?? []).join(', ') || 'None'}</b>
        <br />
        Points: <b>{props.event.pointsForAttendance}</b>
        <br />
        Featured: <b>{props.event.featured ? 'Yes' : 'No'}</b>
        <br />
        RSVP: <b>{props.event.rsvpCount}</b> • Attendance:{' '}
        <b>{props.event.attendanceCount}</b>
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

export function CampusEvents() {
  const serverData = useContext(ServerDataContext);

  const [createOpen, setCreateOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const [currentId, setCurrentId] = useState('');
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const [form, setForm] = useState<EntryForm[]>(() => makeCampusEventForm());
  const [alertOpen, setAlertOpen] = useState(false);
  const [alertMessage, setAlertMessage] = useState('');

  const handleRadiusChange = (radius: number) => {
    setForm(prev => {
      const next = [...prev];
      (next[9] as NumberEntryForm).value = radius;
      next[8] = {
        ...(next[8] as MapEntryForm),
        awardingRadiusF: radius,
      };
      return next;
    });
  };

  const handleApprovalStatusChange = (status: string) => {
    setForm(prev => {
      const next = [...prev];
      (next[19] as FreeEntryForm).hidden = status !== 'REJECTED';
      return next;
    });
  };

  const currentList = serverData.campusEventList;
  const totalPages = currentList?.totalPages ?? 1;

  useEffect(() => {
    serverData.requestCampusEvents({
      page,
      limit: 50,
      search: query || undefined,
    });
  }, [page, query]);

  const visibleEvents = useMemo(() => {
    const fromList = serverData.campusEventList?.events ?? [];
    const base =
      fromList.length > 0
        ? fromList
        : Array.from(serverData.campusEvents.values());
    const filtered = base.filter(ev => {
      if (!query.trim()) return true;
      const q = query.toLowerCase();
      return (
        (ev.title ?? '').toLowerCase().includes(q) ||
        (ev.description ?? '').toLowerCase().includes(q) ||
        (ev.locationName ?? '').toLowerCase().includes(q)
      );
    });

    return filtered.sort(
      (a, b) =>
        compareTwoStrings(b.title ?? '', query) -
          compareTwoStrings(a.title ?? '', query) +
          compareTwoStrings(b.description ?? '', query) -
          compareTwoStrings(a.description ?? '', query) +
          compareTwoStrings(b.locationName ?? '', query) -
          compareTwoStrings(a.locationName ?? '', query) || 0,
    );
  }, [serverData.campusEventList, serverData.campusEvents, query]);

  return (
    <>
      <AlertModal
        description={alertMessage}
        isOpen={alertOpen}
        onClose={() => setAlertOpen(false)}
      />
      <EntryModal
        title="Create Campus Event"
        isOpen={createOpen}
        entryButtonText="CREATE"
        onEntry={async () => {
          const err = validateCampusEventForm(form);
          if (err) {
            setAlertMessage(err);
            setAlertOpen(true);
            return;
          }
          const dto = formToUpsert(form);
          await serverData.createCampusEvent(dto);
          setCreateOpen(false);
        }}
        onCancel={() => setCreateOpen(false)}
        form={form}
        onRadiusChange={(awardingRadius: number) =>
          handleRadiusChange(awardingRadius)
        }
      />
      <EntryModal
        title="Edit Campus Event"
        isOpen={editOpen}
        entryButtonText="SAVE"
        onEntry={async () => {
          const err = validateCampusEventForm(form);
          if (err) {
            setAlertMessage(err);
            setAlertOpen(true);
            return;
          }
          const dto = formToUpsert(form, currentId);
          await serverData.updateCampusEvent(dto);
          setEditOpen(false);
        }}
        onCancel={() => setEditOpen(false)}
        form={form}
        onRadiusChange={(awardingRadius: number) =>
          handleRadiusChange(awardingRadius)
        }
      />
      <DeleteModal
        objectName={
          serverData.campusEvents.get(currentId)?.title ?? 'this event'
        }
        isOpen={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        onDelete={async () => {
          await serverData.deleteCampusEvent(currentId);
          setDeleteOpen(false);
        }}
      />

      <SearchBar
        onCreate={() => {
          const f = makeCampusEventForm();
          (f[19] as FreeEntryForm).hidden = true;
          (f[9] as NumberEntryForm).onChange = v => handleRadiusChange(v);
          (f[18] as OptionEntryForm).onChange = idx =>
            handleApprovalStatusChange(
              (f[18] as OptionEntryForm).options[idx] ?? 'APPROVED',
            );
          setForm(f);
          setCreateOpen(true);
        }}
        onSearch={q => {
          setPage(1);
          setQuery(q);
        }}
      />

      <ActionRow>
        <HButton
          onClick={() => setPage(p => Math.max(1, p - 1))}
          disabled={page <= 1}
        >
          Prev
        </HButton>
        <PageIndicator>
          Page {page} / {totalPages}
        </PageIndicator>
        <HButton
          onClick={() => setPage(p => Math.min(totalPages, p + 1))}
          disabled={page >= totalPages}
        >
          Next
        </HButton>
      </ActionRow>

      {visibleEvents.length === 0 ? (
        <CenterText>No campus events found</CenterText>
      ) : null}

      {visibleEvents.map(ev => (
        <CampusEventCard
          key={ev.id}
          event={ev}
          onEdit={() => {
            const fresh = serverData.campusEvents.get(ev.id);
            if (!fresh) return;
            setCurrentId(ev.id);
            const f = eventToForm(fresh);
            (f[9] as NumberEntryForm).onChange = v => handleRadiusChange(v);
            (f[18] as OptionEntryForm).onChange = idx =>
              handleApprovalStatusChange(
                (f[18] as OptionEntryForm).options[idx] ?? 'APPROVED',
              );
            handleApprovalStatusChange(
              (f[18] as OptionEntryForm).options[
                (f[18] as OptionEntryForm).value
              ] ?? 'APPROVED',
            );
            setForm(f);
            setEditOpen(true);
          }}
          onDelete={() => {
            setCurrentId(ev.id);
            setDeleteOpen(true);
          }}
        />
      ))}
    </>
  );
}
