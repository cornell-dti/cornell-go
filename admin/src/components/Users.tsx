import { useContext, useEffect, useState } from "react";
import { UserDto } from "../all.dto";
import { ServerDataContext } from "./ServerData";
import GridTable from "@nadavshaar/react-grid-table";
import userEvent from "@testing-library/user-event";

const EDIT_SVG = (
  <svg
    height="16"
    viewBox="0 0 20 20"
    width="16"
    xmlns="http://www.w3.org/2000/svg"
  >
    <g fill="#fff" stroke="#1856bf" transform="translate(2 2)">
      <path
        d="m8.24920737-.79402796c1.17157287 0 2.12132033.94974747 2.12132033 2.12132034v13.43502882l-2.12132033 3.5355339-2.08147546-3.495689-.03442539-13.47488064c-.00298547-1.16857977.94191541-2.11832105 2.11049518-2.12130651.00180188-.00000461.00360378-.00000691.00540567-.00000691z"
        transform="matrix(.70710678 .70710678 -.70710678 .70710678 8.605553 -3.271644)"
      />
      <path d="m13.5 4.5 1 1" />
    </g>
  </svg>
);
const CANCEL_SVG = (
  <svg
    height="20"
    viewBox="0 0 20 20"
    width="20"
    xmlns="http://www.w3.org/2000/svg"
  >
    <g fill="none" stroke="#dc1e1e" transform="translate(5 5)">
      <path d="m.5 10.5 10-10" />
      <path d="m10.5 10.5-10-10z" />
    </g>
  </svg>
);
const SAVE_SVG = (
  <svg
    height="20"
    viewBox="0 0 20 20"
    width="20"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="m.5 5.5 3 3 8.028-8"
      fill="none"
      stroke="#4caf50"
      transform="translate(5 6)"
    />
  </svg>
);

const styles = {
  select: { margin: "0 20px" },
  buttonsCellContainer: {
    padding: "0 20px",
    width: "100%",
    height: "100%",
    display: "flex",
    justifyContent: "flex-end",
    alignItems: "center",
  },
  editButton: {
    background: "#f3f3f3",
    outline: "none",
    cursor: "pointer",
    padding: 4,
    display: "inline-flex",
    border: "none",
    borderRadius: "50%",
    boxShadow: "1px 1px 2px 0px rgb(0 0 0 / .3)",
  },
  buttonsCellEditorContainer: {
    height: "100%",
    width: "100%",
    display: "inline-flex",
    padding: "0 20px",
    justifyContent: "flex-end",
    alignItems: "center",
  },
  cancelButton: {
    background: "#f3f3f3",
    outline: "none",
    cursor: "pointer",
    marginRight: 10,
    padding: 2,
    display: "inline-flex",
    border: "none",
    borderRadius: "50%",
    boxShadow: "1px 1px 2px 0px rgb(0 0 0 / .3)",
  },
  saveButton: {
    background: "#f3f3f3",
    outline: "none",
    cursor: "pointer",
    padding: 2,
    display: "inline-flex",
    border: "none",
    borderRadius: "50%",
    boxShadow: "1px 1px 2px 0px rgb(0 0 0 / .3)",
  },
};

function toForm(user: any) {
  return {
    username: user.username,
    id: user.id,
    groupId: user.groupId,
    email: user.email,
    year: user.year,
    isBanned: user.isBanned,
    trackedEvents: user.trackedEvents,
    authType: user.authType,
    enrollmentType: user.enrollmentType,
  }
}

function getColumns(setRowsData: any, serverData: any) {
  return [
    {
      id: "checkbox",
      visible: true,
      pinned: true,
      width: "54px",
    },
    {
      id: 1,
      field: "username",
      label: "Username",
    },
    {
      id: 2,
      field: "id",
      label: "Id",
      editable: false,
    },
    {
      id: 3,
      field: "groupId",
      label: "GroupId",
      editable: false,
    },
    {
      id: 4,
      field: "authType",
      label: "Device Type",
      cellRenderer: ({ data }: { data: any }) => (
        <span>{data.authType ? data.authType : "-"}</span>
      )
    },
    {
      id: 5,
      field: "email",
      label: "Email",
    },
    {
      id: 6,
      field: "year",
      label: "Year",
      cellRenderer: ({ data }: { data: any }) => (
        <span>{data.year ? data.year : "-"}</span>
      ),
    },
    {
      id: 7,
      field: "enrollmentType",
      label: "Enrollment Type",
      cellRenderer: ({ data }: { data: any }) => (
        <span>{data.enrollmentType ? data.enrollmentType : "-"}</span>
      ),
    },
    {
      id: 7,
      field: "trackedEvents",
      label: "Tracked Events",
      cellRenderer: ({ data }: { data: any }) => (
        <span>{data.trackedEvents ? data.trackedEvents.join(", ") : "-"}</span>
      ),
    },
    {id: 8,
      field: "isBanned",
      label: "Status",
      cellRenderer: ({ data }: { data: any }) => (
        <span>{data.isBanned ? "Banned" : "Active"}</span>
      ),
    },
    {
      id: "buttons",
      width: "max-content",
      pinned: true,
      sortable: false,
      resizable: false,
      cellRenderer: ({
        tableManager,
        data,
      }: {
        tableManager: any;
        data: any;
      }) => (
        <div style={styles.buttonsCellContainer}>
          <button
            title="Edit"
            style={styles.editButton}
            onClick={(e) => {
              e.stopPropagation();
              tableManager.rowEditApi.setEditRowId(data.id);
            }}
          >
            {EDIT_SVG}
          </button>
        </div>
      ),
      editorCellRenderer: ({
        tableManager,
        data,
      }: {
        tableManager: any;
        data: any;
      }) => (
        <div style={styles.buttonsCellEditorContainer}>
          <button
            title="Cancel"
            style={styles.cancelButton}
            onClick={(e) => {
              e.stopPropagation();
              tableManager.rowEditApi.setEditRowId(null);
            }}
          >
            {CANCEL_SVG}
          </button>
          <button
            title="Save"
            style={styles.saveButton}
            onClick={(e) => {
              e.stopPropagation();

              let rowsClone = [...tableManager.rowsApi.rows];
              let updatedRowIndex = rowsClone.findIndex(
                (r) => r.id === data.id
              );
              rowsClone[updatedRowIndex] = data;

              setRowsData(rowsClone);

              serverData.users.set(data.id, data as UserDto);
              serverData.updateUser(rowsClone[updatedRowIndex]);
              tableManager.rowEditApi.setEditRowId(null);
            }}
          >
            {SAVE_SVG}
          </button>
        </div>
      ),
    },
  ];
}

/**
 * `Users` - A component that displays a list of users in a table format.
 *
 * @remarks
 * This component retrieves user data from the `ServerDataContext` and maps it to 
 * a format suitable for display in a table. It uses the `GridTable` component to 
 * render the data in rows and columns, with dynamic updates based on changes 
 * in the data. The `getColumns` function is used to define the table columns, 
 * while `setRowsData` is used to update the rows when necessary.
 *
 * @param serverData - The context that contains the user data to be displayed in the table.
 * @param rowsData - The state that holds the formatted user data for rendering in the table.
 * 
 * @returns A `GridTable` component displaying the user data in a structured table format.
 */
export function Users() {
  const serverData = useContext(ServerDataContext);
  const [rowsData, setRowsData] = useState(
    Array.from(serverData.users.values()).map((us) => toForm(us))
  );

  return (
    <GridTable columns={getColumns(setRowsData, serverData)} rows={rowsData} />
  );
}
