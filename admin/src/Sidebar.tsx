import * as React from 'react';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Container from '@mui/material/Container';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import HomeIcon from '@mui/icons-material/Home';
import PlaceIcon from '@mui/icons-material/Place';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import PeopleIcon from '@mui/icons-material/People';
import DataTable from './DataTable';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`sidebar-tabpanel-${index}`}
      aria-labelledby={`sidebar-tab-${index}`}
      {...other}
      style={{ display: value === index ? 'flex' : 'none', flex: 1 }}
    >
      {value === index && <Box sx={{ p: 3, flex: 1 }}>{children}</Box>}
    </div>
  );
}

function a11yProps(index: number) {
  return {
    id: `sidebar-tab-${index}`,
    'aria-controls': `sidebar-tabpanel-${index}`,
  };
}

const sample = {
  columns: ['1', '2', '3', '4', 'buttons'],

  rows: [
    [
      'Joe James',
      'Test Corp',
      'Yonkers',
      'NY',
      { text: 'bruh', clickFunc: () => console.log('bruh') },
    ],
    [
      'John Walsh',
      'Test Corp',
      'Hartford',
      'CT',
      { text: 'bruh', clickFunc: () => console.log('bruh') },
    ],
    [
      'Bob Herm',
      'Test Corp',
      'Tampa',
      'FL',
      { text: 'bruh', clickFunc: () => console.log('bruh') },
    ],
    [
      'James Houston',
      'Test Corp',
      'Dallas',
      'TX',
      { text: 'bruh', clickFunc: () => console.log('bruh') },
    ],
  ],
};

export default function Sidebar() {
  const [value, setValue] = React.useState(0);

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
  };

  return (
    <Box sx={{ bgcolor: 'background.paper', display: 'flex', flex: 1 }}>
      <Tabs
        orientation="vertical"
        variant="scrollable"
        value={value}
        onChange={handleChange}
        sx={{ borderRight: 1, borderColor: 'divider' }}
      >
        <Tab icon={<HomeIcon />} label="Home" {...a11yProps(0)} />
        <Tab icon={<PlaceIcon />} label="Places" {...a11yProps(1)} />
        <Tab
          icon={<VerifiedUserIcon />}
          label="Admin Approval"
          {...a11yProps(2)}
        />
        <Tab icon={<PeopleIcon />} label="Users" {...a11yProps(3)} />
      </Tabs>

      <TabPanel value={value} index={0}>
        Item One
      </TabPanel>
      <TabPanel value={value} index={1}>
        Item Two
      </TabPanel>
      <TabPanel value={value} index={2}>
        Item Three
      </TabPanel>
      <TabPanel value={value} index={3}>
        <DataTable columns={sample.columns} rows={sample.rows} />
      </TabPanel>
    </Box>
  );
}
