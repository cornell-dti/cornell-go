import { useContext, useEffect, useState } from "react";
import { ServerDataContext } from "./ServerData";
import GridTable from "@nadavshaar/react-grid-table";
import userEvent from "@testing-library/user-event";
import { DeleteModal } from "./DeleteModal";

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

function toForm(group: any) {
  return {
    id: group.id,
    friendlyId: group.friendlyId,
    hostId: group.hostId,
    curEventId: group.curEventId,
  };
}

function getColumns(setRowsData: any, serverData: any) {
  let deleteId: any;
  return [
    {
      id: "checkbox",
      visible: true,
      pinned: true,
      width: "54px",
    },
    {
      id: 1,
      field: "id",
      label: "Id",
      editable: false,
    },
    {
      id: 2,
      field: "friendlyId",
      label: "FriendlyId",
      editable: false,
    },
    {
      id: 3,
      field: "hostId",
      label: "HostId",
      editable: false,
    },
    {
      id: 4,
      field: "curEventId",
      label: "CurrentEventId",
      editable: false,
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
              deleteId = data.id;
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
        <div>
          <DeleteModal
            objectName={serverData.groups.get(deleteId)?.name ?? ""}
            isOpen={tableManager.rowEditApi.editRowId !== null}
            onClose={() => {
              tableManager.rowEditApi.setEditRowId(null);
            }}
            onDelete={() => {
              serverData.deleteGroup(deleteId);

              let rowsClone = [...tableManager.rowsApi.rows];
              let deletedRowIndex = rowsClone.findIndex(
                (r) => r.id === data.id
              );
              rowsClone.splice(deletedRowIndex, 1);

              setRowsData(rowsClone);

              tableManager.rowEditApi.setEditRowId(null);
            }}
          />
        </div>
      ),
    },
  ];
}

export function Groups() {
  const serverData = useContext(ServerDataContext);
  const [rowsData, setRowsData] = useState(
    Array.from(serverData.groups.values()).map((us) => toForm(us))
  );

  return (
    <GridTable columns={getColumns(setRowsData, serverData)} rows={rowsData} />
  );
}
