import {
  DataGrid,
  GridColDef,
  GridRowModel,
  GridRenderCellParams,
} from '@mui/x-data-grid';

type Clickable = { text: string; clickFunc: () => void };
type Editable = { text: string; editFunc: (s: string) => void };

type Cell = string | Clickable | Editable;

function isEditable(cell: Cell): cell is Editable {
  return (cell as Editable).editFunc !== undefined;
}

function isClickable(cell: Cell): cell is Clickable {
  return (cell as Clickable).clickFunc !== undefined;
}

interface DataTableProps {
  children?: React.ReactNode;
  columns: string[];
  rows: Cell[][];
}

const sampleColumns: GridColDef[] = [
  { field: 'id', headerName: 'ID', width: 70 },
  { field: 'firstName', headerName: 'First name', width: 130 },
  { field: 'lastName', headerName: 'Last name', width: 130 },
  {
    field: 'age',
    headerName: 'Age',
    type: 'number',
    width: 90,
  },
];

const sampleRows = [
  { id: 1, lastName: 'Snow', firstName: 'Jon', age: 35 },
  { id: 2, lastName: 'Lannister', firstName: 'Cersei', age: 42 },
  { id: 3, lastName: 'Lannister', firstName: 'Jaime', age: 45 },
  { id: 4, lastName: 'Stark', firstName: 'Arya', age: 16 },
  { id: 5, lastName: 'Targaryen', firstName: 'Daenerys', age: null },
  { id: 6, lastName: 'Melisandre', firstName: null, age: 150 },
  { id: 7, lastName: 'Clifford', firstName: 'Ferrara', age: 44 },
  { id: 8, lastName: 'Frances', firstName: 'Rossini', age: 36 },
  { id: 9, lastName: 'Roxie', firstName: 'Harvey', age: 65 },
];

export default function DataTable(props: DataTableProps) {
  const { rows, columns } = props;
  let gridRows = rows.map((row, i) =>
    row.reduce((current, item, index) => {
      Object.defineProperty(current, columns[index], {
        value: typeof item === 'string' ? item : item.text,
        configurable: true,
      });
      Object.defineProperty(current, 'id', {
        value: i,
        configurable: true,
      });
      return current as GridRowModel;
    }, {}),
  );
  let gridColumns: GridColDef[] = columns.map((value, index) => ({
    field: value,
    headerName: value,
    type: 'string',
  }));
  return (
    <DataGrid
      rows={gridRows}
      columns={gridColumns}
      pageSize={5}
      rowsPerPageOptions={[5]}
      checkboxSelection
      disableSelectionOnClick
    />
  );
}
