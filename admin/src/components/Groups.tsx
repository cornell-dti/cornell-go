import { useContext, useEffect, useState } from "react";
import { ServerDataContext } from "./ServerData";
import GridTable from "@nadavshaar/react-grid-table";
import userEvent from "@testing-library/user-event";
import { DeleteModal } from "./DeleteModal";

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
            {CANCEL_SVG}
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
            objectName={serverData.groups.get(deleteId)?.friendlyId ?? ""}
            isOpen={tableManager.rowEditApi.editRowId !== null}
            onClose={() => {
              tableManager.rowEditApi.setEditRowId(null);
            }}
            onDelete={() => {
              serverData.deleteGroup(deleteId);
              serverData.groups.delete(data.id);

              let rowsClone = [...tableManager.rowsApi.rows];
              let deletedRowIndex = rowsClone.findIndex(
                (r) => r.id === data.id,
              );
              rowsClone.splice(deletedRowIndex, 1);

              const newData = Array.from(serverData.groups.values()).map((gr) =>
                toForm(gr),
              );
              newData.forEach((gr) => {
                let index = rowsClone.findIndex((r) => r.id === gr.id);

                if (index === -1) rowsClone.push(gr);
              });

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
    Array.from(serverData.groups.values()).map((gr) => toForm(gr)),
  );

  return (
    <GridTable columns={getColumns(setRowsData, serverData)} rows={rowsData} />
  );
}
